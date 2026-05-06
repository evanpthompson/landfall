/// Describes where photos should be loaded from.
///
/// Used by [PhotoCubit] to select the appropriate repository implementation.
/// Persisted to settings as JSON via [toJson] / [fromJson].
sealed class PhotoSource {
  const PhotoSource();

  Map<String, dynamic> toJson();

  static PhotoSource fromJson(Map<String, dynamic> json) {
    return switch (json['type'] as String?) {
      'serverpod' => const PhotoSourceServerpod(),
      'local_directory' => PhotoSourceLocalDirectory(
          path: json['path'] as String,
        ),
      'network' => PhotoSourceNetwork(
          urls: (json['urls'] as List<dynamic>).cast<String>(),
        ),
      's3' => PhotoSourceS3(
          bucket: json['bucket'] as String,
          region: json['region'] as String,
          prefix: json['prefix'] as String? ?? '',
          accessKey: json['access_key'] as String?,
          secretKey: json['secret_key'] as String?,
        ),
      _ => throw ArgumentError('Unknown PhotoSource type: ${json['type']}'),
    };
  }
}

/// The default Landfall server-managed photo source.
class PhotoSourceServerpod extends PhotoSource {
  const PhotoSourceServerpod();

  @override
  Map<String, dynamic> toJson() => {'type': 'serverpod'};

  @override
  bool operator ==(Object other) => other is PhotoSourceServerpod;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// A local filesystem directory containing image files.
class PhotoSourceLocalDirectory extends PhotoSource {
  const PhotoSourceLocalDirectory({required this.path});

  final String path;

  @override
  Map<String, dynamic> toJson() => {'type': 'local_directory', 'path': path};

  @override
  bool operator ==(Object other) =>
      other is PhotoSourceLocalDirectory && path == other.path;

  @override
  int get hashCode => Object.hash(runtimeType, path);
}

/// A fixed list of image URLs.
class PhotoSourceNetwork extends PhotoSource {
  const PhotoSourceNetwork({required this.urls});

  final List<String> urls;

  @override
  Map<String, dynamic> toJson() => {'type': 'network', 'urls': urls};

  @override
  bool operator ==(Object other) =>
      other is PhotoSourceNetwork &&
      urls.length == other.urls.length &&
      urls.every((u) => other.urls.contains(u));

  @override
  int get hashCode => Object.hashAll(urls);
}

/// An S3-compatible cloud bucket.
class PhotoSourceS3 extends PhotoSource {
  const PhotoSourceS3({
    required this.bucket,
    required this.region,
    required this.prefix,
    this.accessKey,
    this.secretKey,
  });

  final String bucket;
  final String region;
  final String prefix;
  final String? accessKey;
  final String? secretKey;

  @override
  Map<String, dynamic> toJson() => {
        'type': 's3',
        'bucket': bucket,
        'region': region,
        'prefix': prefix,
        if (accessKey != null) 'access_key': accessKey,
        if (secretKey != null) 'secret_key': secretKey,
      };

  @override
  bool operator ==(Object other) =>
      other is PhotoSourceS3 &&
      bucket == other.bucket &&
      region == other.region &&
      prefix == other.prefix &&
      accessKey == other.accessKey &&
      secretKey == other.secretKey;

  @override
  int get hashCode =>
      Object.hash(runtimeType, bucket, region, prefix, accessKey, secretKey);
}
