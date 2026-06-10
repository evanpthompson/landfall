import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:landfall_shared/landfall_shared.dart' hide Card;
import 'package:ui_kit/ui_kit.dart';

import 'package:display/src/features/theme/cubit/theme_cubit.dart';
import 'package:display/src/features/theme/cubit/theme_state.dart';
import 'package:display/src/features/theme/widgets/theme_card.dart';

/// Responsive grid for theme cards. `mainAxisExtent` pins each card's height so
/// the Apply button is never clipped on narrow (≤390px) companion viewports —
/// the previous `childAspectRatio` made cards too short there. `maxCrossAxisExtent`
/// yields two columns on a phone and more on wider displays.
const _themeGridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
  maxCrossAxisExtent: 240,
  crossAxisSpacing: 12,
  mainAxisSpacing: 12,
  mainAxisExtent: 210,
);

/// Full-screen browser for choosing and applying themes.
///
/// A single list of available themes (built-in + imported). There is no
/// separate marketplace/commerce surface — every theme is free to apply.
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
      body: const _ThemeList(),
    );
  }
}

class _ThemeList extends StatelessWidget {
  const _ThemeList();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
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
      gridDelegate: _themeGridDelegate,
      itemCount: themes.length,
      itemBuilder: (context, i) {
        final theme = themes[i];
        final isActive = theme.id == activeId;
        return ThemeCard(
          theme: theme,
          isActive: isActive,
          onApply: () => context.read<ThemeCubit>().applyTheme(theme.id),
        );
      },
    );
  }
}
