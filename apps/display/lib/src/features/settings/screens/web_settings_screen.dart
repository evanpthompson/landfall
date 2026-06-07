import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';

import 'package:display/src/features/profile/cubit/dashboard_profile_cubit.dart';
import 'package:display/src/features/settings/widgets/layout_tab_view.dart';

/// Web settings shell served via the companion app at /c/{displayId}.
///
/// Rendered behind AuthGate — anonymous companion features at the same URL
/// are outside this widget and remain unauthenticated.
///
/// [onPush] is called with a domain.changed kind string after any
/// successful settings save so the TV can react without restart.
class WebSettingsScreen extends StatefulWidget {
  const WebSettingsScreen({super.key, required this.onPush});

  final Future<void> Function(String kind) onPush;

  @override
  State<WebSettingsScreen> createState() => WebSettingsScreenState();
}

class WebSettingsScreenState extends State<WebSettingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  /// Saves the layout via the cubit and, on success, fires the push notification.
  /// Called by [LayoutTabView] via [onAfterSave]. If the save fails the push
  /// is skipped; the error is not surfaced to the user (the cubit handles its
  /// own error state).
  Future<void> onLayoutSaved(DashboardLayout layout) async {
    try {
      await context.read<DashboardProfileCubit>().saveActiveLayout(layout);
    } catch (_) {
      return;
    }
    await widget.onPush('layout.changed');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LandfallColors.background,
      appBar: AppBar(
        backgroundColor: LandfallColors.surface,
        foregroundColor: LandfallColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
        ),
        bottom: TabBar(
          controller: _tabs,
          labelColor: LandfallColors.accent,
          unselectedLabelColor: LandfallColors.textSecondary,
          indicatorColor: LandfallColors.accent,
          indicatorWeight: 2,
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
          tabs: const [
            Tab(text: 'Layout'),
            Tab(text: 'Themes'),
            Tab(text: 'Accounts'),
            Tab(text: 'Display'),
            Tab(text: 'License'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          LayoutTabView(
            leanback: false,
            onAfterSave: onLayoutSaved,
          ),
          const _PlaceholderTab('Themes'),
          const _PlaceholderTab('Accounts'),
          const _PlaceholderTab('Display'),
          const _PlaceholderTab('License'),
        ],
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab(this.name);

  final String name;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$name coming soon',
        style: const TextStyle(color: LandfallColors.textSecondary),
      ),
    );
  }
}
