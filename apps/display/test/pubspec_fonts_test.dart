// Validates that every font asset declared in pubspec.yaml under flutter.fonts
// is a real TrueType/OpenType font and not an accidentally-fetched HTML page.
//
// Regression guard: at one point assets/fonts/Inter-*.ttf were GitHub blob
// HTML pages (curled from /blob/ instead of /raw/), so the engine fetched them
// successfully (200 OK, ~300 KB) but rejected them as invalid fonts — every
// 'Failed to load font Inter' / 'Failed to load font Roboto' error on the
// companion page traced back to those five corrupt files.

import 'dart:io';
import 'package:test/test.dart';

void main() {
  final pubspec = File('pubspec.yaml').readAsStringSync();
  final assetPaths = _extractFontAssets(pubspec);

  test('pubspec.yaml declares at least one font asset', () {
    expect(assetPaths, isNotEmpty,
        reason: 'flutter.fonts parse returned no assets — '
            'parser regression or pubspec restructure');
  });

  for (final asset in assetPaths) {
    test('$asset is a valid font file', () {
      final file = File(asset);
      expect(file.existsSync(), isTrue, reason: '$asset does not exist');
      final raf = file.openSync();
      final magic = raf.readSync(4);
      raf.closeSync();
      expect(magic.length, equals(4), reason: '$asset is empty/truncated');
      // TTF = 00 01 00 00, OTF = "OTTO", TTC = "ttcf", WOFF/WOFF2 = "wOFF"/"wOF2"
      final isTrueType = magic[0] == 0x00 &&
          magic[1] == 0x01 &&
          magic[2] == 0x00 &&
          magic[3] == 0x00;
      final isOpenType = magic[0] == 0x4F &&
          magic[1] == 0x54 &&
          magic[2] == 0x54 &&
          magic[3] == 0x4F;
      final isCollection = magic[0] == 0x74 &&
          magic[1] == 0x74 &&
          magic[2] == 0x63 &&
          magic[3] == 0x66;
      final isWoff = magic[0] == 0x77 &&
          magic[1] == 0x4F &&
          magic[2] == 0x46 &&
          (magic[3] == 0x46 || magic[3] == 0x32);
      expect(
        isTrueType || isOpenType || isCollection || isWoff,
        isTrue,
        reason: '$asset has wrong magic bytes '
            '${magic.map((b) => b.toRadixString(16).padLeft(2, "0")).join(" ")} '
            '— not a valid TTF/OTF/TTC/WOFF font (was it fetched from a '
            'GitHub blob URL instead of the raw URL?)',
      );
    });
  }
}

// Minimal extractor: walks pubspec.yaml top-down, tracks indentation to find
// the `flutter:` → `fonts:` section, and collects every `- asset: <path>`
// inside it. Avoids adding the `yaml` package as a dev dependency.
List<String> _extractFontAssets(String pubspec) {
  final lines = pubspec.split('\n');
  var inFlutter = false;
  var inFonts = false;
  final assets = <String>[];
  for (final line in lines) {
    if (line.isEmpty || line.trimLeft().startsWith('#')) continue;
    final indent = line.length - line.trimLeft().length;
    if (indent == 0) {
      inFlutter = line.startsWith('flutter:');
      inFonts = false;
      continue;
    }
    if (!inFlutter) continue;
    if (indent == 2 && line.trimLeft().startsWith('fonts:')) {
      inFonts = true;
      continue;
    }
    if (indent == 2 && line.trimLeft().endsWith(':')) {
      inFonts = false;
      continue;
    }
    if (!inFonts) continue;
    final match = RegExp(r'^\s*- asset:\s*(\S+)\s*$').firstMatch(line);
    if (match != null) assets.add(match.group(1)!);
  }
  return assets;
}
