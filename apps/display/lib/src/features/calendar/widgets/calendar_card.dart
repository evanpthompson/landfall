import 'package:flutter/material.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';

import 'package:display/src/widgets/stale_badge.dart';

/// Displays calendar events in daily, weekly, or monthly view.
///
/// Pure presentational — wrap with [BlocBuilder<CalendarCubit, CalendarState>].
/// View is controlled by [displayConfig]['view']: 'daily' (default), 'weekly', 'monthly'.
class CalendarCard extends StatelessWidget {
  const CalendarCard({
    super.key,
    required this.events,
    this.displayConfig = const {},
    this.staleSince,
  });

  final List<CalendarEventEntity> events;
  final Map<String, dynamic> displayConfig;

  /// When set, these events could not be refreshed and were last fetched at
  /// this time. Shown as a footnote so a week-old agenda cannot masquerade as
  /// today's.
  final DateTime? staleSince;

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
        child: _ScaleToFit(
          child: Stack(
          children: [
            Positioned.fill(
              child: switch (displayConfig['view']) {
                'daily' => _DailyView(events: events),
                'weekly' => _WeeklyView(events: events),
                'monthly' => _MonthlyView(events: events),
                _ => _BiweeklyView(events: events),
              },
            ),
            if (staleSince != null)
              Positioned(
                top: 0,
                right: 0,
                child: StaleBadge(fetchedAt: staleSince!),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Renders [child] at the size the calendar views are designed for, scaled
/// down proportionally when the slot is smaller than that.
///
/// The type scale targets a wall: an event title is 28 px because it is read
/// from a sofa. A user dragging the card down to a corner of the layout editor
/// must not get an overflow instead of a preview, and shrinking everything
/// together keeps the design intact rather than clipping the bottom off it. At
/// or above the design size this is a no-op, so the wall gets full-size type.
class _ScaleToFit extends StatelessWidget {
  const _ScaleToFit({required this.child});

  /// The smallest slot the views lay out comfortably at.
  static const Size designSize = Size(520, 340);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fits = constraints.maxWidth >= designSize.width &&
            constraints.maxHeight >= designSize.height;
        if (fits) return child;
        return FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: designSize.width,
            height: designSize.height,
            child: child,
          ),
        );
      },
    );
  }
}

// Shared section label used across all calendar views.
class _CalendarLabel extends StatelessWidget {
  const _CalendarLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = LandfallActiveTheme.of(context);
    return Text(
      text,
      style: LandfallTypography.calendarGroupLabel
          .copyWith(color: tokenColor(tokens.colorTextTertiary)),
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
    final now = DateTime.now();
    final todayKey = _dayKey(now);
    final todayEvents = events
        .where((e) => _dayKey(e.startTime.toLocal()) == todayKey)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _CalendarLabel(text: 'CALENDAR — TODAY'),
        const SizedBox(height: 4),
        _DateHeadline(date: now),
        const SizedBox(height: 12),
        // The date is always visible above; the body shows today's events or
        // an explicit empty note so the card never collapses to a heading.
        Expanded(
          child: todayEvents.isEmpty
              ? const _EmptyDayNote(text: 'No events scheduled today')
              : ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: todayEvents.length,
                  itemBuilder: (context, i) => _EventRow(event: todayEvents[i]),
                ),
        ),
      ],
    );
  }
}

// Full date headline shown above the daily list (e.g. "Monday, June 9").
class _DateHeadline extends StatelessWidget {
  const _DateHeadline({required this.date});

  final DateTime date;

  static const _weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];
  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = LandfallActiveTheme.of(context);
    final text =
        '${_weekdays[date.weekday - 1]}, ${_months[date.month - 1]} ${date.day}';
    return Text(
      text,
      style: LandfallTypography.eventTitle
          .copyWith(color: tokenColor(tokens.colorTextPrimary)),
    );
  }
}

// Placeholder shown when a day has no events.
class _EmptyDayNote extends StatelessWidget {
  const _EmptyDayNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final textTertiary =
        tokenColor(LandfallActiveTheme.of(context).colorTextTertiary);
    return Align(
      alignment: Alignment.topLeft,
      child: Text(
        text,
        style: LandfallTypography.calendarMeta.copyWith(color: textTertiary),
      ),
    );
  }
}

String _dayKey(DateTime dt) =>
    '${dt.year.toString().padLeft(4, '0')}-'
    '${dt.month.toString().padLeft(2, '0')}-'
    '${dt.day.toString().padLeft(2, '0')}';

