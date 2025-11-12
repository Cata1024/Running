import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class AvatarUploader {
  static Future<String> uploadAvatar({
    required File file,
    required String userId,
    Function(double progress)? onProgress,
  }) async {
    try {
      // Validar tipo de archivo
      if (!_isValidImage(file)) {
        throw const FormatException('Formato de archivo no soportado. Usa JPG, PNG, GIF o WebP');
      }

      // Validar tamaño (máx. 5MB)
      if (!_isValidSize(file, maxSizeInMB: 5)) {
        throw StateError('La imagen es demasiado grande. El tamaño máximo es 5MB');
      }

      // Obtener usuario actual
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw FirebaseException(
          plugin: 'firebase_auth',
          code: 'unauthenticated',
          message: 'Usuario no autenticado',
        );
      }

      // Renovar token
      final idToken = await user.getIdToken(true);
      if (idToken == null || idToken.isEmpty) {
        throw FirebaseException(
          plugin: 'firebase_auth',
          code: 'token-error',
          message: 'No se pudo renovar el token de autenticación',
        );
      }

      // Configurar metadata
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ext = file.path.split('.').last.toLowerCase();
      final contentType = _getContentType(ext);

      // Referencia al archivo en Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('avatars')
          .child(userId)
          .child('$timestamp.$ext');

      final metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: {
          'uploadedBy': userId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      // Subir archivo
      final uploadTask = storageRef.putFile(file, metadata);
      
      // Progreso de carga
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      debugPrint('Imagen subida correctamente: $downloadUrl');
      return downloadUrl;

    } on FirebaseAuthException catch (e) {
      debugPrint('Error de autenticación: ${e.code} - ${e.message}');

      // Si el token expiró, intentar renovarlo
      if (e.code == 'unauthenticated' || e.code == 'auth/id-token-expired') {
        try {
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser == null) {
            throw FirebaseException(
              plugin: 'firebase_auth',
              code: 'user-not-found',
              message: 'Usuario no encontrado',
            );
          }

          await currentUser.reload();
          return await uploadAvatar(
            file: file,
            userId: userId,
            onProgress: onProgress,
          );
        } on FirebaseAuthException catch (retryError) {
          debugPrint('Error Firebase Auth al renovar token: ${retryError.code} - ${retryError.message}');

          switch (retryError.code) {
            case 'user-not-found':
            case 'user-disabled':
            case 'user-token-expired':
            case 'invalid-user-token':
              throw FirebaseException(
                plugin: 'firebase_auth',
                code: 'auth-required',
                message: 'Tu sesión ha expirado. Por favor, inicia sesión nuevamente.',
              );
          }

          throw FirebaseException(
            plugin: 'firebase_auth',
            code: 'retry-failed',
            message: 'No se pudo renovar la sesión. Por favor, inicia sesión de nuevo.',
          );
        } catch (retryError) {
          debugPrint('Error al renovar token: $retryError');
          throw FirebaseException(
            plugin: 'firebase_auth',
            code: 'retry-failed',
            message: 'No se pudo renovar la sesión. Por favor, inicia sesión de nuevo.',
          );
        }
      }

      throw FirebaseException(
        plugin: 'firebase_auth',
        code: e.code,
        message: e.message ?? 'Error de autenticación',
      );
    } catch (e) {
      debugPrint('Error inesperado: $e');
      throw FirebaseException(
        plugin: 'storage',
        code: 'upload-failed',
        message: 'Error al subir la imagen: $e',
      );
    }
  }

  // Métodos auxiliares
  static bool _isValidImage(File file) {
    final path = file.path.toLowerCase();
    return path.endsWith('.jpg') || 
           path.endsWith('.jpeg') || 
           path.endsWith('.png') || 
           path.endsWith('.gif') || 
           path.endsWith('.webp');
  }

  static bool _isValidSize(File file, {int maxSizeInMB = 5}) {
    final sizeInMB = file.lengthSync() / (1024 * 1024);
    return sizeInMB <= maxSizeInMB;
  }

  static String _getContentType(String ext) {
    switch (ext) {
      case 'png': return 'image/png';
      case 'webp': return 'image/webp';
      case 'gif': return 'image/gif';
      case 'jpg':
      case 'jpeg':
      default: return 'image/jpeg';
    }
  }
}