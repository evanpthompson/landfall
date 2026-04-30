import 'package:landfall_shared/src/models/profile/profile_schedule_type.dart';

/// Defines when a dashboard profile is automatically activated.
///
/// [type] determines the day-of-week pattern. [startHour]/[startMinute] and
/// [endHour]/[endMinute] further restrict activation to a time window within
/// matching days. Omitting both start and end means "all day".
///
/// Overnight ranges (e.g. 22:00–06:00) are supported: when [endHour] is less
/// than [startHour] the range wraps past midnight.
class ProfileSchedule {
  const ProfileSchedule({
    required this.type,
    this.startHour,
    this.startMinute,
    this.endHour,
    this.endMinute,
    this.daysOfWeek,
  });

  final ProfileScheduleType type;

  /// Hour of day the schedule becomes active (0–23). Null = start of day.
  final int? startHour;

  /// Minute within [startHour] (0–59). Null = 0.
  final int? startMinute;

  /// Hour of day the schedule ends (0–23). Null = end of day (exclusive).
  final int? endHour;

  /// Minute within [endHour] (0–59). Null = 0.
  final int? endMinute;

  /// Days on which the schedule is active, using ISO weekday numbers
  /// (1 = Monday … 7 = Sunday). Null = all days. Only meaningful when
  /// [type] is [ProfileScheduleType.custom].
  final List<int>? daysOfWeek;

  /// Returns true when this schedule is active at the given [now].
  bool isActiveAt(DateTime now) {
    switch (type) {
      case ProfileScheduleType.always:
        return true;
      case ProfileScheduleType.weekday:
        if (now.weekday > 5) return false;
        return _inTimeWindow(now);
      case ProfileScheduleType.weekend:
        if (now.weekday < 6) return false;
        return _inTimeWindow(now);
      case ProfileScheduleType.daily:
        return _inTimeWindow(now);
      case ProfileScheduleType.custom:
        if (daysOfWeek != null && !daysOfWeek!.contains(now.weekday)) {
          return false;
        }
        return _inTimeWindow(now);
    }
  }

  bool _inTimeWindow(DateTime now) {
    final start = (startHour ?? 0) * 60 + (startMinute ?? 0);
    final end = endHour != null ? endHour! * 60 + (endMinute ?? 0) : 24 * 60;
    final current = now.hour * 60 + now.minute;
    if (start <= end) {
      return current >= start && current < end;
    }
    // Overnight window — wraps past midnight.
    return current >= start || current < end;
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        if (startHour != null) 'startHour': startHour,
        if (startMinute != null) 'startMinute': startMinute,
        if (endHour != null) 'endHour': endHour,
        if (endMinute != null) 'endMinute': endMinute,
        if (daysOfWeek != null) 'daysOfWeek': daysOfWeek,
      };

  factory ProfileSchedule.fromJson(Map<String, dynamic> json) =>
      ProfileSchedule(
        type: ProfileScheduleType.values.byName(json['type'] as String),
        startHour: json['startHour'] as int?,
        startMinute: json['startMinute'] as int?,
        endHour: json['endHour'] as int?,
        endMinute: json['endMinute'] as int?,
        daysOfWeek: (json['daysOfWeek'] as List<dynamic>?)
            ?.map((e) => e as int)
            .toList(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileSchedule &&
          type == other.type &&
          startHour == other.startHour &&
          startMinute == other.startMinute &&
          endHour == other.endHour &&
          endMinute == other.endMinute &&
          _listEqual(daysOfWeek, other.daysOfWeek);

  @override
  int get hashCode => Object.hash(
        type,
        startHour,
        startMinute,
        endHour,
        endMinute,
        Object.hashAll(daysOfWeek ?? []),
      );

  static bool _listEqual(List<int>? a, List<int>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