String _dayLabel(String key, DateTime now) {
  final today = _dayKey(now);
  final tomorrow = _dayKey(now.add(const Duration(days: 1)));
  if (key == today) return 'Today';
  if (key == tomorrow) return 'Tomorrow';
  final parts = key.split('-');
  final dt =
      DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${weekdays[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day}';
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
            style: LandfallTypography.calendarGroupLabel
                .copyWith(color: textTertiary),
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
    final textTertiary = tokenColor(tokens.colorTextTertiary);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(_timeLabel,
                style: LandfallTypography.eventTime.copyWith(
                  color: tokenColor(tokens.colorAccent),
                  fontWeight: FontWeight.w500,
                )),
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
                  style:
                      LandfallTypography.calendarMeta.copyWith(color: textTertiary),
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
// Biweekly view (default) — next 14 days, daily-list style
// ---------------------------------------------------------------------------

class _BiweeklyView extends StatelessWidget {
  const _BiweeklyView({required this.events});

  final List<CalendarEventEntity> events;

  static const _spanDays = 14;

  @override
  Widget build(BuildContext context) {
    final days = _buildDays(events);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _CalendarLabel(text: 'CALENDAR — NEXT 2 WEEKS'),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: days.length,
            itemBuilder: (context, i) => _DayGroup(group: days[i]),
          ),
        ),
      ],
    );
  }

  // Always returns one entry per day across the next 14 days so the dates and
  // days are visible even when no events fall in the window. Events are bucketed
  // into their day; days without events render with just their label.
  static List<_DayData> _buildDays(List<CalendarEventEntity> events) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final Map<String, List<CalendarEventEntity>> byDay = {};
    for (final event in events) {
      final local = event.startTime.toLocal();
      final eventDay = DateTime(local.year, local.month, local.day);
      final offset = eventDay.difference(today).inDays;
      if (offset < 0 || offset >= _spanDays) continue;
      byDay.putIfAbsent(_dayKey(local), () => []).add(event);
    }

    return List.generate(_spanDays, (i) {
      final day = today.add(Duration(days: i));
      final key = _dayKey(day);
      final dayEvents = byDay[key] ?? const <CalendarEventEntity>[];
      return _DayData(label: _dayLabel(key, now), events: dayEvents);
    });
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
        const _CalendarLabel(text: 'CALENDAR — THIS WEEK'),
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
                    style: LandfallTypography.calendarDayHeader
                        .copyWith(color: textTertiary),
                  ),
                  Text(
                    '${day.day}',
                    style: LandfallTypography.eventTime
                        .copyWith(color: textSecondary),
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
        style: LandfallTypography.calendarGridEvent
            .copyWith(color: textPrimary),
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
        _CalendarLabel(text: _monthNames[now.month - 1]),
        const SizedBox(height: 8),
        // Day-of-week header
        Row(
          children: _dayHeaders
              .map((h) => Expanded(
                    child: Center(
                      child: Text(
                        h,
                        style: LandfallTypography.calendarDayHeader
                            .copyWith(color: textTertiary),
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

    // The date sizes itself from the cell rather than sitting at a fixed 12 px
    // inside a shrink-to-fit box. The old arrangement scaled *down* as the grid
    // got tighter, so the one thing a month view has to communicate — which
    // square is today, and how busy it is — was the first thing to become
    // unreadable from across the room.
    return LayoutBuilder(
      builder: (context, constraints) {
        // The cell has to hold a date, up to three dots and possibly a "+N"
        // line. Sizing the date off the full height ignored the other two and
        // overflowed a busy day by a few pixels.
        final hasExtras = dotCount > 0 || overflow > 0;
        final dateSize = (constraints.maxHeight * (hasExtras ? 0.38 : 0.52))
            .clamp(LandfallTypography.minContentFontSize, 44.0)
            .toDouble();
        final circle = dateSize * 1.6;
        final dot = (dateSize * 0.22).clamp(5.0, 10.0).toDouble();

        // Drop the "+N" line before squeezing the date: the dots already say
        // the day is busy, and the date is what has to stay readable.
        final pillHeight = dateSize * 1.32;
        final dotsHeight = dotCount > 0 ? dot * 2.2 : 0.0;
        final labelHeight = LandfallTypography.minChromeFontSize * 1.5;
        final showOverflowLabel = overflow > 0 &&
            pillHeight + dotsHeight + labelHeight + 6 <= constraints.maxHeight;

        return Padding(
          padding: const EdgeInsets.all(2),
          // Fail-safe only: the budget above is meant to fit, and this turns
          // any residual miscalculation into slightly smaller type rather than
          // an overflow stripe across the wall.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // A pill rather than a fixed-diameter circle: it hugs the
              // number, so a two-digit date cannot spill outside its own
              // highlight at large type sizes.
              Container(
                constraints: BoxConstraints(minWidth: circle),
                padding: EdgeInsets.symmetric(
                  horizontal: dateSize * 0.3,
                  vertical: dateSize * 0.16,
                ),
                decoration: isToday
                    ? BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(circle),
                      )
                    : const BoxDecoration(),
                child: Center(
                    widthFactor: 1,
                    heightFactor: 1,
                    child: Text(
                      '$day',
                      style: TextStyle(
                        fontSize: dateSize,
                        fontWeight:
                            isToday ? FontWeight.w700 : FontWeight.w400,
                        color: isToday ? Colors.white : textPrimary,
                        height: 1.0,
                      ),
                    ),
                  ),
              ),
              if (dotCount > 0) ...[
                SizedBox(height: dot * 0.6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    dotCount,
                    (_) => Container(
                      width: dot,
                      height: dot,
                      margin: EdgeInsets.symmetric(horizontal: dot * 0.25),
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
              if (showOverflowLabel)
                Text(
                  '+$overflow',
                  style: LandfallTypography.calendarMeta
                      .copyWith(color: textTertiary),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
