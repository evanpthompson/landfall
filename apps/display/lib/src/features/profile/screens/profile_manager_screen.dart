import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';

import 'package:display/src/features/profile/cubit/dashboard_profile_cubit.dart';
import 'package:display/src/features/profile/cubit/dashboard_profile_state.dart';
import 'package:display/src/features/theme/cubit/theme_cubit.dart';
import 'package:display/src/features/theme/cubit/theme_state.dart';

/// Full-screen panel for managing named dashboard profiles.
///
/// Lists all profiles with their active state. Supports:
///   - Activating a profile (tap the row)
///   - Creating a new profile (FAB or "+ New Profile" button)
///   - Renaming a profile (swipe action or context menu)
///   - Duplicating a profile (context menu)
///   - Deleting an inactive profile (swipe action or context menu)
class ProfileManagerScreen extends StatelessWidget {
  const ProfileManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LandfallColors.background,
      appBar: AppBar(
        backgroundColor: LandfallColors.surface,
        foregroundColor: LandfallColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Profiles', style: TextStyle(fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _showCreateDialog(context),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('New'),
            style: TextButton.styleFrom(
              foregroundColor: LandfallColors.accent,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<DashboardProfileCubit, DashboardProfileState>(
        builder: (context, state) {
          return switch (state) {
            DashboardProfileLoading() =>
              const Center(child: CircularProgressIndicator()),
            DashboardProfileError(:final message) => Center(
                child: Text(
                  message,
                  style: const TextStyle(color: LandfallColors.textSecondary),
                ),
              ),
            DashboardProfileLoaded(:final profiles) =>
              _ProfileList(profiles: profiles),
          };
        },
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => _ProfileNameDialog(
        title: 'New Profile',
        confirmLabel: 'Create',
        onConfirm: (name) {
          context.read<DashboardProfileCubit>().createProfile(name);
        },
      ),
    );
  }
}

class _ProfileList extends StatelessWidget {
  const _ProfileList({required this.profiles});

  final List<ProfileInfo> profiles;

  @override
  Widget build(BuildContext context) {
    if (profiles.isEmpty) {
      return Center(
        child: Text(
          'No profiles yet.',
          style: TextStyle(color: LandfallColors.textSecondary),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: profiles.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _ProfileTile(profile: profiles[i]),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({required this.profile});

  final ProfileInfo profile;

  @override
  Widget build(BuildContext context) {
    final isActive = profile.isActive;
    return GestureDetector(
      onTap: isActive
          ? null
          : () => context.read<DashboardProfileCubit>().activateProfile(profile.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isActive
              ? LandfallColors.accent.withValues(alpha: 0.12)
              : LandfallColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? LandfallColors.accent : LandfallColors.cardBorder,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name,
                    style: TextStyle(
                      color: isActive
                          ? LandfallColors.accent
                          : LandfallColors.textPrimary,
                      fontSize: 15,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  if (profile.schedule != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _scheduleLabel(profile.schedule!),
                      style: const TextStyle(
                        color: LandfallColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (profile.companionThemeSlug != null)
                    _CompanionThemeChip(
                      slug: profile.companionThemeSlug!,
                      profileId: profile.id,
                    ),
                ],
              ),
            ),
            if (isActive)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.check_circle,
                  color: LandfallColors.accent,
                  size: 18,
                ),
              ),
            _ProfileMenu(profile: profile),
          ],
        ),
      ),
    );
  }

  String _scheduleLabel(ProfileSchedule schedule) {
    return switch (schedule.type) {
      ProfileScheduleType.always => 'Always active',
      ProfileScheduleType.weekday => 'Weekdays',
      ProfileScheduleType.weekend => 'Weekends',
      ProfileScheduleType.daily =>
        '${schedule.startHour}:00 – ${schedule.endHour}:00 daily',
      ProfileScheduleType.custom => 'Custom schedule',
    };
  }
}

/// Small chip below the profile name that surfaces the companion theme.
///
/// Tapping it applies the theme to this profile when the theme is locally
/// available. When the theme isn't loaded (not installed or not yet fetched), a
/// snackbar prompts the user to browse the available themes.
class _CompanionThemeChip extends StatelessWidget {
  const _CompanionThemeChip({required this.slug, required this.profileId});

