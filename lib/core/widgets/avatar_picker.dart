import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../design_system/territory_tokens.dart';

/// Widget para seleccionar y mostrar avatar con soporte para Firebase Upload
/// 
/// Uso:
/// ```dart
/// AvatarPicker(
///   imageUrl: user.photoUrl,
///   onImageSelected: (file) async {
///     final url = await uploadToFirebase(file);
///     updateUserAvatar(url);
///   },
/// )
/// ```
class AvatarPicker extends StatefulWidget {
  final String? imageUrl;
  final Future<void> Function(File file)? onImageSelected;
  final double size;
  final bool editable;
  final String? placeholderText;

  const AvatarPicker({
    super.key,
    this.imageUrl,
    this.onImageSelected,
    this.size = 120,
    this.editable = true,
    this.placeholderText,
  });

  @override
  State<AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<AvatarPicker> {
  File? _selectedImage;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      final file = File(image.path);
      setState(() {
        _selectedImage = file;
      });

      if (widget.onImageSelected != null) {
        setState(() => _isUploading = true);
        try {
          await widget.onImageSelected!(file);
        } finally {
          if (mounted) {
            setState(() => _isUploading = false);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imagen: $e')),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(TerritoryTokens.radiusLarge),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(TerritoryTokens.space16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: TerritoryTokens.space16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Seleccionar foto',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: TerritoryTokens.space24),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(TerritoryTokens.space12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(TerritoryTokens.radiusMedium),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: const Text('Tomar foto'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(TerritoryTokens.space12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(TerritoryTokens.radiusMedium),
                    ),
                    child: Icon(
                      Icons.photo_library,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  title: const Text('Elegir de galería'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: TerritoryTokens.space8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: widget.editable ? _showImageSourceDialog : null,
      child: Stack(
        children: [
          // Avatar circular
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.surfaceContainerHighest,
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: _isUploading
                  ? Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : _selectedImage != null
                      ? Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                        )
                      : widget.imageUrl != null && widget.imageUrl!.isNotEmpty
                          ? Image.network(
                              widget.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _PlaceholderAvatar(
                                  size: widget.size,
                                  text: widget.placeholderText,
                                );
                              },
                            )
                          : _PlaceholderAvatar(
                              size: widget.size,
                              text: widget.placeholderText,
                            ),
            ),
          ),

          // Badge editable
          if (widget.editable && !_isUploading)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(TerritoryTokens.space8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.surface,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.camera_alt,
                  color: theme.colorScheme.onPrimary,
                  size: widget.size * 0.2,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlaceholderAvatar extends StatelessWidget {
  final double size;
  final String? text;

  const _PlaceholderAvatar({
    required this.size,
    this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: size,
      height: size,
      color: theme.colorScheme.primaryContainer,
      child: text != null && text!.isNotEmpty
          ? Center(
              child: Text(
                text!.substring(0, 1).toUpperCase(),
                style: theme.textTheme.displayLarge?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : Icon(
              Icons.person,
              size: size * 0.5,
              color: theme.colorScheme.onPrimaryContainer,
            ),
    );
  }
}

/// Helper para upload de avatar a Firebase Storage
/// 
/// Uso:
/// ```dart
/// final url = await AvatarUploader.uploadToFirebase(
///   file: imageFile,
///   userId: user.uid,
/// );
/// ```
class AvatarUploader {
  AvatarUploader._();

  /// Upload avatar a Firebase Storage
  static Future<String> uploadToFirebase({
    required File file,
    required String userId,
    Function(double progress)? onProgress,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = file.path.split('.').last;
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('avatars')
          .child('${userId}_$timestamp.$extension');
      
      final uploadTask = storageRef.putFile(file);
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }
      
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
      
    } catch (e) {
      // En caso de error, retornar placeholder
      return 'https://ui-avatars.com/api/?name=$userId&size=200';
    }
  }

  /// Validar que el archivo sea una imagen válida
  static bool isValidImage(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension);
  }

  /// Validar tamaño máximo del archivo (en bytes)
  static bool isValidSize(File file, {int maxSizeInMB = 5}) {
    final sizeInMB = file.lengthSync() / (1024 * 1024);
    return sizeInMB <= maxSizeInMB;
  }
}
