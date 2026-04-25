/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;

/// A photo entry synced from an external provider (e.g. Google Drive).
///
/// Each row represents one image file available for the photo frame slideshow.
/// Photo bytes are not stored here — they are fetched on demand via the
/// provider service and proxied through the photo serve route.
abstract class Photo implements _i1.SerializableModel {
  Photo._({
    this.id,
    required this.credentialId,
    required this.providerFileId,
    required this.filename,
    required this.mimeType,
    required this.fetchedAt,
  });

  factory Photo({
    int? id,
    required int credentialId,
    required String providerFileId,
    required String filename,
    required String mimeType,
    required DateTime fetchedAt,
  }) = _PhotoImpl;

  factory Photo.fromJson(Map<String, dynamic> jsonSerialization) {
    return Photo(
      id: jsonSerialization['id'] as int?,
      credentialId: jsonSerialization['credentialId'] as int,
      providerFileId: jsonSerialization['providerFileId'] as String,
      filename: jsonSerialization['filename'] as String,
      mimeType: jsonSerialization['mimeType'] as String,
      fetchedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['fetchedAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// The LinkedCredential used to access this photo.
  int credentialId;

  /// Provider-assigned file identifier. Opaque to the client — used server-side
  /// when proxying image bytes from the upstream provider.
  String providerFileId;

  /// Original filename, e.g. "IMG_1234.jpg".
  String filename;

  /// MIME type, e.g. "image/jpeg", "image/png".
  String mimeType;

  /// When this photo entry was last synced from the upstream provider.
  DateTime fetchedAt;

  /// Returns a shallow copy of this [Photo]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Photo copyWith({
    int? id,
    int? credentialId,
    String? providerFileId,
    String? filename,
    String? mimeType,
    DateTime? fetchedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Photo',
      if (id != null) 'id': id,
      'credentialId': credentialId,
      'providerFileId': providerFileId,
      'filename': filename,
      'mimeType': mimeType,
      'fetchedAt': fetchedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PhotoImpl extends Photo {
  _PhotoImpl({
    int? id,
    required int credentialId,
    required String providerFileId,
    required String filename,
    required String mimeType,
    required DateTime fetchedAt,
  }) : super._(
         id: id,
         credentialId: credentialId,
         providerFileId: providerFileId,
         filename: filename,
         mimeType: mimeType,
         fetchedAt: fetchedAt,
       );

  /// Returns a shallow copy of this [Photo]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Photo copyWith({
    Object? id = _Undefined,
    int? credentialId,
    String? providerFileId,
    String? filename,
    String? mimeType,
    DateTime? fetchedAt,
  }) {
    return Photo(
      id: id is int? ? id : this.id,
      credentialId: credentialId ?? this.credentialId,
      providerFileId: providerFileId ?? this.providerFileId,
      filename: filename ?? this.filename,
      mimeType: mimeType ?? this.mimeType,
      fetchedAt: fetchedAt ?? this.fetchedAt,
    );
  }
}
