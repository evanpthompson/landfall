import 'package:flutter/material.dart' hide Card;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:landfall_client/landfall_client.dart';
import 'package:landfall_shared/landfall_shared.dart';

import 'package:display/src/data/cards/serverpod_card_repository.dart';
import 'package:display/src/data/clock/system_clock_repository.dart';
import 'package:display/src/data/local/app_database.dart';
import 'package:display/src/data/local/repositories/drift_dashboard_layout_repository.dart';
import 'package:display/src/domain/use_cases/get_current_time_use_case.dart';
import 'package:display/src/features/cards/cubit/card_cubit.dart';
import 'package:display/src/features/clock/cubit/clock_cubit.dart';
import 'package:display/src/features/display/screens/display_screen.dart';
import 'package:display/src/features/layout/cubit/dashboard_layout_cubit.dart';
import 'package:ui_kit/ui_kit.dart';

/// Root application widget.
///
/// Wires together all data sources, repositories, use cases, and BLoCs, then
/// hands off to [DisplayScreen] as the home route.
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
    final client = Client(serverUrl);
    final layoutRepository = DriftDashboardLayoutRepository(database);
    final cardRepository = ServerpodCardRepository(client);
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
      ],
      child: MultiBlocProvider(
        providers: [
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
        ],
        child: MaterialApp(
          title: 'Landfall',
          debugShowCheckedModeBanner: false,
          theme: LandfallTheme.dark,
          home: const DisplayScreen(),
        ),
      ),
    );
  }
}
