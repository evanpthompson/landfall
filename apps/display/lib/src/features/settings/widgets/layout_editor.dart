import 'package:flutter/material.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';

/// Interactive drag-to-move grid layout editor.
///
/// Renders the dashboard layout at whatever size it is given. Each card is a
/// colored tile; dragging a tile snaps it to the nearest grid cell on release.
/// Tapping a tile toggles its [CardConfig.visible] flag.
///
/// Calls [onLayoutChanged] immediately on every move or visibility toggle so
/// the parent can persist the updated layout.
class LayoutEditor extends StatefulWidget {
  const LayoutEditor({
    super.key,
    required this.layout,
    required this.onLayoutChanged,
  });

  final DashboardLayout layout;
  final ValueChanged<DashboardLayout> onLayoutChanged;

  @override
  State<LayoutEditor> createState() => _LayoutEditorState();
}

class _LayoutEditorState extends State<LayoutEditor> {
  String? _draggingId;
  int? _ghostCol;
  int? _ghostRow;

  // Resize state
  String? _resizingId;
  int? _ghostColSpan;
  int? _ghostRowSpan;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellW = constraints.maxWidth / widget.layout.columns;
        final cellH = constraints.maxHeight / widget.layout.rows;

        return Stack(
          children: [
            _GridLines(
              columns: widget.layout.columns,
              rows: widget.layout.rows,
            ),
            // Ghost drop-target while dragging
            if (_draggingId != null && _ghostCol != null && _ghostRow != null)
              _buildGhost(cellW, cellH),
            // Ghost resize outline while resizing
            if (_resizingId != null &&
                _ghostColSpan != null &&
                _ghostRowSpan != null)
              _buildResizeGhost(cellW, cellH),
            // Cards — all cards including hidden ones (shown with reduced opacity)
            ...widget.layout.cards.map(
              (c) => _buildCardTile(c, cellW, cellH),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGhost(double cellW, double cellH) {
    final dragging = widget.layout.cards.firstWhere((c) => c.id == _draggingId);
    final slot = dragging.slot;
    return Positioned(
      left: _ghostCol! * cellW + _kGap,
      top: _ghostRow! * cellH + _kGap,
      width: slot.columnSpan * cellW - _kGap * 2,
      height: slot.rowSpan * cellH - _kGap * 2,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: LandfallColors.accent, width: 2),
          borderRadius: BorderRadius.circular(6),
          color: LandfallColors.accentMuted,
        ),
      ),
    );
  }

