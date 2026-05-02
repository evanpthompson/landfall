import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:landfall_shared/landfall_shared.dart' hide Card;
import 'package:ui_kit/ui_kit.dart';

import 'package:display/src/features/theme/cubit/theme_cubit.dart';
import 'package:display/src/features/theme/cubit/theme_state.dart';
import 'package:display/src/features/theme/widgets/theme_card.dart';

/// Full-screen browser for choosing and applying themes.
///
/// Displays all available themes (built-in + imported) in a scrollable grid.
/// The active theme is indicated with a checkmark; inactive themes show an
/// Apply button that links the theme to the active profile.
class ThemeBrowserScreen extends StatelessWidget {
  const ThemeBrowserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LandfallColors.background,
      appBar: AppBar(
        backgroundColor: LandfallColors.surface,
        foregroundColor: LandfallColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Themes', style: TextStyle(fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, state) => switch (state) {
          ThemeInitial() || ThemeLoading() =>
            const Center(child: CircularProgressIndicator()),
          ThemeError(:final message) => Center(
              child: Text(
                message,
                style: const TextStyle(color: LandfallColors.textSecondary),
              ),
            ),
          ThemeLoaded(:final active, :final themes) => _ThemeGrid(
              themes: themes,
              activeId: active.id,
            ),
        },
      ),
    );
  }
}

class _ThemeGrid extends StatelessWidget {
  const _ThemeGrid({required this.themes, required this.activeId});

  final List<ThemeInfo> themes;
  final int activeId;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: themes.length,
      itemBuilder: (context, i) {
        final theme = themes[i];
        final isActive = theme.id == activeId;
        return ThemeCard(
          theme: theme,
          isActive: isActive,
          onApply: () =>
              context.read<ThemeCubit>().applyTheme(theme.id),
        );
      },
    );
  }
}
