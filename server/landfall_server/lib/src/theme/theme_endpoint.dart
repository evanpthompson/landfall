import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';

import '../generated/profile/dashboard_profile.dart';
import '../generated/theme/landfall_theme.dart';
import '../generated/theme/theme_upload_result.dart';
import '../generated/theme/theme_validation_error.dart';
import '../profile/profile_endpoint.dart';
import 'theme_seeder.dart';
import 'theme_validator.dart';

/// Manages themes: built-in, user-imported, and marketplace.
class ThemeEndpoint extends Endpoint {
  /// Returns all themes available on this display (built-in + imported).
  ///
  /// Built-ins are seeded if the themes table is empty.
  Future<List<LandfallTheme>> listThemes(Session session) async {
    await _ensureSeeded(session);
    return LandfallTheme.db.find(
      session,
      orderBy: (t) => t.name,
    );
  }

  /// Validates and stores a theme from a raw YAML or JSON [yaml] string.
  ///
  /// On success [ThemeUploadResult.theme] is set and [errors] is empty.
  /// On failure [theme] is null and [errors] lists each validation problem.
  ///
  /// If a theme with the same slug already exists it is replaced.
  Future<ThemeUploadResult> uploadTheme(
    Session session,
    String yaml,
  ) async {
    final result = ThemeValidator.validate(yaml);
    if (!result.isValid) {
      return ThemeUploadResult(theme: null, errors: result.errors);
    }
    return _store(session, yaml, result.resolvedTokens!);
  }

  /// Fetches a theme YAML/JSON from the given HTTPS [url], validates, and
  /// stores it.
  ///
  /// Returns the same [ThemeUploadResult] shape as [uploadTheme].
  /// Rejects non-HTTPS URLs, private IP ranges, and loopback addresses to
  /// prevent SSRF. Enforces a 10-second fetch timeout. OWASP A06:2025.
  Future<ThemeUploadResult> importTheme(
    Session session,
    String url,
  ) async {
    if (!url.startsWith('https://')) {
      return ThemeUploadResult(
        theme: null,
        errors: [
          ThemeValidationError(
            tokenPath: 'url',
            message: 'Only HTTPS URLs are accepted.',
          ),
        ],
      );
    }

    final uri = Uri.tryParse(url);
    if (uri != null && _isRestrictedHost(uri.host.toLowerCase())) {
      return ThemeUploadResult(
        theme: null,
        errors: [
          ThemeValidationError(
            tokenPath: 'url',
            message: 'URL refers to a restricted host.',
          ),
        ],
      );
    }

    late final http.Response response;
    try {
      response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      return ThemeUploadResult(
        theme: null,
        errors: [
          ThemeValidationError(
            tokenPath: 'url',
            message: 'Failed to fetch theme: $e',
          ),
        ],
      );
    }

    if (response.statusCode != 200) {
      return ThemeUploadResult(
        theme: null,
        errors: [
          ThemeValidationError(
            tokenPath: 'url',
            message:
                'Fetch returned HTTP ${response.statusCode}.',
          ),
        ],
      );
    }

    return uploadTheme(session, response.body);
  }

  /// Deletes the theme with the given [id].
  ///
  /// Throws [InvalidRequestException] when attempting to delete a built-in
  /// theme. Is a no-op when [id] does not exist.
  Future<void> deleteTheme(Session session, int id) async {
    final theme = await LandfallTheme.db.findById(session, id);
    if (theme == null) return;
    if (theme.isBuiltIn) {
      throw InvalidRequestException('Cannot delete a built-in theme.');
    }
    await LandfallTheme.db.deleteRow(session, theme);
  }

  /// Returns the fully resolved token JSON string for the theme identified by
  /// [id].
  ///
  /// Throws [NotFoundException] when [id] does not exist.
  Future<String> previewTheme(Session session, int id) async {
    final theme = await LandfallTheme.db.findById(session, id);
    if (theme == null) {
      throw NotFoundException('LandfallTheme id=$id not found.');
    }
    return theme.resolvedJson;
  }

