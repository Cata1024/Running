import '../entities/storage_resource.dart';

/// Contract hiding cloud storage specifics from the domain layer.
abstract class IStorageRepository {
  /// Upload arbitrary bytes to persistent storage, returning the resulting path
  /// and download URL.
  Future<StorageUploadResult> upload(StorageUploadRequest request);

  /// Delete an object identified by its storage path.
  Future<void> delete(String path);
}
