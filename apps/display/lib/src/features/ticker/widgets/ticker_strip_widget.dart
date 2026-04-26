import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui_kit/ui_kit.dart';

import 'package:display/src/features/ticker/cubit/ticker_cubit.dart';

/// Fixed bottom overlay that scrolls the current ghost ticker message.
///
/// Renders nothing (zero height) when the ticker buffer is empty so it
/// never occupies space on the display grid.
///
/// The widget cycles through active ticker messages one at a time, showing
/// each for [_displayDuration] before crossfading to the next.
class TickerStripWidget extends StatefulWidget {
  const TickerStripWidget({super.key});

  @override
  State<TickerStripWidget> createState() => _TickerStripWidgetState();
}

class _TickerStripWidgetState extends State<TickerStripWidget>
    with SingleTickerProviderStateMixin {
  static const _displayDuration = Duration(seconds: 8);
  static const _fadeDuration = Duration(milliseconds: 400);

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  int _index = 0;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: _fadeDuration);
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);
    _fadeCtrl.value = 1.0;
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _cycleToIndex(int newIndex) async {
    await _fadeCtrl.reverse();
    if (!mounted) return;
    setState(() => _index = newIndex);
    await _fadeCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TickerCubit, TickerState>(
      builder: (context, state) {
        if (state is! TickerLoaded || state.messages.isEmpty) {
          return const SizedBox.shrink();
        }

        final messages = state.messages;
        final safeIndex = _index.clamp(0, messages.length - 1);
        final msg = messages[safeIndex];

        return _TickerBar(
          source: msg.source,
          message: msg.title,
          fadeAnim: _fadeAnim,
          onCycleRequested: () {
            final next = (safeIndex + 1) % messages.length;
            _cycleToIndex(next);
          },
          displayDuration: _displayDuration,
        );
      },
    );
  }
}

class _TickerBar extends StatefulWidget {
  const _TickerBar({
    required this.source,
    required this.message,
    required this.fadeAnim,
    required this.onCycleRequested,
    required this.displayDuration,
  });

  final String source;
  final String message;
  final Animation<double> fadeAnim;
  final VoidCallback onCycleRequested;
  final Duration displayDuration;

  @override
  State<_TickerBar> createState() => _TickerBarState();
}

class _TickerBarState extends State<_TickerBar> {
  @override
  void initState() {
    super.initState();
    _scheduleCycle();
  }

  @override
  void didUpdateWidget(_TickerBar old) {
    super.didUpdateWidget(old);
    if (old.message != widget.message) {
      _scheduleCycle();
    }
  }

  void _scheduleCycle() {
    Future.delayed(widget.displayDuration, () {
      if (mounted) widget.onCycleRequested();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: widget.fadeAnim,
      child: Container(
        height: 28,
        decoration: const BoxDecoration(
          color: Color(0xFF0D0D0F),
          border: Border(
            top: BorderSide(color: LandfallColors.divider, width: 0.5),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Text(
              widget.source,
              style: const TextStyle(
                color: LandfallColors.accent,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 12),
            const SizedBox(
              height: 12,
              child: VerticalDivider(
                color: LandfallColors.divider,
                width: 1,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.message,
                style: const TextStyle(
                  color: LandfallColors.textSecondary,
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
