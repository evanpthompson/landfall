import 'package:display/src/app/poll_timeouts.dart';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:landfall_client/landfall_client.dart' as lf;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart';

import 'src/data/auth/web_local_key_value_storage.dart';
import 'src/features/companion/companion_url.dart';
import 'src/data/license/serverpod_license_repository.dart';
import 'src/data/profile/serverpod_profile_repository.dart';
import 'src/data/theme/serverpod_theme_repository.dart';
import 'src/features/auth/cubit/auth_cubit.dart';
import 'src/features/auth/widgets/auth_gate.dart';
import 'src/features/companion/widgets/companion_mobile_screen.dart';
import 'src/features/license/cubit/license_cubit.dart';
import 'src/features/profile/cubit/dashboard_profile_cubit.dart';
import 'src/features/settings/screens/web_settings_screen.dart';
import 'src/features/theme/cubit/theme_cubit.dart';

// Reads the display ID injected by CompanionPageRoute into the page HTML.
// The server injects: window.LANDFALL_DISPLAY_ID = "{uuid}";
@JS('LANDFALL_DISPLAY_ID')
external JSString? get _rawDisplayId;

void main() {
  // Architecture pin: fonts are bundled at build time, never fetched from
  // fonts.gstatic.com at runtime. The Caddyfile CSP also blocks that origin.
  GoogleFonts.config.allowRuntimeFetching = false;

  final displayId = _rawDisplayId?.toDart ?? '';

  // When served through Caddy (standard port 80/443) the API is on the same
  // origin — Caddy routes /companion/* to the API server. When accessed
  // directly from the Serverpod web port (8082) the API is port - 2 (8080).
  final uri = Uri.base;
  final isDefaultPort = uri.port == 80 || uri.port == 443;
  final serverUrl = isDefaultPort
      ? '${uri.scheme}://${uri.host}/'
      : '${uri.scheme}://${uri.host}:${uri.port - 2}/';

  // OAuth connect routes are served by the Serverpod web server — which is
  // the very origin serving this companion page. Derive it from the page URL
  // directly rather than from the API [serverUrl] (which points at :8080).
  final webServerUrl = companionWebOriginFromPage(uri);

  // JWT stored in localStorage so sign-in persists across page reloads.
  final sessionManager = ClientAuthSessionManager(
    storage: KeyValueClientAuthSuccessStorage(
      keyValueStorage: const WebLocalKeyValueStorage(),
    ),
  );
  final client = lf.Client(
    serverUrl,
    connectionTimeout: kClientConnectionTimeout,
  )..authSessionManager = sessionManager;

  runApp(_CompanionWebApp(
    displayId: displayId,
    serverUrl: serverUrl,
    webServerUrl: webServerUrl,
    client: client,
    sessionManager: sessionManager,
  ));
}

class _CompanionWebApp extends StatefulWidget {
  const _CompanionWebApp({
    required this.displayId,
    required this.serverUrl,
    required this.webServerUrl,
    required this.client,
    required this.sessionManager,
  });

  final String displayId;
  final String serverUrl;
  final String webServerUrl;
  final lf.Client client;
  final ClientAuthSessionManager sessionManager;

  @override
  State<_CompanionWebApp> createState() => _CompanionWebAppState();
}

