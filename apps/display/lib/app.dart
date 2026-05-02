import 'package:flutter/material.dart' hide Card;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:landfall_client/landfall_client.dart' hide LandfallTheme;
import 'package:landfall_shared/landfall_shared.dart';

import 'package:display/src/app/app_config.dart';
import 'package:display/src/data/auth/secure_storage_auth_key_provider.dart';
import 'package:display/src/data/calendar/serverpod_calendar_repository.dart';
import 'package:display/src/data/cards/serverpod_card_repository.dart';
import 'package:display/src/data/clock/system_clock_repository.dart';
import 'package:display/src/data/local/app_database.dart';
import 'package:display/src/data/profile/serverpod_profile_repository.dart';
import 'package:display/src/data/photo/serverpod_photo_repository.dart';
import 'package:display/src/data/license/serverpod_license_repository.dart';
import 'package:display/src/data/settings/drift_display_settings_repository.dart';
import 'package:display/src/data/theme/serverpod_theme_repository.dart';
import 'package:display/src/data/weather/serverpod_weather_repository.dart';
import 'package:display/src/domain/use_cases/get_current_time_use_case.dart';
import 'package:display/src/features/auth/cubit/auth_cubit.dart';
import 'package:display/src/features/auth/screens/login_screen.dart';
import 'package:display/src/features/calendar/cubit/calendar_cubit.dart';
import 'package:display/src/features/cards/cubit/card_cubit.dart';
import 'package:display/src/features/clock/cubit/clock_cubit.dart';
import 'package:display/src/features/display/screens/display_screen.dart';
import 'package:display/src/features/profile/cubit/dashboard_profile_cubit.dart';
import 'package:display/src/features/photo/cubit/photo_cubit.dart';
import 'package:display/src/features/license/cubit/license_cubit.dart';
import 'package:display/src/features/settings/cubit/display_settings_cubit.dart';
import 'package:display/src/features/theme/cubit/theme_cubit.dart';
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
  });

  final AppDatabase database;

  /// The Serverpod server URL.
  ///
  /// Development: `'http://localhost:8080/'`
  /// Production:  `'https://api.makefastlandfall.com/'`
  final String serverUrl;

  @override
  Widget build(BuildContext context) {
    final keyProvider = SecureStorageAuthKeyProvider(
      const FlutterSecureStorage(),
    );
    final client = Client(serverUrl)
      ..authKeyProvider = keyProvider;

    final profileRepository = ServerpodProfileRepository(client);
    final cardRepository = ServerpodCardRepository(client);
    final weatherRepository = ServerpodWeatherRepository(client, database);
    final calendarRepository = ServerpodCalendarRepository(client);
    final photoRepository = ServerpodPhotoRepository(client, serverUrl);
    final displaySettingsRepository = DriftDisplaySettingsRepository(database);
    final clockRepository = const SystemClockRepository();
    final getCurrentTime = GetCurrentTimeUseCase(clockRepository);
    final licenseRepository = ServerpodLicenseRepository(client);
    final themeRepository = ServerpodThemeRepository(client);

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<DashboardProfileRepository>(
          create: (_) => profileRepository,
        ),
        RepositoryProvider<CardRepository>(
          create: (_) => cardRepository,
        ),
        RepositoryProvider<WeatherRepository>(
          create: (_) => weatherRepository,
        ),
        RepositoryProvider<CalendarRepository>(
          create: (_) => calendarRepository,
        ),
        RepositoryProvider<PhotoRepository>(
          create: (_) => photoRepository,
        ),
        RepositoryProvider<DisplaySettingsRepository>(
          create: (_) => displaySettingsRepository,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => AuthCubit(client: client, keyProvider: keyProvider),
          ),
          BlocProvider(
            create: (ctx) => DashboardProfileCubit(
              ctx.read<DashboardProfileRepository>(),
            ),
          ),
          BlocProvider(
            create: (_) => ClockCubit(getCurrentTime),
          ),
          BlocProvider(
            create: (ctx) => CardCubit(ctx.read<CardRepository>()),
          ),
          BlocProvider(
            create: (ctx) => WeatherCubit(ctx.read<WeatherRepository>()),
          ),
          BlocProvider(
            create: (ctx) => CalendarCubit(ctx.read<CalendarRepository>()),
          ),
          BlocProvider(
            create: (ctx) => PhotoCubit(ctx.read<PhotoRepository>()),
          ),
          BlocProvider(
            create: (ctx) =>
                DisplaySettingsCubit(ctx.read<DisplaySettingsRepository>()),
          ),
          BlocProvider(
            create: (ctx) => TickerCubit(ctx.read<CardRepository>()),
          ),
          BlocProvider(
            create: (_) => LicenseCubit(licenseRepository),
          ),
          BlocProvider(
            create: (_) => ThemeCubit(themeRepository)..loadThemes(),
          ),
        ],
        child: MaterialApp(
          title: 'Landfall',
          debugShowCheckedModeBanner: false,
          theme: LandfallTheme.dark,
          home: _AuthGate(client: client, serverUrl: serverUrl),
        ),
      ),
    );
  }
}

/// Switches between [LoginScreen] and [DisplayScreen] based on auth state.
class _AuthGate extends StatelessWidget {
  const _AuthGate({required this.client, required this.serverUrl});

  final Client client;
  final String serverUrl;

  @override
  Widget build(BuildContext context) {
    // Integration tests bypass auth: either the server URL is injected
    // directly, or wizard mode is active (wizard completes then lands here).
    if (kIntegrationTestServerUrl.isNotEmpty || kIntegrationTestWizardMode) {
      return DisplayScreen(client: client, serverUrl: serverUrl);
    }
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          return DisplayScreen(client: client, serverUrl: serverUrl);
        }
        return const LoginScreen();
      },
    );
  }
}
