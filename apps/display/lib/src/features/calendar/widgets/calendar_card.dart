import 'package:flutter/material.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';

/// Displays calendar events in daily, weekly, or monthly view.
///
/// Pure presentational — wrap with [BlocBuilder<CalendarCubit, CalendarState>].
/// View is controlled by [displayConfig]['view']: 'daily' (default), 'weekly', 'monthly'.
class CalendarCard extends StatelessWidget {
  const CalendarCard({
    super.key,
    required this.events,
    this.displayConfig = const {},
  });

  final List<CalendarEventEntity> events;
  final Map<String, dynamic> displayConfig;

  @override
  Widget build(BuildContext context) {
    final tokens = LandfallActiveTheme.of(context);
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: switch (displayConfig['view']) {
          'weekly' => _WeeklyView(events: events),
          'monthly' => _MonthlyView(events: events),
          _ => _DailyView(events: events),
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Daily view (original list layout)
// ---------------------------------------------------------------------------

class _DailyView extends StatelessWidget {
  const _DailyView({required this.events});

  final List<CalendarEventEntity> events;

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByDay(events);

    return Column(
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
    final dt = DateTime(
        int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
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
    final textTertiary =
        tokenColor(LandfallActiveTheme.of(context).colorTextTertiary);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            group.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
              color: textTertiary,
            ),
          ),
          const SizedBox(height: 6),
          ...group.events.map((e) => _EventRow(event: e)),
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event});

  final CalendarEventEntity event;

  @override
  Widget build(BuildContext context) {
    final tokens = LandfallActiveTheme.of(context);
    final textPrimary = tokenColor(tokens.colorTextPrimary);
    final textSecondary = tokenColor(tokens.colorTextSecondary);
    final textTertiary = tokenColor(tokens.colorTextTertiary);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(_timeLabel,
                style: LandfallTypography.eventTime
                    .copyWith(color: textSecondary)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: LandfallTypography.eventTitle
                      .copyWith(color: textPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  event.calendarName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: textTertiary,
                  ),
                ),
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
}

// ---------------------------------------------------------------------------
// Weekly view
// ---------------------------------------------------------------------------

class _WeeklyView extends StatelessWidget {
  const _WeeklyView({required this.events});

  final List<CalendarEventEntity> events;

  static const _dayAbbr = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Monday of the current week
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));

    // Bucket events by weekday index (0 = Mon, 6 = Sun)
    final byDay = List.generate(7, (_) => <CalendarEventEntity>[]);
    for (final event in events) {
      final local = event.startTime.toLocal();
      final eventDay = DateTime(local.year, local.month, local.day);
      final diff = eventDay.difference(monday).inDays;
      if (diff >= 0 && diff < 7) {
        byDay[diff].add(event);
      }
    }

    final tokens = LandfallActiveTheme.of(context);
    final textTertiary = tokenColor(tokens.colorTextTertiary);
    final textSecondary = tokenColor(tokens.colorTextSecondary);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('THIS WEEK',
            style: LandfallTypography.widgetHeading
                .copyWith(color: textTertiary)),
        const SizedBox(height: 12),
        // Day headers
        Row(
          children: List.generate(7, (i) {
            final day = monday.add(Duration(days: i));
            return Expanded(
              child: Column(
                children: [
                  Text(
                    _dayAbbr[i],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                      color: textTertiary,
                    ),
                  ),
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1),
        const SizedBox(height: 8),
        // Event columns
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(7, (i) {
              return Expanded(
                child: ClipRect(
                  child: OverflowBox(
                    alignment: Alignment.topLeft,
                    maxHeight: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: byDay[i]
                          .map((e) => _WeekEventBlock(event: e))
                          .toList(),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _WeekEventBlock extends StatelessWidget {
  const _WeekEventBlock({required this.event});

  final CalendarEventEntity event;

  @override
  Widget build(BuildContext context) {
    final tokens = LandfallActiveTheme.of(context);
    final accent = tokenColor(tokens.colorAccent);
    final textPrimary = tokenColor(tokens.colorTextPrimary);
    return Container(
      margin: const EdgeInsets.only(bottom: 4, right: 2),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withAlpha(40),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: accent.withAlpha(100)),
      ),
      child: Text(
        event.title,
        style: TextStyle(
          fontSize: 10,
          color: textPrimary,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Monthly view
// ---------------------------------------------------------------------------

class _MonthlyView extends StatelessWidget {
  const _MonthlyView({required this.events});

  final List<CalendarEventEntity> events;

  static const _dayHeaders = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  static const _monthNames = [
    'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE',
    'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER',
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstOfMonth = DateTime(now.year, now.month, 1);
    // How many blank cells before day 1 (Mon=0 offset)
    final startOffset = firstOfMonth.weekday - 1;
    final daysInMonth =
        DateTime(now.year, now.month + 1, 0).day;

    // Bucket events by day-of-month
    final byDay = <int, List<CalendarEventEntity>>{};
    for (final event in events) {
      final local = event.startTime.toLocal();
      if (local.year == now.year && local.month == now.month) {
        byDay.putIfAbsent(local.day, () => []).add(event);
      }
    }

    final totalCells = startOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();

    final tokens = LandfallActiveTheme.of(context);
    final textTertiary = tokenColor(tokens.colorTextTertiary);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_monthNames[now.month - 1],
            style: LandfallTypography.widgetHeading
                .copyWith(color: textTertiary)),
        const SizedBox(height: 8),
        // Day-of-week header
        Row(
          children: _dayHeaders
              .map((h) => Expanded(
                    child: Center(
                      child: Text(
                        h,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: textTertiary,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: Column(
            children: List.generate(rows, (row) {
              return Expanded(
                child: Row(
                  children: List.generate(7, (col) {
                    final cellIndex = row * 7 + col;
                    final dayNumber = cellIndex - startOffset + 1;
                    if (dayNumber < 1 || dayNumber > daysInMonth) {
                      return const Expanded(child: SizedBox.shrink());
                    }
                    final dayEvents = byDay[dayNumber] ?? [];
                    return Expanded(
                      child: _MonthCell(
                        day: dayNumber,
                        events: dayEvents,
                        isToday: dayNumber == now.day,
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _MonthCell extends StatelessWidget {
  const _MonthCell({
    required this.day,
    required this.events,
    required this.isToday,
  });

  final int day;
  final List<CalendarEventEntity> events;
  final bool isToday;

  static const _maxDots = 3;

  @override
  Widget build(BuildContext context) {
    final tokens = LandfallActiveTheme.of(context);
    final accent = tokenColor(tokens.colorAccent);
    final textPrimary = tokenColor(tokens.colorTextPrimary);
    final textTertiary = tokenColor(tokens.colorTextTertiary);
    final overflow = events.length > _maxDots ? events.length - _maxDots : 0;
    final dotCount = events.length.clamp(0, _maxDots);

    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.topCenter,
        maxHeight: double.infinity,
        child: Padding(
      padding: const EdgeInsets.all(1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Day number
          Container(
            width: 22,
            height: 22,
            decoration: isToday
                ? BoxDecoration(color: accent, shape: BoxShape.circle)
                : null,
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      isToday ? FontWeight.w700 : FontWeight.w400,
                  color: isToday ? Colors.white : textPrimary,
                ),
              ),
            ),
          ),
          if (dotCount > 0) ...[
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                dotCount,
                (_) => Container(
                  width: 4,
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
          if (overflow > 0)
            Text(
              '+$overflow',
              style: TextStyle(
                fontSize: 9,
                color: textTertiary,
              ),
            ),
        ],
      ),
        ),
      ),
    );
  }
}