  /// Links the theme identified by [themeId] to a profile or to the global
  /// display setting.
  ///
  /// When [profileId] is provided, updates [DashboardProfile.themeId] for that
  /// profile. When null, is a no-op at the profile level (placeholder for a
  /// future global theme setting).
  ///
  /// Throws [NotFoundException] when [themeId] does not exist.
  Future<void> applyTheme(
    Session session,
    int themeId, {
    int? profileId,
  }) async {
    final theme = await LandfallTheme.db.findById(session, themeId);
    if (theme == null) {
      throw NotFoundException('LandfallTheme id=$themeId not found.');
    }

    if (profileId != null) {
      final profile =
          await DashboardProfile.db.findById(session, profileId);
      if (profile == null) {
        throw NotFoundException('DashboardProfile id=$profileId not found.');
      }
      await DashboardProfile.db.updateRow(
        session,
        profile.copyWith(themeId: theme.slug),
      );
    }
    // Future: persist global theme preference here.
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<ThemeUploadResult> _store(
    Session session,
    String yaml,
    Map<String, dynamic> resolvedTokens,
  ) async {
    final resolved = jsonEncode(resolvedTokens);
    final meta = _extractMeta(yaml);
    final slug = _slugify(meta['name'] as String? ?? 'imported');

    final existing = await LandfallTheme.db.findFirstRow(
      session,
      where: (t) => t.slug.equals(slug),
    );

    final LandfallTheme stored;
    if (existing != null && !existing.isBuiltIn) {
      final updated = existing.copyWith(
        name: meta['name'] as String? ?? existing.name,
        author: meta['author'] as String?,
        description: meta['description'] as String?,
        previewUrl: meta['previewUrl'] as String?,
        tagsJson: jsonEncode(meta['tags'] ?? []),
        tokensJson: resolved,
        resolvedJson: resolved,
      );
      stored = await LandfallTheme.db.updateRow(session, updated);
    } else {
      stored = await LandfallTheme.db.insertRow(
        session,
        LandfallTheme(
          slug: await _uniqueSlug(session, slug),
          name: meta['name'] as String? ?? 'Imported Theme',
          schemaVersion: '1.0',
          author: meta['author'] as String?,
          description: meta['description'] as String?,
          previewUrl: meta['previewUrl'] as String?,
          tagsJson: jsonEncode(meta['tags'] ?? []),
          tokensJson: resolved,
          resolvedJson: resolved,
          isBuiltIn: false,
          createdAt: DateTime.now().toUtc(),
        ),
      );
    }

    return ThemeUploadResult(theme: stored, errors: const []);
  }

  Future<void> _ensureSeeded(Session session) async {
    final count = await LandfallTheme.db.count(
      session,
      where: (t) => t.isBuiltIn.equals(true),
    );
    if (count == 0) {
      await ThemeSeeder.seed(session);
    }
  }

  static Map<String, dynamic> _extractMeta(String yamlStr) {
    // Minimal meta extraction: scan for the meta block and pull name/author/etc.
    // We use ThemeValidator internals indirectly — validate guarantees the
    // document is well-formed, so this is a convenience parse only.
    final result = ThemeValidator.validate(yamlStr);
    if (!result.isValid) return {};

    // Re-parse the YAML to pull meta fields.
    // (We avoid duplicating the YAML parse by using the validation path's
    // resolved tokens, but meta fields aren't in there. Quick direct parse.)
    try {
      final lines = yamlStr.split('\n');
      var inMeta = false;
      final meta = <String, dynamic>{};
      var tagsList = <String>[];
      var inTags = false;

      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed == 'meta:') {
          inMeta = true;
          inTags = false;
          continue;
        }
        if (inMeta && trimmed.startsWith('tags:')) {
          inTags = true;
          // Inline list: tags: [a, b, c]
          final inlineMatch = RegExp(r'tags:\s*\[([^\]]*)\]').firstMatch(line);
          if (inlineMatch != null) {
            tagsList = inlineMatch
                .group(1)!
                .split(',')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList();
            inTags = false;
          }
          continue;
        }
        if (inTags && trimmed.startsWith('- ')) {
          tagsList.add(trimmed.substring(2).trim());
          continue;
        }
        if (inMeta && !trimmed.startsWith(' ') && !trimmed.startsWith('\t') &&
            trimmed.isNotEmpty && !trimmed.startsWith('name:') &&
            !trimmed.startsWith('author:') &&
            !trimmed.startsWith('description:') &&
            !trimmed.startsWith('previewUrl:')) {
          inMeta = false;
          inTags = false;
        }
        if (inMeta) {
          _extractField('name', trimmed, meta);
          _extractField('author', trimmed, meta);
          _extractField('description', trimmed, meta);
          _extractField('previewUrl', trimmed, meta);
        }
      }
      if (tagsList.isNotEmpty) meta['tags'] = tagsList;
      return meta;
    } catch (_) {
      return {};
    }
  }

  static void _extractField(
    String key,
    String line,
    Map<String, dynamic> out,
  ) {
    if (!line.startsWith('$key:')) return;
    var value = line.substring('$key:'.length).trim();
    if (value.startsWith('"') && value.endsWith('"')) {
      value = value.substring(1, value.length - 1);
    } else if (value.startsWith("'") && value.endsWith("'")) {
      value = value.substring(1, value.length - 1);
    }
    if (value.isNotEmpty) out[key] = value;
  }

  static String _slugify(String name) => name
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');

  Future<String> _uniqueSlug(Session session, String base) async {
    var candidate = base;
    var suffix = 2;
    while (true) {
      final existing = await LandfallTheme.db.findFirstRow(
        session,
        where: (t) => t.slug.equals(candidate),
      );
      if (existing == null) return candidate;
      candidate = '$base-$suffix';
      suffix++;
    }
  }

  // Blocks loopback, link-local, and RFC-1918 private ranges to prevent SSRF.
  static bool _isRestrictedHost(String host) {
    if (host == 'localhost' || host == '127.0.0.1' || host == '::1') return true;
    if (host == '169.254.169.254') return true;
    if (host.startsWith('192.168.')) return true;
    if (host.startsWith('10.')) return true;
    // RFC-1918: 172.16.0.0/12 covers 172.16.x.x – 172.31.x.x
    final parts = host.split('.');
    if (parts.length == 4 && parts[0] == '172') {
      final second = int.tryParse(parts[1]) ?? -1;
      if (second >= 16 && second <= 31) return true;
    }
    return false;
  }
}
