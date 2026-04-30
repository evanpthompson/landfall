/// When a dashboard profile is automatically activated.
enum ProfileScheduleType {
  /// Always active — no time or day restriction.
  always,

  /// Active on weekdays (Monday–Friday).
  weekday,

  /// Active on weekends (Saturday–Sunday).
  weekend,

  /// Active every day within a fixed time range.
  daily,

  /// Active on specific days of the week within an optional time range.
  custom;
}
