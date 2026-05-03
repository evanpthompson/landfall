import 'package:flutter/material.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';

/// Interactive drag-to-move grid layout editor.
///
/// Tapping a card *selects* it and opens the card HUD. Dragging moves the
/// card; the resize handle in the bottom-right corner resizes it. Locked cards
/// ignore drag and resize gestures and hide the resize handle.
///
/// Calls [onLayoutChanged] on every move, resize, or per-card config change.
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
  String? _selectedId;
  String? _draggingId;
  int? _ghostCol;
  int? _ghostRow;

  String? _resizingId;
  int? _ghostColSpan;
  int? _ghostRowSpan;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellW = constraints.maxWidth / widget.layout.columns;
        final cellH = constraints.maxHeight / widget.layout.rows;

        // Put the dragging card last so it renders on top (UX-01).
        final ordered = [
          ...widget.layout.cards.where((c) => c.id != _draggingId),
          ...widget.layout.cards.where((c) => c.id == _draggingId),
        ];

        return Stack(
          key: const ValueKey('card_stack'),
          children: [
            _GridLines(
              columns: widget.layout.columns,
              rows: widget.layout.rows,
            ),
            if (_draggingId != null && _ghostCol != null && _ghostRow != null)
              _buildGhost(cellW, cellH),
            if (_resizingId != null &&
                _ghostColSpan != null &&
                _ghostRowSpan != null)
              _buildResizeGhost(cellW, cellH),
            ...ordered.map((c) => _buildCardTile(c, cellW, cellH)),
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
    final resizing = widget.layout.cards.firstWhere((c) => c.id == _resizingId);
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
    final isSelected = _selectedId == config.id;
    final color = _cardColor(config.source);

    return Positioned(
      key: ValueKey('card_tile_${config.id}'),
      left: slot.column * cellW + _kGap,
      top: slot.row * cellH + _kGap,
      width: slot.columnSpan * cellW - _kGap * 2,
      height: slot.rowSpan * cellH - _kGap * 2,
      child: GestureDetector(
        onTap: () => _selectCard(config),
        onPanStart: config.locked
            ? null
            : (details) {
                if (_resizingId == config.id) return;
                setState(() {
                  _draggingId = config.id;
                  _ghostCol = slot.column;
                  _ghostRow = slot.row;
                });
              },
        onPanUpdate: config.locked
            ? null
            : (details) {
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
        onPanEnd: config.locked
            ? null
            : (_) {
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
            // Selection highlight
            if (isSelected)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    key: ValueKey('selection_highlight_${config.id}'),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: LandfallColors.accent,
                        width: 2.5,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            // Lock badge — bottom-left corner
            if (config.locked)
              Positioned(
                left: 4,
                bottom: 4,
                child: Icon(
                  key: ValueKey('lock_badge_${config.id}'),
                  Icons.lock,
                  size: 12,
                  color: color.withValues(alpha: 0.8),
                ),
              ),
            // Resize handle — hidden for locked cards
            if (!config.locked)
              Positioned(
                right: 2,
                bottom: 2,
                child: GestureDetector(
                  key: ValueKey('resize_handle_${config.id}'),
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (_) {
                    setState(() {
                      _draggingId = null;
                      _ghostCol = null;
                      _ghostRow = null;
                      _resizingId = config.id;
                      _ghostColSpan = slot.columnSpan;
                      _ghostRowSpan = slot.rowSpan;
                    });
                  },
                  onPanUpdate: (details) {
                    final box = context.findRenderObject() as RenderBox?;
                    if (box == null) return;
                    final local = box.globalToLocal(details.globalPosition);
                    setState(() {
                      _ghostColSpan =
                          ((local.dx / cellW).ceil() - slot.column).clamp(
                              1, widget.layout.columns - slot.column);
                      _ghostRowSpan =
                          ((local.dy / cellH).ceil() - slot.row).clamp(
                              1, widget.layout.rows - slot.row);
                    });
                  },
                  onPanEnd: (_) {
                    if (_resizingId != null &&
                        _ghostColSpan != null &&
                        _ghostRowSpan != null &&
                        (_ghostColSpan != slot.columnSpan ||
                            _ghostRowSpan != slot.rowSpan)) {
                      _commitResize(config, _ghostColSpan!, _ghostRowSpan!);
                    }
                    setState(() {
                      _resizingId = null;
                      _ghostColSpan = null;
                      _ghostRowSpan = null;
                    });
                  },
                  child: _ResizeHandle(color: color),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _selectCard(CardConfig config) {
    setState(() => _selectedId = config.id);
    _showCardHud(config);
  }

  void _showCardHud(CardConfig config) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => _CardHud(
        config: config,
        layout: widget.layout,
        onLayoutChanged: widget.onLayoutChanged,
        onDismiss: () {
          setState(() => _selectedId = null);
          Navigator.pop(context);
        },
      ),
    ).then((_) {
      if (mounted) setState(() => _selectedId = null);
    });
  }

  DashboardLayout _rebuild(List<CardConfig> cards) => DashboardLayout(
        id: widget.layout.id,
        name: widget.layout.name,
        columns: widget.layout.columns,
        rows: widget.layout.rows,
        cards: cards,
      );

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
    widget.onLayoutChanged(_rebuild(updated));
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

// ---------------------------------------------------------------------------
// Card HUD
// ---------------------------------------------------------------------------

class _CardHud extends StatelessWidget {
  const _CardHud({
    required this.config,
    required this.layout,
    required this.onLayoutChanged,
    required this.onDismiss,
  });

  final CardConfig config;
  final DashboardLayout layout;
  final ValueChanged<DashboardLayout> onLayoutChanged;
  final VoidCallback onDismiss;

  DashboardLayout _rebuild(List<CardConfig> cards) => DashboardLayout(
        id: layout.id,
        name: layout.name,
        columns: layout.columns,
        rows: layout.rows,
        cards: cards,
      );

  void _updateCard(BuildContext context, CardConfig updated) {
    final cards = layout.cards.map((c) => c.id == config.id ? updated : c).toList();
    onLayoutChanged(_rebuild(cards));
  }

  void _bringToFront() {
    final others = layout.cards.where((c) => c.id != config.id).toList();
    onLayoutChanged(_rebuild([...others, config]));
  }

  void _sendToBack() {
    final others = layout.cards.where((c) => c.id != config.id).toList();
    onLayoutChanged(_rebuild([config, ...others]));
  }

  void _delete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove card?'),
        content: Text('Remove "${_cardLabel(config.source)}" from this layout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const ValueKey('hud_delete_confirm'),
            onPressed: () {
              Navigator.pop(ctx);
              final cards = layout.cards.where((c) => c.id != config.id).toList();
              onLayoutChanged(_rebuild(cards));
              onDismiss();
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('card_hud'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _cardLabel(config.source),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      config.source,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onDismiss,
              ),
            ],
          ),
          const Divider(),
          // Toggles row
          Row(
            children: [
              Expanded(
                child: _HudToggle(
                  key: const ValueKey('hud_visibility_toggle'),
                  icon: config.visible ? Icons.visibility : Icons.visibility_off,
                  label: config.visible ? 'Visible' : 'Hidden',
                  onTap: () => _updateCard(context, config.copyWith(visible: !config.visible)),
                ),
              ),
              Expanded(
                child: _HudToggle(
                  key: const ValueKey('hud_lock_toggle'),
                  icon: config.locked ? Icons.lock : Icons.lock_open,
                  label: config.locked ? 'Locked' : 'Unlocked',
                  onTap: () => _updateCard(context, config.copyWith(locked: !config.locked)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Z-order and delete row
          Row(
            children: [
              Expanded(
                child: _HudAction(
                  key: const ValueKey('hud_bring_to_front'),
                  icon: Icons.flip_to_front,
                  label: 'Bring to front',
                  onTap: _bringToFront,
                ),
              ),
              Expanded(
                child: _HudAction(
                  key: const ValueKey('hud_send_to_back'),
                  icon: Icons.flip_to_back,
                  label: 'Send to back',
                  onTap: _sendToBack,
                ),
              ),
              Expanded(
                child: _HudAction(
                  key: const ValueKey('hud_delete'),
                  icon: Icons.delete_outline,
                  label: 'Remove',
                  onTap: () => _delete(context),
                  destructive: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _cardLabel(String source) => switch (source) {
        'system.clock' => 'Clock',
        'system.weather' => 'Weather',
        'system.weather.forecast' => 'Forecast',
        'system.calendar' => 'Calendar',
        'system.photos' => 'Photos',
        _ => source,
      };
}

class _HudToggle extends StatelessWidget {
  const _HudToggle({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _HudAction extends StatelessWidget {
  const _HudAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? Theme.of(context).colorScheme.error : null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Resize handle widget
// ---------------------------------------------------------------------------

class _ResizeHandle extends StatelessWidget {
  const _ResizeHandle({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _ResizeHandlePainter(color: color)),
    );
  }
}

class _ResizeHandlePainter extends CustomPainter {
  _ResizeHandlePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.75)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    const spacing = 5.0;
    const len = 4.0;
    for (var i = 0; i < 3; i++) {
      final offset = spacing * i;
      canvas.drawLine(
        Offset(size.width - len - offset, size.height - offset),
        Offset(size.width - offset, size.height - len - offset),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ResizeHandlePainter old) => old.color != color;
}

// ---------------------------------------------------------------------------
// Grid lines
// ---------------------------------------------------------------------------

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
