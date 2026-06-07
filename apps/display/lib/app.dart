import 'dart:io';

import 'package:flutter/material.dart' hide Card;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:landfall_client/landfall_client.dart' hide LandfallTheme;
import 'package:landfall_shared/landfall_shared.dart';

import 'package:display/src/app/app_config.dart';
import 'package:display/src/data/auth/file_client_auth_success_storage.dart';
import 'package:display/src/data/calendar/serverpod_calendar_repository.dart';
import 'package:display/src/data/cards/serverpod_card_repository.dart';
import 'package:display/src/data/local/app_database.dart';
import 'package:display/src/data/profile/serverpod_profile_repository.dart';
import 'package:display/src/data/photo/serverpod_photo_repository.dart';
import 'package:display/src/data/license/serverpod_license_repository.dart';
import 'package:display/src/data/settings/drift_display_settings_repository.dart';
import 'package:display/src/data/theme/serverpod_marketplace_repository.dart';
import 'package:display/src/data/theme/serverpod_theme_repository.dart';
import 'package:display/src/data/weather/serverpod_weather_repository.dart';
import 'package:display/src/domain/use_cases/get_current_time_use_case.dart';
import 'package:display/src/features/auth/cubit/auth_cubit.dart';
import 'package:display/src/features/auth/data/device_auth_client.dart';
import 'package:display/src/features/auth/screens/login_screen.dart';
import 'package:display/src/platform/leanback.dart';
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart';
import 'package:display/src/features/calendar/cubit/calendar_cubit.dart';
import 'package:display/src/features/cards/cubit/card_cubit.dart';
import 'package:display/src/features/clock/cubit/clock_cubit.dart';
import 'package:display/src/features/display/screens/display_screen.dart';
import 'package:display/src/features/profile/cubit/dashboard_profile_cubit.dart';
import 'package:display/src/features/photo/cubit/photo_cubit.dart';
import 'package:display/src/features/license/cubit/license_cubit.dart';
import 'package:display/src/features/settings/cubit/display_settings_cubit.dart';
import 'package:display/src/features/theme/cubit/marketplace_cubit.dart';
import 'package:display/src/features/theme/cubit/theme_cubit.dart';
import 'package:display/src/features/theme/cubit/theme_state.dart';
import 'package:display/src/data/companion/companion_poll_service.dart';
import 'package:display/src/data/companion/companion_repository.dart';
import 'package:display/src/data/companion/serverpod_companion_repository.dart';
import 'package:display/src/features/companion/companion_event_bus.dart';
import 'package:display/src/features/companion/cubit/companion_cubit.dart';
import 'package:display/src/features/ticker/cubit/ticker_cubit.dart';
import 'package:display/src/features/weather/cubit/weather_cubit.dart';
import 'package:ui_kit/ui_kit.dart';

/// Root application widget.
///
/// Wires together all data sources, repositories, use cases, and BLoCs, then
/// gates on [AuthCubit] state: shows [LoginScreen] until authenticated, then
/// shows [DisplayScreen].
class LandfallApp extends StatelessWidget {
  const LandfallApp({
    super.key,
    required this.database,
    required this.serverUrl,
    required this.displayId,
    required this.clockRepository,
  });

  final AppDatabase database;

  /// Clock source for the [ClockCubit]. Owned by `main.dart` so it can be
  /// aligned to the server-configured timezone after launch.
  final ClockRepository clockRepository;

  /// The Serverpod server URL.
  ///
  /// Development: `'http://localhost:8080/'`
  /// Production:  `'https://<your-server-domain>/'`
  final String serverUrl;

  /// Stable unique identifier for this display, generated on first launch.
  final String displayId;

