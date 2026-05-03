import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  goldenFileComparator = _ToleranceGoldenComparator(
    goldenFileComparator as LocalFileComparator,
  );
  await testMain();
}

// Allows up to 1% pixel difference — covers the ~0.3% macOS/Linux rendering
// gap without masking real regressions.
class _ToleranceGoldenComparator extends GoldenFileComparator {
  _ToleranceGoldenComparator(this._delegate);

  final LocalFileComparator _delegate;
  static const double _maxDiffPercent = 0.01;

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
