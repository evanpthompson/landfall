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

/// A stored theme — metadata plus the fully-resolved token set as JSON.
/// Built-in themes have isBuiltIn=true and cannot be deleted.
abstract class LandfallTheme implements _i1.SerializableModel {
  LandfallTheme._({
    this.id,
    required this.slug,
    required this.name,
    required this.schemaVersion,
    this.author,
    this.description,
    this.previewUrl,
    String? tagsJson,
    required this.tokensJson,
    required this.resolvedJson,
    bool? isBuiltIn,
    required this.createdAt,
  }) : tagsJson = tagsJson ?? '[]',
       isBuiltIn = isBuiltIn ?? false;

  factory LandfallTheme({
    int? id,
    required String slug,
    required String name,
    required String schemaVersion,
    String? author,
    String? description,
    String? previewUrl,
    String? tagsJson,
    required String tokensJson,
    required String resolvedJson,
    bool? isBuiltIn,
    required DateTime createdAt,
  }) = _LandfallThemeImpl;

  factory LandfallTheme.fromJson(Map<String, dynamic> jsonSerialization) {
    return LandfallTheme(
      id: jsonSerialization['id'] as int?,
      slug: jsonSerialization['slug'] as String,
      name: jsonSerialization['name'] as String,
      schemaVersion: jsonSerialization['schemaVersion'] as String,
      author: jsonSerialization['author'] as String?,
      description: jsonSerialization['description'] as String?,
      previewUrl: jsonSerialization['previewUrl'] as String?,
      tagsJson: jsonSerialization['tagsJson'] as String?,
      tokensJson: jsonSerialization['tokensJson'] as String,
      resolvedJson: jsonSerialization['resolvedJson'] as String,
      isBuiltIn: jsonSerialization['isBuiltIn'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['isBuiltIn']),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// URL-safe slug, e.g. "default-dark" or "neon-arcade". Unique.
  String slug;

  /// User-facing display name.
  String name;

  /// ThemeSchema version the theme was authored against (e.g. "1.0").
  String schemaVersion;

  /// Optional theme author handle or name.
  String? author;

  /// One or two sentence description.
  String? description;

  /// HTTPS URL to a 1920x1080 PNG preview image.
  String? previewUrl;

  /// JSON-encoded List<String> of marketplace tags.
  String tagsJson;

  /// The raw theme YAML/JSON as a normalised JSON string (post-parse, pre-resolve).
  String tokensJson;

  /// The fully resolved flat token map as a JSON string (derived values filled in).
  String resolvedJson;

  /// True for the 5 built-in themes seeded at startup. Cannot be deleted.
  bool isBuiltIn;

  /// When this theme was created.
  DateTime createdAt;

  /// Returns a shallow copy of this [LandfallTheme]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  LandfallTheme copyWith({
    int? id,
    String? slug,
    String? name,
    String? schemaVersion,
    String? author,
    String? description,
    String? previewUrl,
    String? tagsJson,
    String? tokensJson,
    String? resolvedJson,
    bool? isBuiltIn,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LandfallTheme',
      if (id != null) 'id': id,
      'slug': slug,
      'name': name,
      'schemaVersion': schemaVersion,
      if (author != null) 'author': author,
      if (description != null) 'description': description,
      if (previewUrl != null) 'previewUrl': previewUrl,
      'tagsJson': tagsJson,
      'tokensJson': tokensJson,
      'resolvedJson': resolvedJson,
      'isBuiltIn': isBuiltIn,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _LandfallThemeImpl extends LandfallTheme {
  _LandfallThemeImpl({
    int? id,
    required String slug,
    required String name,
    required String schemaVersion,
    String? author,
    String? description,
    String? previewUrl,
    String? tagsJson,
    required String tokensJson,
    required String resolvedJson,
    bool? isBuiltIn,
    required DateTime createdAt,
  }) : super._(
         id: id,
         slug: slug,
         name: name,
         schemaVersion: schemaVersion,
         author: author,
         description: description,
         previewUrl: previewUrl,
         tagsJson: tagsJson,
         tokensJson: tokensJson,
         resolvedJson: resolvedJson,
         isBuiltIn: isBuiltIn,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [LandfallTheme]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  LandfallTheme copyWith({
    Object? id = _Undefined,
    String? slug,
    String? name,
    String? schemaVersion,
    Object? author = _Undefined,
    Object? description = _Undefined,
    Object? previewUrl = _Undefined,
    String? tagsJson,
    String? tokensJson,
    String? resolvedJson,
    bool? isBuiltIn,
    DateTime? createdAt,
  }) {
    return LandfallTheme(
      id: id is int? ? id : this.id,
      slug: slug ?? this.slug,
      name: name ?? this.name,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      author: author is String? ? author : this.author,
      description: description is String? ? description : this.description,
      previewUrl: previewUrl is String? ? previewUrl : this.previewUrl,
      tagsJson: tagsJson ?? this.tagsJson,
      tokensJson: tokensJson ?? this.tokensJson,
      resolvedJson: resolvedJson ?? this.resolvedJson,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
