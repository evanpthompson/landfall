import 'package:flutter/material.dart';

import 'package:ui_kit/src/theme/landfall_colors.dart';

/// Wraps [child] with a focus ring and a subtle scale animation whenever any
/// descendant gains keyboard focus.
///
/// Designed for Fire TV / 10-foot UX. Safe on all platforms — the ring is
/// invisible until the widget's subtree receives focus.
///
/// Usage:
/// ```dart
/// LandfallFocusable(
///   child: FilledButton(onPressed: () {}, child: const Text('OK')),
/// )
/// ```
class LandfallFocusable extends StatefulWidget {
  const LandfallFocusable({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  final Widget child;

  /// Corner radius of the focus ring. Defaults to 8, matching Landfall cards.
  final BorderRadius borderRadius;

  @override
  State<LandfallFocusable> createState() => _LandfallFocusableState();
}

class _LandfallFocusableState extends State<LandfallFocusable> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      // Invisible to traversal — focus stops at the child, not this wrapper.
      skipTraversal: true,
      canRequestFocus: false,
      onFocusChange: (focused) {
        if (mounted) setState(() => _focused = focused);
      },
      child: AnimatedScale(
        scale: _focused ? 1.04 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(
            border: _focused
                ? Border.all(color: LandfallColors.accent, width: 3)
                : null,
            borderRadius: widget.borderRadius,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
