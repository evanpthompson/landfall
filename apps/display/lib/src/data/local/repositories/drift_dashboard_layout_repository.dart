import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:landfall_shared/landfall_shared.dart';

import 'package:display/src/data/local/app_database.dart';

/// Production [DashboardLayoutRepository] backed by a local Drift/SQLite DB.
///
/// Stores a single active layout (id = 1). On first read, returns
/// [DashboardLayout.defaultLayout] and does not write to the database — the
/// layout is persisted only on the first explicit [saveLayout] call.
class DriftDashboardLayoutRepository implements DashboardLayoutRepository {
  DriftDashboardLayoutRepository(this._db);

  static const _layoutId = 1;

  final AppDatabase _db;

  @override
  Future<DashboardLayout> getActiveLayout() async {
    final entry = await (_db.select(_db.layoutEntries)
          ..where((t) => t.id.equals(_layoutId)))
        .getSingleOrNull();

    if (entry == null) {
      return DashboardLayout.defaultLayout();
    }

    final rawCards = jsonDecode(entry.cardsJson) as List<dynamic>;
    return DashboardLayout(
      id: 'layout-$_layoutId',
      name: entry.name,
      columns: entry.columnsCount,
      rows: entry.rowsCount,
      cards: rawCards
          .map((e) => CardConfig.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Future<List<DashboardLayout>> getAllLayouts() async {
    final entry = await (_db.select(_db.layoutEntries)
          ..where((t) => t.id.equals(_layoutId)))
        .getSingleOrNull();
    if (entry == null) {
      return [
        DashboardLayout.weekdayLayout(),
        DashboardLayout.weekendLayout(),
        DashboardLayout.nightLayout(),
      ];
    }
    // Drift stores one active layout — return the three presets with the
    // saved one replacing the matching preset slot.
    final active = await getActiveLayout();
    final presets = [
      DashboardLayout.weekdayLayout(),
      DashboardLayout.weekendLayout(),
      DashboardLayout.nightLayout(),
    ];
    return presets.map((p) {
      if (p.presetType == active.presetType) return active;
      return p;
    }).toList();
  }

  @override
  Future<void> setActiveLayout(String layoutId) async {
    // Drift only stores one layout; switching preset loads the preset default
    // unless a saved layout with that id already exists.
    final presetMap = {
      'layout-weekday': DashboardLayout.weekdayLayout(),
      'layout-weekend': DashboardLayout.weekendLayout(),
      'layout-night': DashboardLayout.nightLayout(),
    };
    final target = presetMap[layoutId];
    if (target != null) await saveLayout(target);
  }

  @override
  Future<void> saveLayout(DashboardLayout layout) async {
    final cardsJson =
        jsonEncode(layout.cards.map((c) => c.toJson()).toList());

    await _db.into(_db.layoutEntries).insertOnConflictUpdate(
          LayoutEntriesCompanion(
            id: const Value(_layoutId),
            name: Value(layout.name),
            columnsCount: Value(layout.columns),
            rowsCount: Value(layout.rows),
            cardsJson: Value(cardsJson),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }
}
