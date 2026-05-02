import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';

import 'package:display/src/features/profile/cubit/dashboard_profile_cubit.dart';

/// Horizontal scrolling row of chips — one per profile.
///
/// Tapping an inactive chip calls [DashboardProfileCubit.activateProfile].
/// The active chip is visually highlighted and its tap is a no-op.
class ProfileSwitcher extends StatelessWidget {
  const ProfileSwitcher({
    super.key,
    required this.profiles,
    required this.activeId,
  });

  final List<ProfileInfo> profiles;
  final int activeId;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: profiles.map((profile) {
          final isActive = profile.id == activeId;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ProfileChip(
              name: profile.name,
              isActive: isActive,
              onTap: isActive
                  ? null
                  : () => context
                      .read<DashboardProfileCubit>()
                      .activateProfile(profile.id),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// A single profile selection chip.
///
/// [onTap] is null when the chip represents the already-active profile,
/// making it inert to taps.
class ProfileChip extends StatelessWidget {
  const ProfileChip({
    super.key,
    required this.name,
    required this.isActive,
    required this.onTap,
  });

  final String name;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? LandfallColors.accent.withValues(alpha: 0.15)
              : LandfallColors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive
                ? LandfallColors.accent
                : LandfallColors.cardBorder,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Text(
          name,
          style: TextStyle(
            color: isActive
                ? LandfallColors.accent
                : LandfallColors.textSecondary,
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
