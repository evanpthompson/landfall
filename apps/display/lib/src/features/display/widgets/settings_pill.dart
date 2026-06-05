import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:display/src/features/display/remote_nav_keys.dart';

/// A translucent pill that appears on tap/focus and opens the settings screen.
///
/// Designed to stay out of the way on an ambient display: low-opacity, dark
/// background, tight padding. Fade in/out is managed by the parent.
///
/// Activation accepts the Fire TV **OK** button ([LogicalKeyboardKey.select])
/// via [isDisplaySelectKey] — the same predicate the dashboard uses to surface
/// the pill — plus `space` for desktop. Without `select` the focused pill
/// ignored the remote's OK press and Settings was unreachable by remote.
class SettingsPill extends StatelessWidget {
  const SettingsPill({
    super.key,
    required this.onTap,
    required this.focusNode,
    required this.onFocusGained,
  });

  final VoidCallback onTap;
  final FocusNode focusNode;
  final VoidCallback onFocusGained;

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: focusNode,
      onFocusChange: (gained) {
        if (gained) onFocusGained();
      },
      onKeyEvent: (_, event) {
        if (isDisplaySelectKey(event) ||
            (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.space)) {
          onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D0F).withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.13),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.settings,
                size: 14,
                color: Colors.white.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 7),
              Text(
                'Settings',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
