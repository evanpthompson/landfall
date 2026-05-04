/// Standalone CLI tool for validating a Landfall theme YAML file.
///
/// Usage:
///   dart run bin/validate_theme.dart path/to/theme.yaml [--marketplace]
///
/// Exits 0 on success, 1 on validation failure.
/// With `--marketplace`: also runs safe-zone checks (required for marketplace
/// submissions).
library;

import 'dart:io';

import 'package:landfall_server/src/theme/theme_submission_checker.dart';
import 'package:landfall_server/src/theme/theme_validator.dart';

void main(List<String> args) {
  final positional = args.where((a) => !a.startsWith('--')).toList();
  final flags = args.where((a) => a.startsWith('--')).toSet();

  if (positional.isEmpty) {
    stderr.writeln('Usage: dart run bin/validate_theme.dart '
        '<theme.yaml> [--marketplace]');
    exit(2);
  }

  final path = positional.first;
  final isMarketplace = flags.contains('--marketplace');

  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('Error: file not found: $path');
    exit(2);
  }

  final content = file.readAsStringSync();
  final filename = file.uri.pathSegments.last;

  stdout.writeln('Validating $filename...');

  // Stage 1: schema + token validation.
  final result = ThemeValidator.validate(content);
  if (!result.isValid) {
    stdout.writeln('FAIL  $filename');
    for (final e in result.errors) {
      stdout.writeln('  [schema] ${e.tokenPath}: ${e.message}');
    }
    exit(1);
  }

  // Stage 2 (marketplace only): SHA-256 integrity.
  if (isMarketplace) {
    final integrityError = ThemeValidator.verifySha256(content);
    if (integrityError != null) {
      stdout.writeln('FAIL  $filename');
      stdout.writeln('  [integrity] sha256: $integrityError');
      exit(1);
    }
  }

  // Stage 3 (marketplace only): safe-zone checks.
  if (isMarketplace) {
    final violations =
        ThemeSubmissionChecker.checkSafeZones(result.resolvedTokens!);
    if (violations.isNotEmpty) {
      stdout.writeln('FAIL  $filename');
      for (final v in violations) {
        stdout.writeln('  [safe-zone] ${v.tokenPath}: ${v.message}');
      }
      exit(1);
    }
  }

  stdout.writeln('OK    $filename');
  exit(0);
}
