import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:landfall_shared/landfall_shared.dart';

import 'package:display/src/data/local/app_database.dart';
import 'package:display/src/data/local/repositories/drift_dashboard_layout_repository.dart';
import 'package:display/src/features/layout/cubit/dashboard_layout_cubit.dart';
import 'package:display/src/features/display/screens/display_screen.dart';
import 'package:ui_kit/ui_kit.dart';

class LandfallApp extends StatelessWidget {
  const LandfallApp({super.key, required this.database});

  final AppDatabase database;

  @override
  Widget build(BuildContext context) {
    final layoutRepository = DriftDashboardLayoutRepository(database);

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<DashboardLayoutRepository>(
          create: (_) => layoutRepository,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (ctx) => DashboardLayoutCubit(
              ctx.read<DashboardLayoutRepository>(),
            ),
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
