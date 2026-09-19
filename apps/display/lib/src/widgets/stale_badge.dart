import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

/// A quiet "as of <time>" marker for a card whose data could not be refreshed.
///
/// A wall display has no spinner, no refresh button and nobody watching a log:
/// the only way it can admit that a reading is old is to say so on the card.
/// Deliberately low-contrast — it should read as a footnote, not an alarm,
/// because the data behind it is still the best available.
class StaleBadge extends StatelessWidget {
  const StaleBadge({super.key, required this.fetchedAt});

  /// When the data on the card was last fetched successfully.
  final DateTime fetchedAt;

  @override
  Widget build(BuildContext context) {
    final tokens = LandfallActiveTheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.cloud_off_rounded,
          size: 12,
          color: tokenColor(tokens.colorTextTertiary),
        ),
        const SizedBox(width: 4),
        Text(
          'as of ${formatStaleTimestamp(fetchedAt)}',
          style: LandfallTypography.cardLabel.copyWith(
            color: tokenColor(tokens.colorTextTertiary),
          ),
        ),
      ],
    );
  }
}

/// Formats [fetchedAt] for [StaleBadge]: a 12-hour clock time for something
/// from today, and a day name once it is older, because "as of 2:15 PM" on a
/// Thursday is misleading when the reading is from Tuesday.
String formatStaleTimestamp(DateTime fetchedAt, {DateTime? now}) {
  final localFetched = fetchedAt.toLocal();
  final reference = (now ?? DateTime.now()).toLocal();
  final hour = localFetched.hour % 12 == 0 ? 12 : localFetched.hour % 12;
  final minute = localFetched.minute.toString().padLeft(2, '0');
  final meridiem = localFetched.hour < 12 ? 'AM' : 'PM';
  final time = '$hour:$minute $meridiem';

  final sameDay = localFetched.year == reference.year &&
      localFetched.month == reference.month &&
      localFetched.day == reference.day;
  if (sameDay) return time;

  const dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  final difference = reference.difference(localFetched);
  if (difference.inDays >= 7) return '${localFetched.month}/${localFetched.day}';
  return '${dayNames[localFetched.weekday - 1]} $time';
}