  final String slug;
  final int profileId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: GestureDetector(
        onTap: () => _applyOrPrompt(context),
        child: Container(
          key: const Key('companion_theme_chip'),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: LandfallColors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: LandfallColors.accent.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.palette_outlined,
                  size: 11, color: LandfallColors.accent),
              const SizedBox(width: 4),
              Text(
                slug,
                style: TextStyle(
                  color: LandfallColors.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _applyOrPrompt(BuildContext context) {
    final themeState = context.read<ThemeCubit>().state;
    if (themeState is ThemeLoaded) {
      final theme = themeState.themes.where((t) => t.slug == slug).firstOrNull;
      if (theme != null) {
        context.read<ThemeCubit>().applyTheme(theme.id, profileId: profileId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Applied "${theme.name}" to this profile'),
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Open Themes to install this look'),
        duration: Duration(seconds: 3),
      ),
    );
  }
}

class _ProfileMenu extends StatelessWidget {
  const _ProfileMenu({required this.profile});

  final ProfileInfo profile;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_ProfileAction>(
      icon: Icon(
        Icons.more_vert,
        size: 18,
        color: LandfallColors.textSecondary,
      ),
      color: LandfallColors.surface,
      onSelected: (action) => _handleAction(context, action),
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: _ProfileAction.rename,
          child: Text('Rename'),
        ),
        const PopupMenuItem(
          value: _ProfileAction.duplicate,
          child: Text('Duplicate'),
        ),
        if (!profile.isActive)
          const PopupMenuItem(
            value: _ProfileAction.delete,
            child: Text('Delete', style: TextStyle(color: Color(0xFFFF6B6B))),
          ),
      ],
    );
  }

  void _handleAction(BuildContext context, _ProfileAction action) {
    switch (action) {
      case _ProfileAction.rename:
        showDialog<void>(
          context: context,
          builder: (_) => _ProfileNameDialog(
            title: 'Rename Profile',
            initialValue: profile.name,
            confirmLabel: 'Rename',
            onConfirm: (name) {
              context.read<DashboardProfileCubit>().renameProfile(profile.id, name);
            },
          ),
        );
      case _ProfileAction.duplicate:
        showDialog<void>(
          context: context,
          builder: (_) => _ProfileNameDialog(
            title: 'Duplicate Profile',
            initialValue: '${profile.name} Copy',
            confirmLabel: 'Duplicate',
            onConfirm: (name) {
              context
                  .read<DashboardProfileCubit>()
                  .duplicateProfile(profile.id, name);
            },
          ),
        );
      case _ProfileAction.delete:
        showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: LandfallColors.surface,
            title: const Text('Delete Profile?'),
            content: Text('Delete "${profile.name}"? This cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context
                      .read<DashboardProfileCubit>()
                      .deleteProfile(profile.id);
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFFF6B6B),
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
    }
  }
}

enum _ProfileAction { rename, duplicate, delete }

class _ProfileNameDialog extends StatefulWidget {
  const _ProfileNameDialog({
    required this.title,
    this.initialValue = '',
    required this.confirmLabel,
    required this.onConfirm,
  });

  final String title;
  final String initialValue;
  final String confirmLabel;
  final ValueChanged<String> onConfirm;

  @override
  State<_ProfileNameDialog> createState() => _ProfileNameDialogState();
}

class _ProfileNameDialogState extends State<_ProfileNameDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: LandfallColors.surface,
      title: Text(widget.title),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Profile name'),
        onSubmitted: (_) => _confirm(context),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => _confirm(context),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }

  void _confirm(BuildContext context) {
    final name = _ctrl.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop();
    widget.onConfirm(name);
  }
}
