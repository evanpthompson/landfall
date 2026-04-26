import 'dart:convert';

import 'package:landfall_client/landfall_client.dart';
import 'package:landfall_shared/landfall_shared.dart';

/// Production [DashboardLayoutRepository] backed by the Serverpod [LayoutEndpoint].
///
/// Layout configs are stored server-side so all displays sharing the same
/// server instance stay in sync. The local Drift repository is used as a
/// fallback when the server is unreachable.
class ServerpodLayoutRepository implements DashboardLayoutRepository {
  const ServerpodLayoutRepository(this._client, this._fallback);

  final Client _client;
  final DashboardLayoutRepository _fallback;

  // ── read ──────────────────────────────────────────────────────────────────

  @override
  Future<DashboardLayout> getActiveLayout() async {
    try {
      final all = await _client.layout.getLayouts();
      if (all.isEmpty) return DashboardLayout.defaultLayout();
      final active = all.firstWhere(
        (l) => l.isActive,
        orElse: () => all.first,
      );
      return _fromConfig(active);
    } catch (_) {
      return _fallback.getActiveLayout();
    }
  }

  @override
  Future<List<DashboardLayout>> getAllLayouts() async {
    try {
      final all = await _client.layout.getLayouts();
      if (all.isEmpty) {
        return [
          DashboardLayout.weekdayLayout(),
          DashboardLayout.weekendLayout(),
          DashboardLayout.nightLayout(),
        ];
      }
      return all.map(_fromConfig).toList();
    } catch (_) {
      return _fallback.getAllLayouts();
    }
  }

  // ── write ─────────────────────────────────────────────────────────────────

  @override
  Future<void> saveLayout(DashboardLayout layout) async {
    try {
      final config = _toConfig(layout);
      final saved = await _client.layout.saveLayout(config);
      // If the layout was already active or has no peers, set it active.
      final all = await _client.layout.getLayouts();
      if (all.length == 1 || layout.id.startsWith('layout-preset-')) {
        await _client.layout.setActiveLayout(saved.id!);
      }
    } catch (_) {
      await _fallback.saveLayout(layout);
    }
  }

  @override
  Future<void> setActiveLayout(String layoutId) async {
    try {
      final id = _serverId(layoutId);
      if (id != null) {
        await _client.layout.setActiveLayout(id);
      }
    } catch (_) {
      await _fallback.setActiveLayout(layoutId);
    }
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  static DashboardLayout _fromConfig(LayoutConfig config) {
    final rawCards = jsonDecode(config.cardsJson) as List<dynamic>;
    return DashboardLayout(
      id: 'layout-${config.id}',
      name: config.name,
      columns: config.columnsCount,
      rows: config.rowsCount,
      presetType: LayoutPresetType.values
          .firstWhere((p) => p.name == config.presetType,
              orElse: () => LayoutPresetType.custom),
      cards: rawCards
          .map((e) => CardConfig.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static LayoutConfig _toConfig(DashboardLayout layout) {
    return LayoutConfig(
      id: _serverId(layout.id),
      name: layout.name,
      presetType: layout.presetType.name,
      columnsCount: layout.columns,
      rowsCount: layout.rows,
      cardsJson: jsonEncode(layout.cards.map((c) => c.toJson()).toList()),
      isActive: false,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  static int? _serverId(String layoutId) {
    // Domain layout IDs are 'layout-{int}' — strip the prefix.
    final raw = layoutId.replaceFirst('layout-', '');
    return int.tryParse(raw);
  }
}
