import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';

import '../generated/agent/landfall_exception.dart';
import '../generated/profile/dashboard_profile.dart';
import '../generated/theme/landfall_theme.dart';
import '../generated/theme/theme_upload_result.dart';
import '../generated/theme/theme_validation_error.dart';
import '../profile/profile_endpoint.dart';
import 'ssrf_guard.dart';
import 'theme_seeder.dart';
import 'theme_validator.dart';

void _requireAuth(Session session) {
  if (session.authenticated == null) {
    throw LandfallException(message: 'Authentication required.');
  }
}

/// Manages themes: built-in, user-imported, and marketplace.
class ThemeEndpoint extends Endpoint {
  /// Returns all themes available on this display (built-in + imported).
  ///
  /// Built-ins are seeded if the themes table is empty.
  Future<List<LandfallTheme>> listThemes(Session session) async {
    _requireAuth(session);
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
    _requireAuth(session);
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
    _requireAuth(session);
    final classification = SsrfGuard.classifyUrl(url);
    if (!classification.accepted) {
      return ThemeUploadResult(
        theme: null,
        errors: [
          ThemeValidationError(
            tokenPath: 'url',
            message: classification.reason!,
          ),
        ],
      );
    }

    final uri = Uri.parse(url);

    // Resolve the hostname and reject if any A/AAAA points at a private/
    // loopback/link-local range. Defeats DNS rebinding where a public-looking
    // hostname is an alias for an internal address. Skips for bracketed IPv6
    // literals and dotted IPv4 (already validated synchronously).
    if (!_isNumericHost(uri.host)) {
      try {
        final addrs = await InternetAddress.lookup(uri.host)
            .timeout(const Duration(seconds: 3));
        if (addrs.isEmpty ||
            addrs.any((a) => SsrfGuard.isPrivateAddress(a.address))) {
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
      } on SocketException {
        return ThemeUploadResult(
          theme: null,
          errors: [
            ThemeValidationError(
              tokenPath: 'url',
              message: 'Failed to resolve theme host.',
            ),
          ],
        );
      } on TimeoutException {
        return ThemeUploadResult(
          theme: null,
          errors: [
            ThemeValidationError(
              tokenPath: 'url',
              message: 'Theme host resolution timed out.',
            ),
          ],
        );
      }
    }

    late final http.Response response;
    try {
      response = await _fetchNoRedirect(uri)
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
            message: 'Fetch returned HTTP ${response.statusCode}.',
          ),
        ],
      );
    }

    final integrityError = ThemeValidator.verifySha256(response.body);
    if (integrityError != null) {
      return ThemeUploadResult(
        theme: null,
        errors: [
          ThemeValidationError(
            tokenPath: 'sha256',
            message: integrityError,
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
    _requireAuth(session);
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
    _requireAuth(session);
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
    _requireAuth(session);
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

  // Returns true if [host] is a literal IP (v4 or v6) rather than a name
  // that needs DNS resolution.
  static bool _isNumericHost(String host) {
    if (host.contains(':')) return true; // IPv6 literal
    final parts = host.split('.');
    if (parts.length == 4 && parts.every((p) => int.tryParse(p) != null)) {
      return true;
    }
    return false;
  }

  // GET [uri] without following redirects. A 30x response is treated as a
  // fetch failure — redirect targets are not re-validated and could lead to
  // a private endpoint.
  static Future<http.Response> _fetchNoRedirect(Uri uri) async {
    final client = http.Client();
    try {
      final request = http.Request('GET', uri)..followRedirects = false;
      final streamed = await client.send(request);
      final body = await streamed.stream.bytesToString();
      final response = http.Response(
        body,
        streamed.statusCode,
        headers: streamed.headers,
        reasonPhrase: streamed.reasonPhrase,
      );
      if (response.statusCode >= 300 && response.statusCode < 400) {
        throw const HttpException('Redirects are not permitted.');
      }
      return response;
    } finally {
      client.close();
    }
  }
}
