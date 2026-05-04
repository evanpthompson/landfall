import 'package:test/test.dart';

import 'package:landfall_server/src/theme/theme_submission_checker.dart';
import 'package:landfall_server/src/theme/theme_validator.dart';

/// Resolved token map built from the given theme YAML using ThemeValidator.
Map<String, dynamic> _resolve(String yaml) {
  final result = ThemeValidator.validate(yaml);
  if (!result.isValid) {
    throw StateError(
      'Test theme is invalid: ${result.errors.map((e) => e.message).join(', ')}',
    );
  }
  return result.resolvedTokens!;
}

String _theme({
  String? alertColor,
  String? successColor,
  String? warningColor,
  String? textPrimary,
}) {
  final buffer = StringBuffer('''
version: "1.0"
meta:
  name: "Test Theme"
color:
''');
  if (alertColor != null) buffer.writeln('  alert: "$alertColor"');
  if (successColor != null) buffer.writeln('  success: "$successColor"');
  if (warningColor != null) buffer.writeln('  warning: "$warningColor"');
  if (textPrimary != null) {
    buffer.writeln('  text:');
    buffer.writeln('    primary: "$textPrimary"');
  }
  return buffer.toString();
}

void main() {
  group('ThemeSubmissionChecker.checkSafeZones', () {
    group('color.text.primary', () {
      test('hex primary text passes (fully opaque)', () {
        final tokens = _resolve(_theme(textPrimary: '#FFFFFF'));
        final violations = ThemeSubmissionChecker.checkSafeZones(tokens);
        expect(
          violations.where((v) => v.tokenPath == 'color.text.primary'),
          isEmpty,
        );
      });

      test('rgba primary text with alpha >= 0.8 passes', () {
        final tokens = _resolve(_theme(textPrimary: '#EEEEEE'));
        // Override after resolution to test the checker directly.
        tokens['color.text.primary'] = 'rgba(255,255,255,0.85)';
        final violations = ThemeSubmissionChecker.checkSafeZones(tokens);
        expect(
          violations.where((v) => v.tokenPath == 'color.text.primary'),
          isEmpty,
        );
      });

      test('rgba primary text with alpha < 0.8 is a violation', () {
        final tokens = _resolve(_theme());
        tokens['color.text.primary'] = 'rgba(255,255,255,0.3)';
        final violations = ThemeSubmissionChecker.checkSafeZones(tokens);
        expect(
          violations.where((v) => v.tokenPath == 'color.text.primary'),
          isNotEmpty,
        );
      });

      test('violation message mentions minimum alpha', () {
        final tokens = _resolve(_theme());
        tokens['color.text.primary'] = 'rgba(255,255,255,0.1)';
        final violations = ThemeSubmissionChecker.checkSafeZones(tokens);
        final v = violations.firstWhere((v) => v.tokenPath == 'color.text.primary');
        expect(v.message, contains('0.8'));
      });
    });

    group('color.alert', () {
      test('red alert passes', () {
        final tokens = _resolve(_theme(alertColor: '#FF3B30'));
        final violations = ThemeSubmissionChecker.checkSafeZones(tokens);
        expect(
          violations.where((v) => v.tokenPath == 'color.alert'),
          isEmpty,
        );
      });

      test('blue alert is a violation', () {
        final tokens = _resolve(_theme(alertColor: '#0088FF'));
        final violations = ThemeSubmissionChecker.checkSafeZones(tokens);
        expect(
          violations.where((v) => v.tokenPath == 'color.alert'),
          isNotEmpty,
        );
      });

      test('green alert is a violation', () {
        final tokens = _resolve(_theme(alertColor: '#34C759'));
        final violations = ThemeSubmissionChecker.checkSafeZones(tokens);
        expect(
          violations.where((v) => v.tokenPath == 'color.alert'),
          isNotEmpty,
        );
      });

      test('violation message mentions red hue requirement', () {
        final tokens = _resolve(_theme(alertColor: '#0000FF'));
        final violations = ThemeSubmissionChecker.checkSafeZones(tokens);
        final v = violations.firstWhere((v) => v.tokenPath == 'color.alert');
        expect(v.message.toLowerCase(), contains('red'));
      });
    });

    group('color.success', () {
      test('green success passes', () {
        final tokens = _resolve(_theme(successColor: '#34C759'));
        final violations = ThemeSubmissionChecker.checkSafeZones(tokens);
        expect(
          violations.where((v) => v.tokenPath == 'color.success'),
          isEmpty,
        );
      });

      test('blue success is a violation', () {
        final tokens = _resolve(_theme(successColor: '#0088FF'));
        final violations = ThemeSubmissionChecker.checkSafeZones(tokens);
        expect(
          violations.where((v) => v.tokenPath == 'color.success'),
          isNotEmpty,
        );
      });

      test('red success is a violation', () {
        final tokens = _resolve(_theme(successColor: '#FF3B30'));
        final violations = ThemeSubmissionChecker.checkSafeZones(tokens);
        expect(
          violations.where((v) => v.tokenPath == 'color.success'),
          isNotEmpty,
        );
      });
    });

    group('color.warning', () {
      test('orange warning passes', () {
        final tokens = _resolve(_theme(warningColor: '#FF9F0A'));
        final violations = ThemeSubmissionChecker.checkSafeZones(tokens);
        expect(
          violations.where((v) => v.tokenPath == 'color.warning'),
          isEmpty,
        );
      });

      test('yellow warning passes', () {
        final tokens = _resolve(_theme(warningColor: '#FFD60A'));
        final violations = ThemeSubmissionChecker.checkSafeZones(tokens);
        expect(
          violations.where((v) => v.tokenPath == 'color.warning'),
          isEmpty,
        );
      });

      test('blue warning is a violation', () {
        final tokens = _resolve(_theme(warningColor: '#0088FF'));
        final violations = ThemeSubmissionChecker.checkSafeZones(tokens);
        expect(
          violations.where((v) => v.tokenPath == 'color.warning'),
          isNotEmpty,
        );
      });

      test('pure green warning is a violation', () {
        final tokens = _resolve(_theme(warningColor: '#00FF00'));
        final violations = ThemeSubmissionChecker.checkSafeZones(tokens);
        expect(
          violations.where((v) => v.tokenPath == 'color.warning'),
          isNotEmpty,
        );
      });
    });

    group('default resolved tokens', () {
      test('default theme has no safe zone violations', () {
        const minimal = '''
version: "1.0"
meta:
  name: "Minimal"
''';
        final tokens = _resolve(minimal);
        final violations = ThemeSubmissionChecker.checkSafeZones(tokens);
        expect(violations, isEmpty);
      });
    });

    group('SafeZoneViolation', () {
      test('has tokenPath and message fields', () {
        final tokens = _resolve(_theme());
        tokens['color.text.primary'] = 'rgba(0,0,0,0.1)';
        final violations = ThemeSubmissionChecker.checkSafeZones(tokens);
        final v = violations.first;
        expect(v.tokenPath, isA<String>());
        expect(v.message, isA<String>());
        expect(v.tokenPath, isNotEmpty);
        expect(v.message, isNotEmpty);
      });
    });
  });
}
