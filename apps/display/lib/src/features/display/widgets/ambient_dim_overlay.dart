import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:display/src/features/clock/cubit/clock_cubit.dart';
import 'package:display/src/features/clock/cubit/clock_state.dart';
import 'package:display/src/features/settings/cubit/display_settings_cubit.dart';

/// Full-screen black overlay that dims the display on a configurable schedule.
///
/// Opacity is driven by [DisplaySettingsCubit] + [ClockCubit]:
///   - If dim is disabled → opacity 0.0
///   - If current hour is inside [dimStartHour, dimEndHour) → [dimLevel]
///   - Otherwise → 0.0
///
/// The dim window wraps midnight correctly (e.g. 22 → 7 covers 10 pm to 7 am).
/// Transitions use a 2-second animated fade so the change is gentle.
///
/// Pointer events are ignored so underlying cards remain interactive.
class AmbientDimOverlay extends StatelessWidget {
  const AmbientDimOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DisplaySettingsCubit, DisplaySettingsState>(
      builder: (_, settingsState) {
        return BlocBuilder<ClockCubit, ClockState>(
          builder: (_, clockState) {
            final opacity = _opacity(settingsState, clockState);
            return IgnorePointer(
              child: AnimatedOpacity(
                opacity: opacity,
                duration: const Duration(seconds: 2),
                child: const SizedBox.expand(
                  child: ColoredBox(color: Colors.black),
                ),
              ),
            );
          },
        );
      },
    );
  }

  static double _opacity(
    DisplaySettingsState settingsState,
    ClockState clockState,
  ) {
    if (settingsState is! DisplaySettingsLoaded) return 0.0;
    final s = settingsState.settings;
    if (!s.dimEnabled) return 0.0;
    if (clockState is! ClockTicking) return 0.0;

    final hour = clockState.entity.now.hour;
    final inDimWindow = s.dimStartHour > s.dimEndHour
        // wraps midnight: e.g. start=22, end=7 → dim from 10 pm to 7 am
        ? hour >= s.dimStartHour || hour < s.dimEndHour
        // same day: e.g. start=2, end=6
        : hour >= s.dimStartHour && hour < s.dimEndHour;

    return inDimWindow ? s.dimLevel : 0.0;
  }
}
