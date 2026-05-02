import 'package:landfall_client/landfall_client.dart' hide LandfallTheme;
import 'package:landfall_shared/landfall_shared.dart';

/// Production [ThemeRepository] backed by [ThemeEndpoint].
///
/// Converts between [LandfallTheme] (Serverpod model) and [ThemeInfo]
/// (domain model) using [ThemeInfo.fromServerJson].
class ServerpodThemeRepository implements ThemeRepository {
  const ServerpodThemeRepository(this._client);

  final Client _client;

  @override
  Future<List<ThemeInfo>> listThemes() async {
    final themes = await _client.theme.listThemes();
    return themes.map(_toDomain).toList();
  }

  @override
  Future<ThemeInfo> uploadTheme(String yaml) async {
    final result = await _client.theme.uploadTheme(yaml);
    if (result.errors.isNotEmpty) {
      throw StateError(result.errors.map((e) => e.message).join(' '));
    }
    return _toDomain(result.theme!);
  }

  @override
  Future<ThemeInfo> importTheme(String url) async {
    final result = await _client.theme.importTheme(url);
    if (result.errors.isNotEmpty) {
      throw StateError(result.errors.map((e) => e.message).join(' '));
    }
    return _toDomain(result.theme!);
  }

  @override
  Future<void> applyTheme(int themeId, {int? profileId}) =>
      _client.theme.applyTheme(themeId, profileId: profileId);

  @override
  Future<void> deleteTheme(int id) => _client.theme.deleteTheme(id);

  // ── helpers ───────────────────────────────────────────────────────────────

  static ThemeInfo _toDomain(dynamic t) => ThemeInfo.fromServerJson(
        id: t.id!,
        slug: t.slug,
        name: t.name,
        schemaVersion: t.schemaVersion,
        author: t.author,
        description: t.description,
        previewUrl: t.previewUrl,
        tagsJson: t.tagsJson,
        isBuiltIn: t.isBuiltIn,
        resolvedJson: t.resolvedJson,
      );
}
