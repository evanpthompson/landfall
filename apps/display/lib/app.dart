import 'package:flutter/material.dart' hide Card;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:landfall_client/landfall_client.dart';
import 'package:landfall_shared/landfall_shared.dart';

import 'package:display/src/data/auth/secure_storage_auth_key_provider.dart';
import 'package:display/src/data/calendar/serverpod_calendar_repository.dart';
import 'package:display/src/data/cards/serverpod_card_repository.dart';
import 'package:display/src/data/clock/system_clock_repository.dart';
import 'package:display/src/data/local/app_database.dart';
import 'package:display/src/data/local/repositories/drift_dashboard_layout_repository.dart';
import 'package:display/src/data/weather/serverpod_weather_repository.dart';
import 'package:display/src/domain/use_cases/get_current_time_use_case.dart';
import 'package:display/src/features/auth/cubit/auth_cubit.dart';
import 'package:display/src/features/auth/screens/login_screen.dart';
import 'package:display/src/features/calendar/cubit/calendar_cubit.dart';
import 'package:display/src/features/cards/cubit/card_cubit.dart';
import 'package:display/src/features/clock/cubit/clock_cubit.dart';
import 'package:display/src/features/display/screens/display_screen.dart';
import 'package:display/src/features/layout/cubit/dashboard_layout_cubit.dart';
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

    final layoutRepository = DriftDashboardLayoutRepository(database);
    final cardRepository = ServerpodCardRepository(client);
    final weatherRepository = ServerpodWeatherRepository(client, database);
    final calendarRepository = ServerpodCalendarRepository(client);
    final clockRepository = const SystemClockRepository();
    final getCurrentTime = GetCurrentTimeUseCase(clockRepository);

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<DashboardLayoutRepository>(
          create: (_) => layoutRepository,
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
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => AuthCubit(client: client, keyProvider: keyProvider),
          ),
          BlocProvider(
            create: (ctx) => DashboardLayoutCubit(
              ctx.read<DashboardLayoutRepository>(),
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
        ],
        child: MaterialApp(
          title: 'Landfall',
          debugShowCheckedModeBanner: false,
          theme: LandfallTheme.dark,
          home: const _AuthGate(),
        ),
      ),
    );
  }
}

/// Switches between [LoginScreen] and [DisplayScreen] based on auth state.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          return const DisplayScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
