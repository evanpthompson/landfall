import 'package:flutter/material.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';

/// Displays upcoming calendar events grouped by day.
///
/// Events are displayed in chronological order. All-day events show "All day"
/// in place of a time. The calendar name is shown as a small label on each row
/// so feeds from different sources are distinguishable at a glance.
///
/// Pure presentational — wrap with [BlocBuilder<CalendarCubit, CalendarState>].
class CalendarCard extends StatelessWidget {
  const CalendarCard({super.key, required this.events});

  final List<CalendarEventEntity> events;

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByDay(events);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: LandfallColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LandfallColors.cardBorder, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('UPCOMING', style: LandfallTypography.widgetHeading),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: grouped.length,
                itemBuilder: (context, i) => _DayGroup(group: grouped[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static List<_DayData> _groupByDay(List<CalendarEventEntity> events) {
    final Map<String, List<CalendarEventEntity>> byDay = {};
    for (final event in events) {
      final key = _dayKey(event.startTime.toLocal());
      byDay.putIfAbsent(key, () => []).add(event);
    }

    final now = DateTime.now();
    return byDay.entries
        .map((e) => _DayData(label: _dayLabel(e.key, now), events: e.value))
        .toList();
  }

  static String _dayKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';

  static String _dayLabel(String key, DateTime now) {
    final today = _dayKey(now);
    final tomorrow = _dayKey(now.add(const Duration(days: 1)));
    if (key == today) return 'Today';
    if (key == tomorrow) return 'Tomorrow';
    final parts = key.split('-');
    final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${weekdays[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day}';
  }
}

class _DayData {
  const _DayData({required this.label, required this.events});
  final String label;
  final List<CalendarEventEntity> events;
}

class _DayGroup extends StatelessWidget {
  const _DayGroup({required this.group});

  final _DayData group;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(group.label, style: _dayLabelStyle),
          const SizedBox(height: 6),
          ...group.events.map((e) => _EventRow(event: e)),
        ],
      ),
    );
  }

  static const _dayLabelStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.0,
    color: LandfallColors.textTertiary,
  );
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event});

  final CalendarEventEntity event;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(_timeLabel, style: LandfallTypography.eventTime),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: LandfallTypography.eventTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(event.calendarName, style: _calendarLabelStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _timeLabel {
    if (event.isAllDay) return 'All day';
    final local = event.startTime.toLocal();
    final hour = local.hour;
    final minute = local.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$displayHour:$minuteStr $period';
  }

  static const _calendarLabelStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: LandfallColors.textTertiary,
  );
}
