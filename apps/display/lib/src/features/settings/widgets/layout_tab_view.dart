import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';

import 'package:display/src/features/profile/cubit/dashboard_profile_cubit.dart';
import 'package:display/src/features/profile/cubit/dashboard_profile_state.dart';
import 'package:display/src/features/profile/screens/profile_manager_screen.dart';
import 'package:display/src/features/profile/widgets/profile_switcher.dart';
import 'package:display/src/features/settings/widgets/layout_editor.dart';
import 'package:display/src/features/settings/widgets/section_header.dart';

class LayoutTabView extends StatelessWidget {
  const LayoutTabView({
    super.key,
    this.leanback = false,
    this.onMoveModeChanged,
    this.onCancelMoveRegistered,
    this.onAfterSave,
  });

  final bool leanback;
  final ValueChanged<bool>? onMoveModeChanged;
  final ValueChanged<VoidCallback>? onCancelMoveRegistered;

  /// Called after a successful layout save. When provided (web context),
  /// the caller is responsible for firing the push notification.
  final Future<void> Function(DashboardLayout)? onAfterSave;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardProfileCubit, DashboardProfileState>(
      builder: (context, state) {
        if (state is! DashboardProfileLoaded) {
          return const Center(child: CircularProgressIndicator());
        }
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader('Profile'),
              const SizedBox(height: 12),
              Row(
                children: [
                  ProfileSwitcher(
                    profiles: state.profiles,
                    activeId: state.active.id,
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ProfileManagerScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.tune, size: 16),
                    label: const Text('Manage profiles'),
                    style: TextButton.styleFrom(
                      foregroundColor: LandfallColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SectionHeader(
                leanback
                    ? 'Arrow keys to focus  •  OK to move  •  OK to drop  •  Back to cancel'
                    : 'Tap to select  •  drag to move  •  drag corner to resize',
              ),
              const SizedBox(height: 16),
              Expanded(
                child: LayoutEditor(
                  layout: state.active.layout,
                  onLayoutChanged: (updated) {
                    if (onAfterSave != null) {
                      onAfterSave!(updated);
                    } else {
                      context.read<DashboardProfileCubit>().saveActiveLayout(updated);
                    }
                  },
                  onReset: leanback
                      ? null
                      : () => context.read<DashboardProfileCubit>().resetActiveLayout(),
                  leanback: leanback,
                  onMoveModeChanged: onMoveModeChanged,
                  onCancelMoveRegistered: onCancelMoveRegistered,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
