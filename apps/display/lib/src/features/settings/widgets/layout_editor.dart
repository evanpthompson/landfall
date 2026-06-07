import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';

/// Interactive grid layout editor.
///
/// In pointer mode (default): tap to select a card and open the HUD; drag to
/// move; drag the corner handle to resize. Locked cards ignore gestures.
///
/// In leanback mode ([leanback] = true): arrow keys navigate between cards,
/// OK/Enter picks up the focused card, arrow keys then shift it one cell at a
/// time, OK/Enter drops it, Escape cancels. Use [onMoveModeChanged] to be
/// notified when the editor enters or leaves move mode (e.g. so a parent
/// PopScope can intercept Back to cancel instead of popping the screen).
class LayoutEditor extends StatefulWidget {
  const LayoutEditor({
    super.key,
    required this.layout,
    required this.onLayoutChanged,
    this.onReset,
    this.leanback = false,
    this.onMoveModeChanged,
    this.onCancelMoveRegistered,
  });

  final DashboardLayout layout;
  final ValueChanged<DashboardLayout> onLayoutChanged;

  /// If provided, a reset button appears in the toolbar that calls this.
  final VoidCallback? onReset;

  /// When true the editor uses D-pad navigation instead of pointer gestures.
  final bool leanback;

  /// Called with `true` when move mode is entered, `false` when it exits.
  final ValueChanged<bool>? onMoveModeChanged;

  /// Called when move mode starts with a [VoidCallback] that cancels the move.
  /// Store the callback and invoke it from a parent [PopScope] so Back cancels
  /// an in-progress move instead of popping the screen.
  final ValueChanged<VoidCallback>? onCancelMoveRegistered;

  @override
  State<LayoutEditor> createState() => _LayoutEditorState();
}

class _LayoutEditorState extends State<LayoutEditor> {
  // ── Pointer mode state ────────────────────────────────────────────────────
  String? _selectedId;
  String? _draggingId;
  int? _ghostCol;
  int? _ghostRow;

  // Delta-based drag tracking — avoids needing a RenderBox lookup.
  Offset? _dragStartGlobal;
  int? _dragStartCol;
  int? _dragStartRow;
  double? _dragCellW;
  double? _dragCellH;

  String? _resizingId;
  int? _ghostColSpan;
  int? _ghostRowSpan;
  Offset? _resizeStartGlobal;
  int? _resizeStartColSpan;
  int? _resizeStartRowSpan;

  bool _snapEnabled = true;
  bool _previewMode = false;

  // ── Leanback (D-pad) state ────────────────────────────────────────────────
  /// ID of the card that currently has D-pad focus (browse mode).
  String? _lbFocusedId;

  /// ID of the card currently being moved (move mode).
  String? _lbMovingId;

  /// Proposed column while in move mode.
  int? _lbMoveCol;

  /// Proposed row while in move mode.
  int? _lbMoveRow;

  /// Focus nodes keyed by card ID, created lazily and disposed in [dispose].
  final Map<String, FocusNode> _lbFocusNodes = {};

  FocusNode _focusNodeFor(String id) =>
      _lbFocusNodes.putIfAbsent(id, () => FocusNode(debugLabel: 'lb_card_$id'));

  // ── Leanback public API ───────────────────────────────────────────────────