  @override
  Widget build(BuildContext context) {
    // Build the session manager with file-based storage so the full AuthSuccess
    // (access token + refresh token) survives app restarts. The session manager
    // implements RefresherClientAuthKeyProvider, so the Serverpod Client will
    // automatically refresh the 10-minute access token before it expires.
    final sessionManager = ClientAuthSessionManager(
      storage: FileClientAuthSuccessStorage(),
    );
    final client = Client(serverUrl)..authSessionManager = sessionManager;

    final profileRepository = ServerpodProfileRepository(client);
    final cardRepository = ServerpodCardRepository(client);
    final weatherRepository = ServerpodWeatherRepository(client, database);
    final calendarRepository = ServerpodCalendarRepository(client);
    final webServerUrl = kLandfallWebServerUrl.isNotEmpty
        ? kLandfallWebServerUrl
        : serverUrl;
    final photoRepository = ServerpodPhotoRepository(client, webServerUrl);
    final displaySettingsRepository = DriftDisplaySettingsRepository(database);
    final getCurrentTime = GetCurrentTimeUseCase(clockRepository);
    final licenseRepository = ServerpodLicenseRepository(client);
    final themeRepository = ServerpodThemeRepository(client);
    final marketplaceRepository = ServerpodMarketplaceRepository(client);

    final companionEventBus = CompanionEventBus();
    final companionRepository = ServerpodCompanionRepository(client);
    final companionPollService = ClientCompanionPollService(client);

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<CompanionEventBus>(create: (_) => companionEventBus),
        RepositoryProvider<CompanionRepository>(
          create: (_) => companionRepository,
        ),
        RepositoryProvider<CompanionPollService>(
          create: (_) => companionPollService,
        ),
        RepositoryProvider<DashboardProfileRepository>(
          create: (_) => profileRepository,
        ),
        RepositoryProvider<CardRepository>(create: (_) => cardRepository),
        RepositoryProvider<WeatherRepository>(create: (_) => weatherRepository),
        RepositoryProvider<CalendarRepository>(
          create: (_) => calendarRepository,
        ),
        RepositoryProvider<PhotoRepository>(create: (_) => photoRepository),
        RepositoryProvider<DisplaySettingsRepository>(
          create: (_) => displaySettingsRepository,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => AuthCubit(
              client: client,
              sessionManager: sessionManager,
              deviceAuthClient: HttpDeviceAuthClient(serverUrl: webServerUrl),
            ),
          ),
          BlocProvider(
            create: (ctx) => DashboardProfileCubit(
              ctx.read<DashboardProfileRepository>(),
              bus: companionEventBus,
            ),
          ),
          BlocProvider(create: (_) => ClockCubit(getCurrentTime)),
          BlocProvider(
            create: (_) => CardCubit(cardRepository, bus: companionEventBus),
          ),
          BlocProvider(
            create: (_) =>
                WeatherCubit(weatherRepository, bus: companionEventBus),
          ),
          BlocProvider(
            create: (ctx) => CalendarCubit(ctx.read<CalendarRepository>()),
          ),
          BlocProvider(
            create: (ctx) => PhotoCubit(
              ctx.read<PhotoRepository>(),
              ctx.read<DisplaySettingsRepository>(),
            ),
          ),
          BlocProvider(
            create: (ctx) =>
                DisplaySettingsCubit(ctx.read<DisplaySettingsRepository>()),
          ),
          BlocProvider(
            create: (ctx) => TickerCubit(ctx.read<CardRepository>()),
          ),
          BlocProvider(create: (_) => LicenseCubit(licenseRepository)),
          BlocProvider(
            create: (_) => ThemeCubit(
              themeRepository,
              profileRepository: profileRepository,
            )..loadThemes(),
          ),
          BlocProvider(
            create: (_) =>
                MarketplaceCubit(marketplaceRepository)..loadMarketplace(),
          ),
          BlocProvider(
            create: (ctx) => CompanionCubit(
              displayId: displayId,
              serverUrl: serverUrl,
              repository: ctx.read<CompanionRepository>(),
            ),
          ),
        ],
        child: BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, themeState) {
            final themeData = themeState is ThemeLoaded
                ? themeState.active.tokens.toMaterialThemeData()
                : LandfallTheme.dark;
            return MaterialApp(
              title: 'Landfall',
              debugShowCheckedModeBanner: false,
              theme: themeData,
              // On Android (Fire TV) the platform reports a high screen density
              // (hdpi/xhdpi), so Flutter's logical coordinate space can be as
              // small as 960×540 even on a 1080p display. That makes the grid
              // cells too small, the agent feed too narrow, and the companion
              // card QR code dominant. FittedBox scales a fixed 1920×1080
              // design space to fill the logical size the platform reports;
              // the MediaQuery override ensures widgets inside always see
              // 1920×1080 design coords. Desktop is left untouched so it
              // responds naturally to the monitor's actual resolution.
              builder: Platform.isAndroid
                  ? (context, child) {
                      const designSize = Size(1920, 1080);
                      return MediaQuery(
                        data: MediaQuery.of(context).copyWith(
                          size: designSize,
                          textScaler: TextScaler.noScaling,
                        ),
                        child: FittedBox(
                          fit: BoxFit.fill,
                          child: SizedBox.fromSize(
                            size: designSize,
                            child: child!,
                          ),
                        ),
                      );
                    }
                  : null,
              home: _AuthGate(client: client, serverUrl: serverUrl),
            );
          },
        ),
      ),
    );
  }
}

/// Switches between [LoginScreen] and [DisplayScreen] based on auth state.
class _AuthGate extends StatefulWidget {
  const _AuthGate({required this.client, required this.serverUrl});

  final Client client;
  final String serverUrl;

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool? _leanback;

  @override
  void initState() {
    super.initState();
    Leanback().isLeanback().then((v) {
      if (mounted) setState(() => _leanback = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Integration tests bypass auth: either the server URL is injected
    // directly, or wizard mode is active (wizard completes then lands here).
    if (kIntegrationTestServerUrl.isNotEmpty || kIntegrationTestWizardMode) {
      return DisplayScreen(
  client: widget.client,
  serverUrl: widget.serverUrl,
  leanback: _leanback ?? false,
);
    }
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          return DisplayScreen(
  client: widget.client,
  serverUrl: widget.serverUrl,
  leanback: _leanback ?? false,
);
        }
        return LoginScreen(
          leanback: _leanback ?? false,
          serverUrl: widget.serverUrl,
        );
      },
    );
  }
}
