import 'dart:convert';

import 'package:landfall_shared/src/models/theme/theme_tokens.dart';

/// Client-side representation of a Landfall theme.
///
/// Decoupled from the Serverpod-generated [LandfallTheme] model — this is the
/// domain object used throughout the Flutter client. The [tokens] field is the
/// fully resolved token set the renderer consumes directly.
class ThemeInfo {
  const ThemeInfo({
    required this.id,
    required this.slug,
    required this.name,
    required this.schemaVersion,
    this.author,
    this.description,
    this.previewUrl,
    this.tags = const [],
    required this.isBuiltIn,
    required this.tokens,
  });

  final int id;

  /// URL-safe slug, e.g. `"default-dark"` or `"neon-arcade"`.
  final String slug;

  final String name;
  final String schemaVersion;
  final String? author;
  final String? description;
  final String? previewUrl;
  final List<String> tags;

  /// True for the 5 built-in themes seeded at server startup. Built-in themes
  /// cannot be deleted.
  final bool isBuiltIn;

  /// Fully resolved token set. All derived values are pre-computed; the renderer
  /// maps these to widget styles with no further defaulting.
  final LandfallThemeTokens tokens;

  /// Deserialise from the flat JSON stored in [LandfallTheme.resolvedJson].
  factory ThemeInfo.fromServerJson({
    required int id,
    required String slug,
    required String name,
    required String schemaVersion,
    String? author,
    String? description,
    String? previewUrl,
    String tagsJson = '[]',
    required bool isBuiltIn,
    required String resolvedJson,
  }) {
    final tags = (jsonDecode(tagsJson) as List<dynamic>)
        .map((e) => e as String)
        .toList();
    final tokenMap =
        (jsonDecode(resolvedJson) as Map<String, dynamic>);
    return ThemeInfo(
      id: id,
      slug: slug,
      name: name,
      schemaVersion: schemaVersion,
      author: author,
      description: description,
      previewUrl: previewUrl,
      tags: tags,
      isBuiltIn: isBuiltIn,
      tokens: LandfallThemeTokens.fromMap(tokenMap),
    );
  }

  ThemeInfo copyWith({
    int? id,
    String? slug,
    String? name,
    String? schemaVersion,
    String? author,
    String? description,
    String? previewUrl,
    List<String>? tags,
    bool? isBuiltIn,
    LandfallThemeTokens? tokens,
  }) {
    return ThemeInfo(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      name: name ?? this.name,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      author: author ?? this.author,
      description: description ?? this.description,
      previewUrl: previewUrl ?? this.previewUrl,
      tags: tags ?? this.tags,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      tokens: tokens ?? this.tokens,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemeInfo &&
          id == other.id &&
          slug == other.slug &&
          name == other.name &&
          isBuiltIn == other.isBuiltIn;

  @override
  int get hashCode => Object.hash(id, slug, name, isBuiltIn);

  @override
  String toString() => 'ThemeInfo(id: $id, slug: $slug, name: $name)';
}
