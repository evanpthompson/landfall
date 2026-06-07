import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: LandfallColors.textTertiary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}
