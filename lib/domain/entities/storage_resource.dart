/// Domain representation of a stored artifact upload.
class StorageUploadResult {
  const StorageUploadResult({required this.path, required this.downloadUrl});

  /// Logical path used to store the artifact inside the backing store.
  final String path;

  /// Public or signed URL that can be used to retrieve the artifact.
  final String downloadUrl;
}

/// Parameters required to upload an artifact to persistent storage.
class StorageUploadRequest {
  const StorageUploadRequest({
    required this.path,
    required this.bytes,
    this.contentType,
    this.metadata,
  });

  /// Target path in the storage backend.
  final String path;

  /// Raw bytes to be persisted.
  final List<int> bytes;

  /// Optional MIME type associated with the artifact.
  final String? contentType;

  /// Optional key-value metadata that should accompany the upload.
  final Map<String, String>? metadata;
}
