import 'package:flutter/material.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';

/// Displays the current time from a [ClockEntity].
///
/// Shows hours:minutes large, seconds smaller to the right (baseline-aligned),
/// and the full date on the line below. This is a pure presentational widget —
/// it does not read from any BLoC. Wire it with [BlocBuilder<ClockCubit, ClockState>]
/// in the parent screen.
///
/// Sized to fill whatever space it is given. Designed for a 3-column × 2-row
/// grid slot (~480×270 px at 1920×1080).
class ClockCard extends StatelessWidget {
  const ClockCard({super.key, required this.entity});

  final ClockEntity entity;

  @override
  Widget build(BuildContext context) {
    final t = entity.now;
    final hhmm = '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}';
    final ss = ':${t.second.toString().padLeft(2, '0')}';
    final date = _formatDate(t);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: LandfallColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: LandfallColors.cardBorder,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(hhmm, style: LandfallTypography.timeDisplay),
                  const SizedBox(width: 6),
                  Text(ss, style: LandfallTypography.timeSeconds),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(date, style: LandfallTypography.dateLabel),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    const months = [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December',
    ];
    return '${weekdays[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day}';
  }
}