class _CompanionWebAppState extends State<_CompanionWebApp> {
  CompanionInfo? _info;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    try {
      final entity = await widget.client.companion
          .getOrCreateForDisplay(widget.displayId);
      if (mounted) setState(() => _info = _toInfo(entity));
    } catch (_) {
      // Info tab will stay in loading state — interaction still works.
    }
  }

  static CompanionInfo _toInfo(lf.CompanionEntity entity) {
    const rarityColors = <String, Color>{
      'common': Color(0xFF9E9E9E),
      'uncommon': Color(0xFF66BB6A),
      'rare': Color(0xFF42A5F5),
      'epic': Color(0xFFAB47BC),
      'legendary': Color(0xFFFFA726),
    };
    const rarityLabels = <String, String>{
      'common': 'Common',
      'uncommon': 'Uncommon',
      'rare': 'Rare',
      'epic': 'Epic',
      'legendary': 'Legendary',
    };

    final rarity = entity.rarityTier.toLowerCase();
    final traits = entity.traits
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    return CompanionInfo(
      name: entity.name,
      rarityLabel: rarityLabels[rarity] ?? rarity,
      rarityColor: rarityColors[rarity] ?? const Color(0xFF9E9E9E),
      traits: traits,
      evolutionStage: entity.evolutionStage,
      assetCredit: entity.assetCredit,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Inter is bundled at build time (see pubspec.yaml). Setting it as the
    // theme's fontFamily prevents Material from falling back to Roboto, which
    // Flutter Web would otherwise fetch from fonts.gstatic.com at runtime —
    // a third-party request the strict CSP and the offline-first architecture
    // both reject.
    final base = ThemeData.dark(useMaterial3: true);
    final profileRepository = ServerpodProfileRepository(widget.client);
    final themeRepository = ServerpodThemeRepository(widget.client);
    final licenseRepository = ServerpodLicenseRepository(widget.client);

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AuthCubit(
            client: widget.client,
            sessionManager: widget.sessionManager,
          ),
        ),
        BlocProvider(
          create: (_) => DashboardProfileCubit(profileRepository)..loadProfiles(),
        ),
        BlocProvider(
          // profileRepository is required so applyTheme resolves the active
          // profile id and persists the choice server-side. Without it the
          // theme is applied with a null profileId, which the server treats
          // as a no-op — so the dashboard never updates.
          create: (_) => ThemeCubit(
            themeRepository,
            profileRepository: profileRepository,
          )..loadThemes(),
        ),
        BlocProvider(
          create: (_) => LicenseCubit(licenseRepository)..loadStatus(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Landfall Companion',
        theme: base.copyWith(
          textTheme: base.textTheme.apply(fontFamily: 'Inter'),
          primaryTextTheme: base.primaryTextTheme.apply(fontFamily: 'Inter'),
        ),
        home: _CompanionHome(
          displayId: widget.displayId,
          serverUrl: widget.serverUrl,
          webServerUrl: widget.webServerUrl,
          client: widget.client,
          info: _info,
        ),
      ),
    );
  }
}

class _CompanionHome extends StatefulWidget {
  const _CompanionHome({
    required this.displayId,
    required this.serverUrl,
    required this.webServerUrl,
    required this.client,
    required this.info,
  });

  final String displayId;
  final String serverUrl;
  final String webServerUrl;
  final lf.Client client;
  final CompanionInfo? info;

  @override
  State<_CompanionHome> createState() => _CompanionHomeState();
}

class _CompanionHomeState extends State<_CompanionHome> {
  int _pageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      body: IndexedStack(
        index: _pageIndex,
        children: [
          CompanionMobileScreen(
            displayId: widget.displayId,
            onAction: (kind) =>
                widget.client.companion.pushAction(widget.displayId, kind),
            info: widget.info,
          ),
          AuthGate(
            child: WebSettingsScreen(
              onPush: (kind) =>
                  widget.client.companion.pushAction(widget.displayId, kind),
              client: widget.client,
              serverUrl: widget.serverUrl,
              webServerUrl: widget.webServerUrl,
              displayId: widget.displayId,
              onOpenUrl: (url) => web.window.open(url, '_blank'),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _pageIndex,
        onDestinationSelected: (i) => setState(() => _pageIndex = i),
        backgroundColor: const Color(0xFF0D0F14),
        indicatorColor: const Color(0xFF4F8EF7).withValues(alpha: 0.15),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.pets_outlined),
            selectedIcon: Icon(Icons.pets),
            label: 'Companion',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
