import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import '../../core/error/exceptions.dart';

class StorageService {
  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  Future<String> uploadBytes({
    required String path,
    required Uint8List data,
    String? contentType,
    SettableMetadata? metadata,
  }) async {
    try {
      final ref = _storage.ref(path);
      final SettableMetadata? meta =
          metadata ?? (contentType != null ? SettableMetadata(contentType: contentType) : null);
      await ref.putData(data, meta);
      return ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw StorageException(message: e.message ?? 'Error uploading to storage', code: e.code);
    }
  }

  Future<void> deleteObject(String path) async {
    try {
      await _storage.ref(path).delete();
    } on FirebaseException catch (e) {
      throw StorageException(message: e.message ?? 'Error deleting object', code: e.code);
    }
  }
}
