import 'package:flutter/material.dart';

/// Filled action button used across the auth flow.
///
/// Renders a spinner when [isLoading] is true and disables the press handler.
class LandfallButton extends StatelessWidget {
  const LandfallButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4A9EFF),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF2A2A2A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          // Weight via styleFrom merges into the theme's labelLarge with
          // inherit:false. Passing it on the child `Text` instead forces
          // inherit:true and crashes AnimatedDefaultTextStyle.lerp whenever
          // the surrounding theme rebuilds (resize, theme swap, MediaQuery).
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white54,
                ),
              )
            : Text(label),
      ),
    );
  }
}
