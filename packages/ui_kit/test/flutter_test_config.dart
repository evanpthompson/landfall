import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  goldenFileComparator = _ToleranceGoldenComparator(
    goldenFileComparator as LocalFileComparator,
  );
  await testMain();
}

// Allows up to 5% pixel difference.
// macOS and Linux Flutter test renderers produce small diffs on text-heavy
// widgets due to font metric differences. 5% catches real regressions
// (typically >10% diff) while tolerating platform rendering variance.
class _ToleranceGoldenComparator extends GoldenFileComparator {
  _ToleranceGoldenComparator(this._delegate);

  final LocalFileComparator _delegate;
  static const double _maxDiffPercent = 0.05;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    try {
      return await _delegate.compare(imageBytes, golden);
    } catch (e) {
      final message = e.toString();
      final match = RegExp(r'(\d+(?:\.\d+)?)%').firstMatch(message);
      if (match != null) {
        final diffPercent = double.parse(match.group(1)!) / 100.0;
        if (diffPercent <= _maxDiffPercent) return true;
      }
      rethrow;
    }
  }

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) =>
      _delegate.update(golden, imageBytes);

  @override
  Uri getTestUri(Uri key, int? version) =>
      _delegate.getTestUri(key, version);
}
