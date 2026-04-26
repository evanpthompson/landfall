import 'package:landfall_shared/src/models/dashboard/card_config.dart';
import 'package:landfall_shared/src/models/dashboard/dashboard_slot.dart';
import 'package:landfall_shared/src/models/dashboard/layout_preset_type.dart';

/// A named display configuration — a grid of [CardConfig] items.
///
/// Every visible card on the display corresponds to a [CardConfig] in the
/// active [DashboardLayout]. Layouts are stored locally in the Drift database
/// and loaded at startup.
///
/// The grid is [columns] × [rows] cells. Cell dimensions are computed at
/// render time from the display's physical resolution. The default grid is
/// 12 × 8, which gives a 160×135 pixel cell at 1920×1080.
class DashboardLayout {
  const DashboardLayout({
    required this.id,
    required this.name,
    required this.cards,
    this.columns = 12,
    this.rows = 8,
    this.presetType = LayoutPresetType.custom,
  });

  /// Unique identifier for this layout.
  final String id;

  /// User-facing name for this layout (e.g., "Default", "Night", "Weekend").
  final String name;

  /// All card configurations — both visible and hidden.
  final List<CardConfig> cards;

  /// Number of columns in the display grid. Defaults to 12.
  final int columns;

  /// Number of rows in the display grid. Defaults to 8.
  final int rows;

  /// Which built-in preset this layout belongs to.
  ///
  /// Preset layouts start from a fixed default arrangement but can be
  /// freely customised by the user. A layout created from scratch is [LayoutPresetType.custom].
  final LayoutPresetType presetType;

  /// Cards with [CardConfig.visible] == true, in declaration order.
  List<CardConfig> get visibleCards => cards.where((c) => c.visible).toList();

  /// The out-of-box layout, used when no saved layout exists.
  static DashboardLayout defaultLayout() => weekdayLayout();

  /// Weekday preset — clock, weather, forecast strip, calendar.
  static DashboardLayout weekdayLayout() {
    return DashboardLayout(
      id: 'layout-weekday',
      name: 'Weekday',
      presetType: LayoutPresetType.weekday,
      cards: [
        CardConfig(
          id: 'slot_clock',
          source: 'system.clock',
          slot: DashboardSlot(column: 0, row: 0, columnSpan: 3, rowSpan: 2),
        ),
        CardConfig(
          id: 'slot_weather',
          source: 'system.weather',
          slot: DashboardSlot(column: 3, row: 0, columnSpan: 9, rowSpan: 4),
        ),
        CardConfig(
          id: 'slot_forecast',
          source: 'system.weather.forecast',
          slot: DashboardSlot(column: 0, row: 2, columnSpan: 3, rowSpan: 2),
        ),
        CardConfig(
          id: 'slot_calendar',
          source: 'system.calendar',
          slot: DashboardSlot(column: 0, row: 4, columnSpan: 7, rowSpan: 4),
        ),
        CardConfig(
          id: 'slot_photos',
          source: 'system.photos',
          slot: DashboardSlot(column: 7, row: 4, columnSpan: 5, rowSpan: 4),
          visible: false,
        ),
      ],
    );
  }

  /// Weekend preset — clock, photos, calendar. Work content hidden.
  static DashboardLayout weekendLayout() {
    return DashboardLayout(
      id: 'layout-weekend',
      name: 'Weekend',
      presetType: LayoutPresetType.weekend,
      cards: [
        CardConfig(
          id: 'slot_clock',
          source: 'system.clock',
          slot: DashboardSlot(column: 0, row: 0, columnSpan: 4, rowSpan: 3),
        ),
        CardConfig(
          id: 'slot_weather',
          source: 'system.weather',
          slot: DashboardSlot(column: 4, row: 0, columnSpan: 8, rowSpan: 3),
        ),
        CardConfig(
          id: 'slot_calendar',
          source: 'system.calendar',
          slot: DashboardSlot(column: 0, row: 3, columnSpan: 5, rowSpan: 5),
        ),
        CardConfig(
          id: 'slot_photos',
          source: 'system.photos',
          slot: DashboardSlot(column: 5, row: 3, columnSpan: 7, rowSpan: 5),
        ),
      ],
    );
  }

  /// Night preset — clock only, minimal content for a bedside display.
  static DashboardLayout nightLayout() {
    return DashboardLayout(
      id: 'layout-night',
      name: 'Night',
      presetType: LayoutPresetType.night,
      cards: [
        CardConfig(
          id: 'slot_clock',
          source: 'system.clock',
          slot: DashboardSlot(column: 3, row: 2, columnSpan: 6, rowSpan: 4),
        ),
        CardConfig(
          id: 'slot_weather',
          source: 'system.weather',
          slot: DashboardSlot(column: 0, row: 0, columnSpan: 12, rowSpan: 2),
          visible: false,
        ),
        CardConfig(
          id: 'slot_calendar',
          source: 'system.calendar',
          slot: DashboardSlot(column: 0, row: 6, columnSpan: 12, rowSpan: 2),
          visible: false,
        ),
        CardConfig(
          id: 'slot_photos',
          source: 'system.photos',
          slot: DashboardSlot(column: 0, row: 0, columnSpan: 3, rowSpan: 4),
          visible: false,
        ),
      ],
    );
  }

  /// Returns the default layout for a given [LayoutPresetType].
  static DashboardLayout forPreset(LayoutPresetType preset) =>
      switch (preset) {
        LayoutPresetType.weekday => weekdayLayout(),
        LayoutPresetType.weekend => weekendLayout(),
        LayoutPresetType.night => nightLayout(),
        LayoutPresetType.custom => weekdayLayout(),
      };

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'columns': columns,
        'rows': rows,
        'presetType': presetType.name,
        'cards': cards.map((c) => c.toJson()).toList(),
      };

  factory DashboardLayout.fromJson(Map<String, dynamic> json) =>
      DashboardLayout(
        id: json['id'] as String,
        name: json['name'] as String,
        columns: json['columns'] as int? ?? 12,
        rows: json['rows'] as int? ?? 8,
        presetType: json['presetType'] != null
            ? LayoutPresetType.values.byName(json['presetType'] as String)
            : LayoutPresetType.custom,
        cards: (json['cards'] as List<dynamic>)
            .map((e) => CardConfig.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardLayout &&
          id == other.id &&
          name == other.name &&
          columns == other.columns &&
          rows == other.rows &&
          presetType == other.presetType &&
          cards.length == other.cards.length &&
          List.generate(cards.length, (i) => cards[i] == other.cards[i])
              .every((e) => e);

  @override
  int get hashCode =>
      Object.hash(id, name, columns, rows, presetType, Object.hashAll(cards));

  @override
  String toString() =>
      'DashboardLayout(id: $id, name: $name, '
      'grid: $columns×$rows, cards: ${cards.length})';
}
