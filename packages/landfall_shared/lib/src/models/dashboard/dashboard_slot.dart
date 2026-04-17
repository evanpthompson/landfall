/// A position and size within the display grid.
///
/// The grid coordinate system starts at (0, 0) — top-left corner of the
/// display. [column] and [row] are zero-based. Spans must be at least 1.
///
/// Example: a slot at column 0, row 0, spanning 3 columns and 2 rows
/// occupies the top-left 3×2 block of the grid.
class DashboardSlot {
  DashboardSlot({
    required this.column,
    required this.row,
    required this.columnSpan,
    required this.rowSpan,
  }) {
    if (column < 0) throw ArgumentError.value(column, 'column', 'must be >= 0');
    if (row < 0) throw ArgumentError.value(row, 'row', 'must be >= 0');
    if (columnSpan < 1) {
      throw ArgumentError.value(columnSpan, 'columnSpan', 'must be >= 1');
    }
    if (rowSpan < 1) {
      throw ArgumentError.value(rowSpan, 'rowSpan', 'must be >= 1');
    }
  }

  /// Zero-based starting column of this slot.
  final int column;

  /// Zero-based starting row of this slot.
  final int row;

  /// Number of columns this slot spans. Must be at least 1.
  final int columnSpan;

  /// Number of rows this slot spans. Must be at least 1.
  final int rowSpan;

  DashboardSlot copyWith({
    int? column,
    int? row,
    int? columnSpan,
    int? rowSpan,
  }) {
    return DashboardSlot(
      column: column ?? this.column,
      row: row ?? this.row,
      columnSpan: columnSpan ?? this.columnSpan,
      rowSpan: rowSpan ?? this.rowSpan,
    );
  }

  Map<String, dynamic> toJson() => {
        'column': column,
        'row': row,
        'columnSpan': columnSpan,
        'rowSpan': rowSpan,
      };

  factory DashboardSlot.fromJson(Map<String, dynamic> json) => DashboardSlot(
        column: json['column'] as int,
        row: json['row'] as int,
        columnSpan: json['columnSpan'] as int,
        rowSpan: json['rowSpan'] as int,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardSlot &&
          column == other.column &&
          row == other.row &&
          columnSpan == other.columnSpan &&
          rowSpan == other.rowSpan;

  @override
  int get hashCode => Object.hash(column, row, columnSpan, rowSpan);

  @override
  String toString() =>
      'DashboardSlot(col: $column, row: $row, '
      'span: $columnSpan×$rowSpan)';
}
