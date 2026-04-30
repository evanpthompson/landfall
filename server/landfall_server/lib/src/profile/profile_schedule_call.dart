// ignore_for_file: deprecated_member_use

import 'dart:convert';

import 'package:landfall_shared/landfall_shared.dart';
import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

const _evaluationInterval = Duration(minutes: 1);

/// Evaluates all profile schedules once per minute and activates the
/// highest-priority matching profile.
///
/// Priority is determined by [DashboardProfile.sortOrder]: the matching profile
/// with the lowest sort order wins. Profiles with no schedule ([scheduleJson]
/// null) are ignored — they are only activated manually.
///
/// If the winning profile is already active, no DB write is performed.
/// Re-registers itself every [_evaluationInterval] so the loop runs
/// indefinitely.
class ProfileScheduleCall extends FutureCall<SerializableModel> {
  @override
  Future<void> invoke(Session session, SerializableModel? object) async {
    try {
      await _evaluate(session);
    } catch (e, stackTrace) {
      session.log(
        'Profile schedule evaluation failed: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
    } finally {
      await session.serverpod.futureCallWithDelay(
        'profileSchedule',
        null,
        _evaluationInterval,
      );
    }
  }

  Future<void> _evaluate(Session session) async {
    final now = DateTime.now().toLocal();

    final all = await DashboardProfile.db.find(
      session,
      orderBy: (t) => t.sortOrder,
    );

    DashboardProfile? winner;
    for (final profile in all) {
      if (profile.scheduleJson == null) continue;
      try {
        final schedule = ProfileSchedule.fromJson(
          jsonDecode(profile.scheduleJson!) as Map<String, dynamic>,
        );
        if (schedule.isActiveAt(now)) {
          winner = profile;
          break; // lowest sortOrder wins — list is already sorted
        }
      } catch (_) {
        // Malformed scheduleJson — skip this profile.
      }
    }

    if (winner == null || winner.isActive) return;

    // Deactivate all, then activate the winner.
    for (final p in all) {
      if (p.isActive) {
        await DashboardProfile.db.updateRow(
          session,
          p.copyWith(isActive: false),
        );
      }
    }
    await DashboardProfile.db.updateRow(
      session,
      winner.copyWith(isActive: true),
    );
  }
}
