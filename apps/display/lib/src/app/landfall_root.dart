import 'package:flutter/material.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:uuid/uuid.dart';

import 'package:display/src/app/app_config.dart';
import 'package:display/src/app/startup_decision.dart';

/// Root of the running app and the single source of truth for which server URL
/// the tree is bound to.
///
/// It reads [DisplaySettings] (the source of truth for the server URL), resolves
/// the [StartupDecision], and builds either the display app or the setup wizard.
/// [relaunch] re-reads settings and rebuilds the subtree from scratch — the
/// clean way to pick up a changed server URL without restarting the process.
/// Any descendant can trigger it via [AppRelauncher].
class LandfallRoot extends StatefulWidget {
  const LandfallRoot({
    super.key,
    required this.settingsRepository,
    required this.buildDisplay,
    required this.buildWizard,
  });

  final DisplaySettingsRepository settingsRepository;

  /// Builds the main display app for a resolved `(serverUrl, displayId)`.
  final Widget Function(String serverUrl, String displayId) buildDisplay;

  /// Builds the setup wizard. [onComplete] is wired to [relaunch] so finishing
  /// the wizard rebinds the app to the freshly saved URL.
  final Widget Function(VoidCallback onComplete) buildWizard;

  @override
  State<LandfallRoot> createState() => _LandfallRootState();
}

class _LandfallRootState extends State<LandfallRoot> {
  late Future<_RootRoute> _route;

  /// True once the setup wizard has completed in this process. It suppresses
  /// the [kIntegrationTestWizardMode] short-circuit so finishing the wizard
  /// advances to the display instead of re-showing the wizard on relaunch.
  bool _wizardCompleted = false;

  @override
  void initState() {
    super.initState();
    _route = _resolve();
  }

  /// Re-reads settings and rebuilds the tree against the current server URL.
  void relaunch() {
    setState(() {
      _route = _resolve();
    });
  }

  void _completeWizard() {
    _wizardCompleted = true;
    relaunch();
  }

  Future<_RootRoute> _resolve() async {
    var settings = await widget.settingsRepository.getSettings();

    final decision = resolveStartupDecision(
      settings: settings,
      integrationTestServerUrl: kIntegrationTestServerUrl,
      integrationTestWizardMode:
          kIntegrationTestWizardMode && !_wizardCompleted,
      defaultServerUrl: kLandfallDefaultServerUrl,
    );

    if (decision.target == StartupTarget.setupWizard) {
      return const _RootRoute.wizard();
    }

    // Generate a stable display UUID on first launch and persist it.
    if (settings.displayId.isEmpty) {
      settings = settings.copyWith(displayId: const Uuid().v4());
      await widget.settingsRepository.saveSettings(settings);
    }
    if (decision.persistDefaultSettings) {
      settings = settings.copyWith(
        serverUrl: decision.serverUrl,
        wizardComplete: true,
      );
      await widget.settingsRepository.saveSettings(settings);
    }

    return _RootRoute.display(decision.serverUrl, settings.displayId);
  }

  @override
  Widget build(BuildContext context) {
    return AppRelauncher(
      relaunch: relaunch,
      child: FutureBuilder<_RootRoute>(
        future: _route,
        builder: (context, snapshot) {
          final route = snapshot.data;
          if (route == null) {
            return const ColoredBox(color: Color(0xFF0A0A0A));
          }
          if (route.target == StartupTarget.setupWizard) {
            return widget.buildWizard(_completeWizard);
          }
          return widget.buildDisplay(route.serverUrl, route.displayId);
        },
      ),
    );
  }
}

class _RootRoute {
  const _RootRoute.wizard()
      : target = StartupTarget.setupWizard,
        serverUrl = '',
        displayId = '';

  const _RootRoute.display(this.serverUrl, this.displayId)
      : target = StartupTarget.display;

  final StartupTarget target;
  final String serverUrl;
  final String displayId;
}

/// Exposes [LandfallRoot.relaunch] to descendants so any screen (e.g. the
/// "change server address" flow) can rebind the app after saving a new URL.
class AppRelauncher extends InheritedWidget {
  const AppRelauncher({
    super.key,
    required this.relaunch,
    required super.child,
  });

  final VoidCallback relaunch;

  static AppRelauncher of(BuildContext context) {
    final relauncher =
        context.dependOnInheritedWidgetOfExactType<AppRelauncher>();
    assert(relauncher != null, 'No AppRelauncher found in context');
    return relauncher!;
  }

  @override
  bool updateShouldNotify(AppRelauncher oldWidget) =>
      relaunch != oldWidget.relaunch;
}
