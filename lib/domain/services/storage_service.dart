import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../core/error/exceptions.dart';

class StorageService {
  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? (() {
          final bucket = Firebase.app().options.storageBucket;
          if (bucket != null && bucket.isNotEmpty) {
            final normalized = bucket.startsWith('gs://') ? bucket : 'gs://$bucket';
            return FirebaseStorage.instanceFor(bucket: normalized);
          }
          return FirebaseStorage.instance;
        })();

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
