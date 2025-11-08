import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../core/error/exceptions.dart';
import '../../domain/entities/storage_resource.dart';
import '../../domain/repositories/i_storage_repository.dart';

/// Firebase Storage implementation for [IStorageRepository].
class FirebaseStorageRepository implements IStorageRepository {
  FirebaseStorageRepository({FirebaseStorage? storage})
      : _storage = storage ?? _resolveStorageFromApp();

  final FirebaseStorage _storage;

  static FirebaseStorage _resolveStorageFromApp() {
    final options = Firebase.app().options;
    final bucket = options.storageBucket;
    if (bucket != null && bucket.isNotEmpty) {
      final normalized = bucket.startsWith('gs://') ? bucket : 'gs://$bucket';
      return FirebaseStorage.instanceFor(bucket: normalized);
    }
    return FirebaseStorage.instance;
  }

  @override
  Future<StorageUploadResult> upload(StorageUploadRequest request) async {
    try {
      final ref = _storage.ref(request.path);
      final metadata = request.metadata == null && request.contentType == null
          ? null
          : SettableMetadata(
              contentType: request.contentType,
              customMetadata: request.metadata,
            );
      final data = Uint8List.fromList(request.bytes);
      await ref.putData(data, metadata);
      final url = await ref.getDownloadURL();
      return StorageUploadResult(path: request.path, downloadUrl: url);
    } on FirebaseException catch (error) {
      throw StorageException(message: error.message ?? 'Error uploading object', code: error.code);
    }
  }

  @override
  Future<void> delete(String path) async {
    try {
      await _storage.ref(path).delete();
    } on FirebaseException catch (error) {
      throw StorageException(message: error.message ?? 'Error deleting object', code: error.code);
    }
  }
}
