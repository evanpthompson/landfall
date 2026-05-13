import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// QR badge used by the companion card.
///
/// Sizing rule:
/// - With an explicit [targetSize], use it verbatim.
/// - Otherwise, use the shorter side of the parent's constraints, capped at
///   the 270 px spec ceiling from `docs/companion_card_design.md`. The
///   parent (e.g. CompanionCard's wide/stacked layout) is responsible for
///   giving the QR enough room — a too-small QR is preferable to one that
///   overflows the card.
class CompanionQrCode extends StatelessWidget {
  const CompanionQrCode({
    super.key,
    required this.url,
    this.targetSize,
  });

  final String url;

  /// Optional fixed size in logical px. When null, the widget computes the
  /// size from its parent's constraints.
  final double? targetSize;

  static const double _ceiling = 270;

  @override
  Widget build(BuildContext context) {
    if (targetSize != null) {
      return _box(targetSize!);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final shortSide = _shortFiniteSide(constraints);
        final size = shortSide > _ceiling ? _ceiling : shortSide;
        return _box(size);
      },
    );
  }

  Widget _box(double size) {
    // Align loosens the parent's tight constraints so the inner Container is
    // free to render at exactly `size`. Without it, a Row/SizedBox parent
    // would force the Container to the parent's full width.
    return Align(
      alignment: Alignment.center,
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
        ),
        child: QrImageView(
          data: url,
          semanticsLabel: url,
          version: QrVersions.auto,
          eyeStyle: const QrEyeStyle(
            eyeShape: QrEyeShape.square,
            color: Color(0xFF111318),
          ),
          dataModuleStyle: const QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: Color(0xFF111318),
          ),
        ),
      ),
    );
  }

  static double _shortFiniteSide(BoxConstraints c) {
    final w = c.maxWidth.isFinite ? c.maxWidth : _ceiling;
    final h = c.maxHeight.isFinite ? c.maxHeight : _ceiling;
    return w < h ? w : h;
  }
}