  /// Called by the parent PopScope to cancel an in-progress move via Back.
  void cancelLbMove() {
    if (_lbMovingId == null) return;
    setState(() {
      _lbMovingId = null;
      _lbMoveCol = null;
      _lbMoveRow = null;
    });
    widget.onMoveModeChanged?.call(false);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    for (final node in _lbFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!widget.leanback)
          _EditorToolbar(
            snapEnabled: _snapEnabled,
            previewMode: _previewMode,
            onSnapToggle: () => setState(() => _snapEnabled = !_snapEnabled),
            onPreviewToggle: () => setState(() {
              _previewMode = !_previewMode;
              if (_previewMode) _selectedId = null;
            }),
            onSelectAll: _showSelectAllSheet,
            onReset: widget.onReset,
          ),
        Expanded(child: _buildCanvas()),
      ],
    );
  }

  Widget _buildCanvas() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellW = constraints.maxWidth / widget.layout.columns;
        final cellH = constraints.maxHeight / widget.layout.rows;

        // Dragging card goes last so it renders on top (UX-01).
        final ordered = [
          ...widget.layout.cards.where((c) => c.id != _draggingId),
          ...widget.layout.cards.where((c) => c.id == _draggingId),
        ];

        final overlapping = _draggingId != null && _ghostCol != null && _ghostRow != null
            ? _overlaps(_ghostCol!, _ghostRow!,
                widget.layout.cards.firstWhere((c) => c.id == _draggingId).slot.columnSpan,
                widget.layout.cards.firstWhere((c) => c.id == _draggingId).slot.rowSpan,
                _draggingId!)
            : false;

        return Stack(
          key: const ValueKey('card_stack'),
          children: [
            _GridLines(
              columns: widget.layout.columns,
              rows: widget.layout.rows,
            ),
            if (_draggingId != null && _ghostCol != null && _ghostRow != null)
              _buildGhost(cellW, cellH, overlapping),
            if (_resizingId != null && _ghostColSpan != null && _ghostRowSpan != null)
              _buildResizeGhost(cellW, cellH),
            ...ordered.map((c) => _buildCardTile(c, cellW, cellH)),
            if (_previewMode)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    key: const ValueKey('preview_mode_indicator'),
                    color: Colors.transparent,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Ghost overlays
  // ---------------------------------------------------------------------------

  Widget _buildGhost(double cellW, double cellH, bool overlapping) {
    final dragging = widget.layout.cards.firstWhere((c) => c.id == _draggingId);
    final slot = dragging.slot;
    final borderColor = overlapping ? Colors.amber : LandfallColors.accent;
    final fillColor = overlapping
        ? Colors.amber.withValues(alpha: 0.15)
        : LandfallColors.accentMuted;

    return Positioned(
      key: ValueKey(overlapping ? 'drag_ghost_overlap' : 'drag_ghost_clear'),
      left: _ghostCol! * cellW + _kGap,
      top: _ghostRow! * cellH + _kGap,
      width: slot.columnSpan * cellW - _kGap * 2,
      height: slot.rowSpan * cellH - _kGap * 2,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(6),
          color: fillColor,
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

  // ---------------------------------------------------------------------------
  // Card tiles
  // ---------------------------------------------------------------------------

  Widget _buildCardTile(CardConfig config, double cellW, double cellH) {
    final slot = config.slot;
    final isBeingDragged = _draggingId == config.id;
    final isSelected = _selectedId == config.id;
    final color = _cardColor(config.source);

    // In leanback mode the card may be at its proposed move position.
    final isLbMoving = widget.leanback && _lbMovingId == config.id;
    final displayCol = isLbMoving ? _lbMoveCol! : slot.column;
    final displayRow = isLbMoving ? _lbMoveRow! : slot.row;
    final isLbFocused = widget.leanback && _lbFocusedId == config.id;

    final tile = AnimatedPositioned(
      key: ValueKey('card_tile_${config.id}'),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      left: displayCol * cellW + _kGap,
      top: displayRow * cellH + _kGap,
      width: slot.columnSpan * cellW - _kGap * 2,
      height: slot.rowSpan * cellH - _kGap * 2,
      child: widget.leanback
          ? _buildLbCardContent(config, color, isLbFocused, isLbMoving)
          : GestureDetector(
        onTap: _previewMode ? () => _exitPreview(config) : () => _selectCard(config),
        onPanStart: (_previewMode || config.locked)
            ? null
            : (details) {
                if (_resizingId == config.id) return;
                setState(() {
                  _draggingId = config.id;
                  _ghostCol = slot.column;
                  _ghostRow = slot.row;
                  _dragStartGlobal = details.globalPosition;
                  _dragStartCol = slot.column;
                  _dragStartRow = slot.row;
                  _dragCellW = cellW;
                  _dragCellH = cellH;
                });
              },
        onPanUpdate: (_previewMode || config.locked)
            ? null
            : (details) {
                if (_resizingId == config.id) return;
                if (_dragStartGlobal == null) return;
                final delta = details.globalPosition - _dragStartGlobal!;
                final rawCol = _dragStartCol! + delta.dx / _dragCellW!;
                final rawRow = _dragStartRow! + delta.dy / _dragCellH!;
                setState(() {
                  _ghostCol = (_snapEnabled ? rawCol.floor() : rawCol.round())
                      .clamp(0, widget.layout.columns - slot.columnSpan);
                  _ghostRow = (_snapEnabled ? rawRow.floor() : rawRow.round())
                      .clamp(0, widget.layout.rows - slot.rowSpan);
                });
              },
        onPanEnd: (_previewMode || config.locked)
            ? null
            : (_) {
                if (_resizingId == config.id) {
                  setState(() {
                    _draggingId = null;
                    _ghostCol = null;
                    _ghostRow = null;
                    _dragStartGlobal = null;
                    _dragStartCol = null;
                    _dragStartRow = null;
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
                  _dragStartGlobal = null;
                  _dragStartCol = null;
                  _dragStartRow = null;
                  _dragCellW = null;
                  _dragCellH = null;
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
                        if (!config.visible && !_previewMode) ...[
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
            // Selection highlight (not shown in preview mode)
            if (isSelected && !_previewMode)
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
            // Resize handle — hidden for locked cards and in preview mode
            if (!config.locked && !_previewMode)
              Positioned(
                right: 2,
                bottom: 2,
                child: GestureDetector(
                  key: ValueKey('resize_handle_${config.id}'),
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (details) {
                    setState(() {
                      _draggingId = null;
                      _ghostCol = null;
                      _ghostRow = null;
                      _resizingId = config.id;
                      _ghostColSpan = slot.columnSpan;
                      _ghostRowSpan = slot.rowSpan;
                      _resizeStartGlobal = details.globalPosition;
                      _resizeStartColSpan = slot.columnSpan;
                      _resizeStartRowSpan = slot.rowSpan;
                    });
                  },
                  onPanUpdate: (details) {
                    if (_resizeStartGlobal == null) return;
                    final delta = details.globalPosition - _resizeStartGlobal!;
                    setState(() {
                      _ghostColSpan =
                          (_resizeStartColSpan! + (delta.dx / cellW).round())
                              .clamp(1, widget.layout.columns - slot.column);
                      _ghostRowSpan =
                          (_resizeStartRowSpan! + (delta.dy / cellH).round())
                              .clamp(1, widget.layout.rows - slot.row);
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
                      _resizeStartGlobal = null;
                      _resizeStartColSpan = null;
                      _resizeStartRowSpan = null;
                    });
                  },
                  child: _ResizeHandle(color: color),
                ),
              ),
          ],
        ),
      ),
    );

    return tile;
  }

  // ── Leanback card content ─────────────────────────────────────────────────

  Widget _buildLbCardContent(
    CardConfig config,
    Color color,
    bool isFocused,
    bool isMoving,
  ) {
    final focusNode = _focusNodeFor(config.id);
    final isFirstCard = widget.layout.cards.isNotEmpty &&
        widget.layout.cards.first.id == config.id;

    return Focus(
      focusNode: focusNode,
      autofocus: isFirstCard,
      onFocusChange: (hasFocus) {
        if (hasFocus && mounted) {
          setState(() => _lbFocusedId = config.id);
        }
      },
      onKeyEvent: (node, event) => _handleLbKey(config, event),
      child: Stack(
        children: [
          // Card body
          Positioned.fill(
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
          // D-pad focus ring (browse mode)
          if (isFocused && !isMoving)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  key: ValueKey('lb_focus_ring_${config.id}'),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: LandfallColors.accent.withValues(alpha: 0.6),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          // Move mode highlight
          if (isMoving)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  key: ValueKey('lb_move_mode_${config.id}'),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: LandfallColors.accent,
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(6),
                    color: LandfallColors.accent.withValues(alpha: 0.1),
                  ),
                ),
              ),
            ),
          // Lock badge
          if (config.locked)
            Positioned(
              left: 4,
              bottom: 4,
              child: Icon(
                Icons.lock,
                size: 12,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          // Move hint shown when in move mode
          if (isMoving)
            const Positioned(
              right: 4,
              top: 4,
              child: Icon(
                Icons.open_with,
                size: 14,
                color: LandfallColors.accent,
              ),
            ),
        ],
      ),
    );
  }

  // ── Leanback key handling ─────────────────────────────────────────────────

  KeyEventResult _handleLbKey(CardConfig config, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;

    // ── Move mode ────────────────────────────────────────────────────────────
    if (_lbMovingId == config.id) {
      if (key == LogicalKeyboardKey.arrowRight) {
        _lbShift(config, dc: 1, dr: 0);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowLeft) {
        _lbShift(config, dc: -1, dr: 0);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowDown) {
        _lbShift(config, dc: 0, dr: 1);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowUp) {
        _lbShift(config, dc: 0, dr: -1);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.select || key == LogicalKeyboardKey.enter) {
        _lbConfirm(config);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.escape) {
        cancelLbMove();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    // ── Browse mode ──────────────────────────────────────────────────────────
    if (_lbFocusedId == config.id) {
      if (key == LogicalKeyboardKey.select || key == LogicalKeyboardKey.enter) {
        if (!config.locked) _lbStartMove(config);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowRight) {
        _lbNavigate(config, dx: 1, dy: 0);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowLeft) {
        _lbNavigate(config, dx: -1, dy: 0);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowDown) {
        _lbNavigate(config, dx: 0, dy: 1);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowUp) {
        _lbNavigate(config, dx: 0, dy: -1);
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  void _lbStartMove(CardConfig config) {
    setState(() {
      _lbMovingId = config.id;
      _lbMoveCol = config.slot.column;
      _lbMoveRow = config.slot.row;
    });
    widget.onMoveModeChanged?.call(true);
    widget.onCancelMoveRegistered?.call(cancelLbMove);
  }

  void _lbShift(CardConfig config, {required int dc, required int dr}) {
    final slot = config.slot;
    final newCol = (_lbMoveCol! + dc)
        .clamp(0, widget.layout.columns - slot.columnSpan);
    final newRow = (_lbMoveRow! + dr)
        .clamp(0, widget.layout.rows - slot.rowSpan);
    setState(() {
      _lbMoveCol = newCol;
      _lbMoveRow = newRow;
    });
  }

  void _lbConfirm(CardConfig config) {
    if (_lbMoveCol != config.slot.column || _lbMoveRow != config.slot.row) {
      _commitMove(config, _lbMoveCol!, _lbMoveRow!);
    }
    setState(() {
      _lbMovingId = null;
      _lbMoveCol = null;
      _lbMoveRow = null;
    });
    widget.onMoveModeChanged?.call(false);
  }

  void _lbNavigate(CardConfig from, {required int dx, required int dy}) {
    final fromCX = from.slot.column + from.slot.columnSpan / 2.0;
    final fromCY = from.slot.row + from.slot.rowSpan / 2.0;

    CardConfig? best;
    double bestScore = double.infinity;

    for (final card in widget.layout.cards) {
      if (card.id == from.id) continue;
      final toCX = card.slot.column + card.slot.columnSpan / 2.0;
      final toCY = card.slot.row + card.slot.rowSpan / 2.0;
      final relX = toCX - fromCX;
      final relY = toCY - fromCY;

      // Must be in the requested direction.
      final inDir = (dx > 0 && relX > 0) ||
          (dx < 0 && relX < 0) ||
          (dy > 0 && relY > 0) ||
          (dy < 0 && relY < 0);
      if (!inDir) continue;

      final score = relX * relX + relY * relY;
      if (score < bestScore) {
        bestScore = score;
        best = card;
      }
    }

    if (best != null) {
      _focusNodeFor(best.id).requestFocus();
    }
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  void _selectCard(CardConfig config) {
    setState(() => _selectedId = config.id);
    _showCardHud(config);
  }

  void _exitPreview(CardConfig config) {
    setState(() {
      _previewMode = false;
      _selectedId = config.id;
    });
    _showCardHud(config);
  }

  void _showSelectAllSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => _SelectAllSheet(
        layout: widget.layout,
        onLayoutChanged: widget.onLayoutChanged,
        onDismiss: () => Navigator.pop(context),
      ),
    );
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

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Returns true if [col, row, colSpan × rowSpan] overlaps any visible card
  /// other than [excludeId].
  bool _overlaps(int col, int row, int colSpan, int rowSpan, String excludeId) {
    for (final card in widget.layout.cards) {
      if (card.id == excludeId || !card.visible) continue;
      final s = card.slot;
      final colOverlap = col < s.column + s.columnSpan && col + colSpan > s.column;
      final rowOverlap = row < s.row + s.rowSpan && row + rowSpan > s.row;
      if (colOverlap && rowOverlap) return true;
    }
    return false;
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
// Toolbar
// ---------------------------------------------------------------------------

class _EditorToolbar extends StatelessWidget {
  const _EditorToolbar({
    required this.snapEnabled,
    required this.previewMode,
    required this.onSnapToggle,
    required this.onPreviewToggle,
    required this.onSelectAll,
    this.onReset,
  });

  final bool snapEnabled;
  final bool previewMode;
  final VoidCallback onSnapToggle;
  final VoidCallback onPreviewToggle;
  final VoidCallback onSelectAll;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('editor_toolbar'),
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: LandfallColors.divider.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: Row(
        children: [
          _ToolbarButton(
            key: const ValueKey('toolbar_snap_toggle'),
            icon: snapEnabled ? Icons.grid_on : Icons.grid_off,
            label: snapEnabled ? 'Snap on' : 'Snap off',
            active: snapEnabled,
            onTap: onSnapToggle,
          ),
          const SizedBox(width: 4),
          _ToolbarButton(
            key: const ValueKey('toolbar_select_all'),
            icon: Icons.select_all,
            label: 'Select all',
            onTap: onSelectAll,
          ),
          const SizedBox(width: 4),
          _ToolbarButton(
            key: const ValueKey('toolbar_preview_toggle'),
            icon: previewMode ? Icons.visibility : Icons.visibility_outlined,
            label: previewMode ? 'Exit preview' : 'Preview',
            active: previewMode,
            onTap: onPreviewToggle,
          ),
          if (onReset != null) ...[
            const SizedBox(width: 4),
            _ToolbarButton(
              key: const ValueKey('toolbar_reset'),
              icon: Icons.refresh,
              label: 'Reset',
              onTap: onReset!,
            ),
          ],
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? LandfallColors.accent
        : LandfallColors.textSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: color),
            ),
          ],
        ),
      ),
    );
  }
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
    final cards =
        layout.cards.map((c) => c.id == config.id ? updated : c).toList();
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
        content:
            Text('Remove "${_cardLabel(config.source)}" from this layout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const ValueKey('hud_delete_confirm'),
            onPressed: () {
              Navigator.pop(ctx);
              final cards =
                  layout.cards.where((c) => c.id != config.id).toList();
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
    return SingleChildScrollView(
      child: Container(
        key: const ValueKey('card_hud'),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Row(
            children: [
              Expanded(
                child: _HudToggle(
                  key: const ValueKey('hud_visibility_toggle'),
                  icon: config.visible
                      ? Icons.visibility
                      : Icons.visibility_off,
                  label: config.visible ? 'Visible' : 'Hidden',
                  onTap: () => _updateCard(
                      context, config.copyWith(visible: !config.visible)),
                ),
              ),
              Expanded(
                child: _HudToggle(
                  key: const ValueKey('hud_lock_toggle'),
                  icon: config.locked ? Icons.lock : Icons.lock_open,
                  label: config.locked ? 'Locked' : 'Unlocked',
                  onTap: () => _updateCard(
                      context, config.copyWith(locked: !config.locked)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
          ..._displayConfigSection(context),
        ],
      ),
    ),
    );
  }

  List<Widget> _displayConfigSection(BuildContext context) {
    void update(Map<String, dynamic> patch) {
      final merged = {...config.displayConfig, ...patch};
      _updateCard(context, config.copyWith(displayConfig: merged));
    }

    return switch (config.source) {
      'system.clock' => [
          const Divider(),
          _HudSectionLabel(label: 'Clock display'),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Format:'),
              const SizedBox(width: 12),
              _HudChip(
                key: const ValueKey('hud_clock_hour_format_24'),
                label: '24h',
                selected: config.displayConfig['hourFormat'] != '12',
                onTap: () => update({'hourFormat': '24'}),
              ),
              const SizedBox(width: 8),
              _HudChip(
                key: const ValueKey('hud_clock_hour_format_12'),
                label: '12h',
                selected: config.displayConfig['hourFormat'] == '12',
                onTap: () => update({'hourFormat': '12'}),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _HudSwitch(
            switchKey: const ValueKey('hud_clock_show_seconds'),
            label: 'Show seconds',
            value: config.displayConfig['showSeconds'] != false,
            onChanged: (v) => update({'showSeconds': v}),
          ),
          _HudSwitch(
            switchKey: const ValueKey('hud_clock_show_date'),
            label: 'Show date',
            value: config.displayConfig['showDate'] != false,
            onChanged: (v) => update({'showDate': v}),
          ),
        ],
      'system.weather' => [
          const Divider(),
          _HudSectionLabel(label: 'Weather display'),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Unit:'),
              const SizedBox(width: 12),
              _HudChip(
                key: const ValueKey('hud_weather_unit_f'),
                label: '°F',
                selected: config.displayConfig['unit'] != 'c',
                onTap: () => update({'unit': 'f'}),
              ),
              const SizedBox(width: 8),
              _HudChip(
                key: const ValueKey('hud_weather_unit_c'),
                label: '°C',
                selected: config.displayConfig['unit'] == 'c',
                onTap: () => update({'unit': 'c'}),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _HudSwitch(
            switchKey: const ValueKey('hud_weather_compact'),
            label: 'Compact (hide details)',
            value: config.displayConfig['compact'] == true,
            onChanged: (v) => update({'compact': v}),
          ),
        ],
      'system.weather.forecast' => [
          const Divider(),
          _HudSectionLabel(label: 'Forecast days'),
          const SizedBox(height: 8),
          Row(
            children: [
              _HudChip(
                key: const ValueKey('hud_forecast_days_1'),
                label: '1 day',
                selected: config.displayConfig['days'] == 1,
                onTap: () => update({'days': 1}),
              ),
              const SizedBox(width: 8),
              _HudChip(
                key: const ValueKey('hud_forecast_days_3'),
                label: '3 days',
                selected: config.displayConfig['days'] == 3,
                onTap: () => update({'days': 3}),
              ),
              const SizedBox(width: 8),
              _HudChip(
                key: const ValueKey('hud_forecast_days_5'),
                label: '5 days',
                selected: config.displayConfig['days'] != 1 &&
                    config.displayConfig['days'] != 3,
                onTap: () => update({'days': 5}),
              ),
            ],
          ),
        ],
      'system.calendar' => [
          const Divider(),
          _HudSectionLabel(label: 'Calendar view'),
          const SizedBox(height: 8),
          Row(
            children: [
              _HudChip(
                key: const ValueKey('hud_calendar_view_biweekly'),
                label: '2 Weeks',
                selected: config.displayConfig['view'] != 'daily' &&
                    config.displayConfig['view'] != 'weekly' &&
                    config.displayConfig['view'] != 'monthly',
                onTap: () => update({'view': 'biweekly'}),
              ),
              const SizedBox(width: 8),
              _HudChip(
                key: const ValueKey('hud_calendar_view_daily'),
                label: 'Daily',
                selected: config.displayConfig['view'] == 'daily',
                onTap: () => update({'view': 'daily'}),
              ),
              const SizedBox(width: 8),
              _HudChip(
                key: const ValueKey('hud_calendar_view_weekly'),
                label: 'Weekly',
                selected: config.displayConfig['view'] == 'weekly',
                onTap: () => update({'view': 'weekly'}),
              ),
              const SizedBox(width: 8),
              _HudChip(
                key: const ValueKey('hud_calendar_view_monthly'),
                label: 'Monthly',
                selected: config.displayConfig['view'] == 'monthly',
                onTap: () => update({'view': 'monthly'}),
              ),
            ],
          ),
        ],
      _ => const [],
    };
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

// ---------------------------------------------------------------------------
// HUD display config helpers
// ---------------------------------------------------------------------------

class _HudSectionLabel extends StatelessWidget {
  const _HudSectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      );
}

class _HudChip extends StatelessWidget {
  const _HudChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        visualDensity: VisualDensity.compact,
      );
}

class _HudSwitch extends StatelessWidget {
  const _HudSwitch({
    this.switchKey,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final Key? switchKey;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(child: Text(label)),
          Switch(key: switchKey, value: value, onChanged: onChanged),
        ],
      );
}

// ---------------------------------------------------------------------------
// Select-all sheet
// ---------------------------------------------------------------------------

class _SelectAllSheet extends StatelessWidget {
  const _SelectAllSheet({
    required this.layout,
    required this.onLayoutChanged,
    required this.onDismiss,
  });

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

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('select_all_sheet'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'All cards',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onDismiss,
              ),
            ],
          ),
          const Divider(),
          Row(
            children: [
              Expanded(
                child: _HudAction(
                  key: const ValueKey('select_all_lock_all'),
                  icon: Icons.lock,
                  label: 'Lock all',
                  onTap: () {
                    onLayoutChanged(_rebuild(
                      layout.cards.map((c) => c.copyWith(locked: true)).toList(),
                    ));
                    onDismiss();
                  },
                ),
              ),
              Expanded(
                child: _HudAction(
                  key: const ValueKey('select_all_unlock_all'),
                  icon: Icons.lock_open,
                  label: 'Unlock all',
                  onTap: () {
                    onLayoutChanged(_rebuild(
                      layout.cards.map((c) => c.copyWith(locked: false)).toList(),
                    ));
                    onDismiss();
                  },
                ),
              ),
              Expanded(
                child: _HudAction(
                  key: const ValueKey('select_all_hide_all'),
                  icon: Icons.visibility_off,
                  label: 'Hide all',
                  onTap: () {
                    onLayoutChanged(_rebuild(
                      layout.cards.map((c) => c.copyWith(visible: false)).toList(),
                    ));
                    onDismiss();
                  },
                ),
              ),
              Expanded(
                child: _HudAction(
                  key: const ValueKey('select_all_show_all'),
                  icon: Icons.visibility,
                  label: 'Show all',
                  onTap: () {
                    onLayoutChanged(_rebuild(
                      layout.cards.map((c) => c.copyWith(visible: true)).toList(),
                    ));
                    onDismiss();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
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
    final color =
        destructive ? Theme.of(context).colorScheme.error : null;
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
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: color),
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
