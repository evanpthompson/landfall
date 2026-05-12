import 'package:flutter/material.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';

/// Displays the current time from a [ClockEntity].
///
/// Responds to [displayConfig] keys:
/// - `hourFormat`: `'12'` or `'24'` (default `'24'`)
/// - `showSeconds`: bool (default `true`)
/// - `showDate`: bool (default `true`)
class ClockCard extends StatelessWidget {
  const ClockCard({
    super.key,
    required this.entity,
    this.displayConfig = const {},
  });

  final ClockEntity entity;
  final Map<String, dynamic> displayConfig;

  @override
  Widget build(BuildContext context) {
    final tokens = LandfallActiveTheme.of(context);
    final t = entity.now;
    final use12h = displayConfig['hourFormat'] == '12';
    final showSeconds = displayConfig['showSeconds'] != false;
    final showDate = displayConfig['showDate'] != false;

    final String hhmm;
    final String? amPm;
    if (use12h) {
      final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
      hhmm = '$h:${t.minute.toString().padLeft(2, '0')}';
      amPm = t.hour < 12 ? 'AM' : 'PM';
    } else {
      hhmm = '${t.hour.toString().padLeft(2, '0')}:'
          '${t.minute.toString().padLeft(2, '0')}';
      amPm = null;
    }
    final ss = ':${t.second.toString().padLeft(2, '0')}';
    final date = _formatDate(t);

    final textPrimary = tokenColor(tokens.colorTextPrimary);
    final textSecondary = tokenColor(tokens.colorTextSecondary);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokenColor(tokens.cardFill),
        borderRadius: BorderRadius.circular(tokens.cardRadius.toDouble()),
        border: Border.all(
          color: tokenColor(tokens.cardBorderColor),
          width: tokens.cardBorderWidth,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CLOCK',
                style: LandfallTypography.cardLabel
                    .copyWith(color: tokenColor(tokens.colorTextTertiary))),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(hhmm,
                      style: LandfallTypography.timeDisplay
                          .copyWith(color: textPrimary)),
                  if (showSeconds) ...[
                    const SizedBox(width: 6),
                    Text(ss,
                        style: LandfallTypography.timeSeconds
                            .copyWith(color: textSecondary)),
                  ],
                  if (amPm != null) ...[
                    const SizedBox(width: 8),
                    Text(amPm,
                        style: LandfallTypography.timeSeconds
                            .copyWith(color: textSecondary)),
                  ],
                ],
              ),
            ),
            if (showDate) ...[
              const SizedBox(height: 4),
              Text(date,
                  style: LandfallTypography.dateLabel
                      .copyWith(color: textSecondary)),
            ],
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