  Widget _buildResizeGhost(double cellW, double cellH) {
    final resizing =
        widget.layout.cards.firstWhere((c) => c.id == _resizingId);
    final slot = resizing.slot;
    return Positioned(
      left: slot.column * cellW + _kGap,
      top: slot.row * cellH + _kGap,
      width: _ghostColSpan! * cellW - _kGap * 2,
      height: _ghostRowSpan! * cellH - _kGap * 2,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: LandfallColors.accent.withValues(alpha: 0.6),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(6),
          color: LandfallColors.accentMuted,
        ),
      ),
    );
  }

  Widget _buildCardTile(CardConfig config, double cellW, double cellH) {
    final slot = config.slot;
    final isBeingDragged = _draggingId == config.id;
    final color = _cardColor(config.source);

    return Positioned(
      left: slot.column * cellW + _kGap,
      top: slot.row * cellH + _kGap,
      width: slot.columnSpan * cellW - _kGap * 2,
      height: slot.rowSpan * cellH - _kGap * 2,
      child: GestureDetector(
        onTap: () => _toggleVisible(config),
        onPanStart: (details) {
          // Resize takes priority — don't start a drag if resize is active.
          if (_resizingId == config.id) return;
          setState(() {
            _draggingId = config.id;
            _ghostCol = slot.column;
            _ghostRow = slot.row;
          });
        },
        onPanUpdate: (details) {
          // Ignore drag updates while resize is in progress for this tile.
          if (_resizingId == config.id) return;
          final box = context.findRenderObject() as RenderBox?;
          if (box == null) return;
          final local = box.globalToLocal(details.globalPosition);
          setState(() {
            _ghostCol = (local.dx / cellW)
                .floor()
                .clamp(0, widget.layout.columns - slot.columnSpan);
            _ghostRow = (local.dy / cellH)
                .floor()
                .clamp(0, widget.layout.rows - slot.rowSpan);
          });
        },
        onPanEnd: (_) {
          // If resize is active for this tile, just clear drag state without
          // committing a move — the resize handler will commit its own result.
          if (_resizingId == config.id) {
            setState(() {
              _draggingId = null;
              _ghostCol = null;
              _ghostRow = null;
            });
            return;
          }
          if (_draggingId != null &&
              _ghostCol != null &&
              _ghostRow != null &&
              (_ghostCol != slot.column || _ghostRow != slot.row)) {
            _commitMove(config, _ghostCol!, _ghostRow!);
          }
          setState(() {
            _draggingId = null;
            _ghostCol = null;
            _ghostRow = null;
          });
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isBeingDragged
                    ? 0.3
                    : config.visible
                        ? 1.0
                        : 0.35,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    border: Border.all(
                      color: config.visible
                          ? color.withValues(alpha: 0.7)
                          : color.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _cardLabel(config.source),
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (!config.visible) ...[
                          const SizedBox(height: 4),
                          Text(
                            'hidden',
                            style: TextStyle(
                              color: color.withValues(alpha: 0.5),
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Resize handle — bottom-right corner
            Positioned(
              right: 2,
              bottom: 2,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (_) {
                  setState(() {
                    // Cancel any drag that may have started on the parent tile
                    // simultaneously — resize always takes priority.
                    _draggingId = null;
                    _ghostCol = null;
                    _ghostRow = null;
                    _resizingId = config.id;
                    _ghostColSpan = slot.columnSpan;
                    _ghostRowSpan = slot.rowSpan;
                  });
                },
                onPanUpdate: (details) {
                  final box =
                      context.findRenderObject() as RenderBox?;
                  if (box == null) return;
                  final local =
                      box.globalToLocal(details.globalPosition);
                  setState(() {
                    _ghostColSpan = ((local.dx / cellW).ceil() -
                            slot.column)
                        .clamp(1,
                            widget.layout.columns - slot.column);
                    _ghostRowSpan = ((local.dy / cellH).ceil() -
                            slot.row)
                        .clamp(1,
                            widget.layout.rows - slot.row);
                  });
                },
                onPanEnd: (_) {
                  if (_resizingId != null &&
                      _ghostColSpan != null &&
                      _ghostRowSpan != null &&
                      (_ghostColSpan != slot.columnSpan ||
                          _ghostRowSpan != slot.rowSpan)) {
                    _commitResize(
                        config, _ghostColSpan!, _ghostRowSpan!);
                  }
                  setState(() {
                    _resizingId = null;
                    _ghostColSpan = null;
                    _ghostRowSpan = null;
                  });
                },
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Icon(
                    Icons.open_in_full,
                    size: 10,
                    color: LandfallColors.background,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DashboardLayout _rebuild(List<CardConfig> cards) => DashboardLayout(
        id: widget.layout.id,
        name: widget.layout.name,
        columns: widget.layout.columns,
        rows: widget.layout.rows,
        presetType: widget.layout.presetType,
        cards: cards,
      );

  void _toggleVisible(CardConfig config) {
    final updated = widget.layout.cards
        .map((c) => c.id == config.id ? c.copyWith(visible: !c.visible) : c)
        .toList();
    widget.onLayoutChanged(_rebuild(updated));
  }

  void _commitResize(CardConfig config, int newColSpan, int newRowSpan) {
    final updated = widget.layout.cards.map((c) {
      if (c.id != config.id) return c;
      return c.copyWith(
        slot: DashboardSlot(
          column: c.slot.column,
          row: c.slot.row,
          columnSpan: newColSpan,
          rowSpan: newRowSpan,
        ),
      );
    }).toList();
    widget.onLayoutChanged(
      DashboardLayout(
        id: widget.layout.id,
        name: widget.layout.name,
        columns: widget.layout.columns,
        rows: widget.layout.rows,
        presetType: widget.layout.presetType,
        cards: updated,
      ),
    );
  }

  void _commitMove(CardConfig config, int newCol, int newRow) {
    final updated = widget.layout.cards.map((c) {
      if (c.id != config.id) return c;
      return c.copyWith(
        slot: DashboardSlot(
          column: newCol,
          row: newRow,
          columnSpan: c.slot.columnSpan,
          rowSpan: c.slot.rowSpan,
        ),
      );
    }).toList();
    widget.onLayoutChanged(_rebuild(updated));
  }

  static Color _cardColor(String source) {
    if (source.startsWith('system.clock')) return const Color(0xFF4A9EFF);
    if (source.startsWith('system.weather')) return const Color(0xFF50C878);
    if (source.startsWith('system.calendar')) return const Color(0xFFFF9500);
    if (source.startsWith('system.photos')) return const Color(0xFFBF5AF2);
    return LandfallColors.textSecondary;
  }

  static String _cardLabel(String source) => switch (source) {
        'system.clock' => 'Clock',
        'system.weather' => 'Weather',
        'system.weather.forecast' => 'Forecast',
        'system.calendar' => 'Calendar',
        'system.photos' => 'Photos',
        _ => source,
      };

  static const double _kGap = 8.0;
}

class _GridLines extends StatelessWidget {
  const _GridLines({required this.columns, required this.rows});

  final int columns;
  final int rows;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GridPainter(columns: columns, rows: rows),
      child: const SizedBox.expand(),
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({required this.columns, required this.rows});

  final int columns;
  final int rows;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = LandfallColors.divider.withValues(alpha: 0.4)
      ..strokeWidth = 0.5;

    final cellW = size.width / columns;
    final cellH = size.height / rows;

    for (var c = 0; c <= columns; c++) {
      canvas.drawLine(
        Offset(c * cellW, 0),
        Offset(c * cellW, size.height),
        paint,
      );
    }
    for (var r = 0; r <= rows; r++) {
      canvas.drawLine(
        Offset(0, r * cellH),
        Offset(size.width, r * cellH),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) =>
      old.columns != columns || old.rows != rows;
}
