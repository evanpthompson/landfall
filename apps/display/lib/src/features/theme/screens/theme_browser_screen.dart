import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:landfall_shared/landfall_shared.dart' hide Card;
import 'package:ui_kit/ui_kit.dart';

import 'package:display/src/features/theme/cubit/marketplace_cubit.dart';
import 'package:display/src/features/theme/cubit/marketplace_state.dart';
import 'package:display/src/features/theme/cubit/theme_cubit.dart';
import 'package:display/src/features/theme/cubit/theme_state.dart';
import 'package:display/src/features/theme/widgets/marketplace_theme_card.dart';
import 'package:display/src/features/theme/widgets/theme_card.dart';

import 'theme_detail_sheet.dart';

/// Full-screen browser for choosing and applying themes.
///
/// Has two tabs:
/// - **Installed** — built-in themes and any imported themes
/// - **Marketplace** — purchasable themes from the Landfall marketplace
class ThemeBrowserScreen extends StatelessWidget {
  const ThemeBrowserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
          bottom: const TabBar(
            labelColor: LandfallColors.accent,
            unselectedLabelColor: LandfallColors.textSecondary,
            indicatorColor: LandfallColors.accent,
            tabs: [
              Tab(text: 'Installed'),
              Tab(text: 'Marketplace'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _InstalledTab(),
            _MarketplaceTab(),
          ],
        ),
      ),
    );
  }
}

// ── Installed tab ──────────────────────────────────────────────────────────────

class _InstalledTab extends StatelessWidget {
  const _InstalledTab();

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
          onApply: () => context.read<ThemeCubit>().applyTheme(theme.id),
        );
      },
    );
  }
}

// ── Marketplace tab ────────────────────────────────────────────────────────────

class _MarketplaceTab extends StatelessWidget {
  const _MarketplaceTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MarketplaceCubit, MarketplaceState>(
      builder: (context, state) => switch (state) {
        MarketplaceInitial() || MarketplaceLoading() =>
          const Center(child: CircularProgressIndicator()),
        MarketplaceError(:final message) => Center(
            child: Text(
              message,
              style: const TextStyle(color: LandfallColors.textSecondary),
            ),
          ),
        MarketplaceLoaded(:final themes) when themes.isEmpty => const Center(
            child: Text(
              'No marketplace themes available yet.',
              style: TextStyle(color: LandfallColors.textSecondary),
            ),
          ),
        MarketplaceLoaded(:final themes) => _MarketplaceGrid(themes: themes),
      },
    );
  }
}

class _MarketplaceGrid extends StatelessWidget {
  const _MarketplaceGrid({required this.themes});

  final List<MarketplaceThemeInfo> themes;

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
        final entry = themes[i];
        return MarketplaceThemeCard(
          entry: entry,
          onTap: () => _showDetail(context, entry),
        );
      },
    );
  }

  void _showDetail(BuildContext context, MarketplaceThemeInfo entry) {
    ThemeDetailSheet.show(
      context,
      entry: entry,
      onApply: () => context.read<ThemeCubit>().applyTheme(entry.theme.id),
      onPurchase: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchase via Settings › License'),
            duration: Duration(seconds: 3),
          ),
        );
      },
    );
  }
}
