import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:landfall_shared/landfall_shared.dart';

import 'package:display/src/features/layout/cubit/dashboard_layout_cubit.dart';
import 'package:display/src/features/layout/cubit/dashboard_layout_state.dart';

/// The primary display surface — renders all active cards on a grid.
///
/// Drives from [DashboardLayoutCubit]. Each [CardConfig] in the layout maps
/// to a placeholder tile at the correct grid position. In Phase 1 these tiles
/// will be replaced by real card widgets; for Phase 0 they show the source
/// label and color-code by card type.
class DisplayScreen extends StatefulWidget {
  const DisplayScreen({super.key});

  @override
  State<DisplayScreen> createState() => _DisplayScreenState();
}

class _DisplayScreenState extends State<DisplayScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardLayoutCubit>().loadLayout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: BlocBuilder<DashboardLayoutCubit, DashboardLayoutState>(
        builder: (context, state) {
          return switch (state) {
            DashboardLayoutLoading() => const _LoadingView(),
            DashboardLayoutLoaded(:final layout) => _GridView(layout: layout),
            DashboardLayoutError(:final message) => _ErrorView(message: message),
          };
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading
// ---------------------------------------------------------------------------

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFF4A9EFF)),
    );
  }
}

// ---------------------------------------------------------------------------
// Error
// ---------------------------------------------------------------------------

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Layout error: $message',
        style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 16),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Grid
// ---------------------------------------------------------------------------

/// Renders visible [CardConfig] items from [layout] as colored placeholder
/// tiles positioned on the display grid.
///
/// Grid math: the full 1920×1080 display area is divided into [layout.columns]
/// × [layout.rows] equal cells. Each [DashboardSlot] declares its origin and
/// span in grid coordinates; this widget converts those to pixel positions
/// using a [LayoutBuilder] measurement.
class _GridView extends StatelessWidget {
  const _GridView({required this.layout});

  final DashboardLayout layout;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellW = constraints.maxWidth / layout.columns;
        final cellH = constraints.maxHeight / layout.rows;

        return Stack(
          children: layout.visibleCards.map((config) {
            final slot = config.slot;
            return Positioned(
              left: slot.column * cellW + _kGap,
              top: slot.row * cellH + _kGap,
              width: slot.columnSpan * cellW - _kGap * 2,
              height: slot.rowSpan * cellH - _kGap * 2,
              child: _PlaceholderTile(config: config),
            );
          }).toList(),
        );
      },
    );
  }

  /// Gap in logical pixels between tiles.
  static const double _kGap = 8.0;
}

// ---------------------------------------------------------------------------
// Placeholder tile
// ---------------------------------------------------------------------------

/// A colored tile that represents a [CardConfig] on the grid.
///
/// Color-coded by source prefix so the layout is visually readable at a
/// glance during development. Real card widgets replace these in Phase 1.
class _PlaceholderTile extends StatelessWidget {
  const _PlaceholderTile({required this.config});

  final CardConfig config;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _tileColor(config.source).withValues(alpha: 0.15),
        border: Border.all(
          color: _tileColor(config.source).withValues(alpha: 0.6),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              config.source,
              style: TextStyle(
                color: _tileColor(config.source),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              config.id,
              style: const TextStyle(
                color: Color(0xFF666666),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Color _tileColor(String source) {
    if (source.startsWith('system.clock')) return const Color(0xFF4A9EFF);
    if (source.startsWith('system.weather')) return const Color(0xFF50C878);
    if (source.startsWith('system.calendar')) return const Color(0xFFFF9500);
    if (source.startsWith('system.photos')) return const Color(0xFFBF5AF2);
    if (source.startsWith('agent.')) return const Color(0xFFFF6B6B);
    return const Color(0xFF888888);
  }
}
