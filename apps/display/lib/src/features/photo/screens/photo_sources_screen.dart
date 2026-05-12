import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';

import '../cubit/photo_cubit.dart';

/// Settings screen for managing photo sources.
///
/// Shows the active source with its load state and allows switching to
/// Local Directory, Network URLs, or the Landfall Server (Google Drive).
class PhotoSourcesScreen extends StatelessWidget {
  const PhotoSourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LandfallColors.background,
      appBar: AppBar(
        backgroundColor: LandfallColors.surface,
        foregroundColor: LandfallColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Photo Sources', style: TextStyle(fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, size: 22),
            onPressed: () => _showAddSourceSheet(context),
          ),
        ],
      ),
      body: BlocBuilder<PhotoCubit, PhotoState>(
        builder: (context, state) {
          final cubit = context.read<PhotoCubit>();
          final active = cubit.activeSource;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Active source section
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'ACTIVE SOURCE',
                  style: TextStyle(
                    color: LandfallColors.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              _ActiveSourceTile(source: active, state: state),
              const SizedBox(height: 24),

              // Available sources
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'SWITCH SOURCE',
                  style: TextStyle(
                    color: LandfallColors.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              _SourceTile(
                icon: Icons.cloud_outlined,
                title: 'Landfall Server',
                subtitle: 'Photos synced from Google Drive via your Landfall account',
                isActive: active is PhotoSourceServerpod,
                onTap: () async {
                  await cubit.setSource(const PhotoSourceServerpod());
                  if (context.mounted) {
                    _showFeedback(context, cubit.state);
                  }
                },
              ),
              _SourceTile(
                icon: Icons.folder_outlined,
                title: 'Local Directory',
                subtitle: active is PhotoSourceLocalDirectory
                    ? active.path
                    : 'Load images from a folder on this device',
                isActive: active is PhotoSourceLocalDirectory,
                onTap: () => _showLocalDirDialog(context, cubit),
              ),
              _SourceTile(
                icon: Icons.link,
                title: 'Network URLs',
                subtitle: active is PhotoSourceNetwork
                    ? '${active.urls.length} URL(s) configured'
                    : 'A list of direct image URLs',
                isActive: active is PhotoSourceNetwork,
                onTap: () => _showNetworkUrlsDialog(context, cubit),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _sanitizePath(String raw) {
    var s = raw.trim();
    if (s.length >= 2 &&
        ((s.startsWith('"') && s.endsWith('"')) ||
            (s.startsWith("'") && s.endsWith("'")))) {
      s = s.substring(1, s.length - 1).trim();
    }
    return s;
  }

  void _showFeedback(BuildContext context, PhotoState state) {
    final message = switch (state) {
      PhotoLoaded(:final photos) => '${photos.length} photo(s) loaded',
      PhotoEmpty() => 'No photos found at this source',
      PhotoError(:final message) => 'Error: $message',
      PhotoLoading() => null,
    };
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: state is PhotoLoaded
              ? const Color(0xFF2A7A4F)
              : const Color(0xFF7A2A2A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showAddSourceSheet(BuildContext context) {
    final cubit = context.read<PhotoCubit>();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: LandfallColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Add Photo Source',
              style: TextStyle(
                color: LandfallColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _AddSourceOption(
              icon: Icons.folder_outlined,
              title: 'Local Directory',
              subtitle: 'Load images from a folder on this device',
              onTap: () {
                Navigator.of(context).pop();
                _showLocalDirDialog(context, cubit);
              },
            ),
            const SizedBox(height: 8),
            _AddSourceOption(
              icon: Icons.link,
              title: 'Network URLs',
              subtitle: 'A list of direct image URLs',
              onTap: () {
                Navigator.of(context).pop();
                _showNetworkUrlsDialog(context, cubit);
              },
            ),
            const SizedBox(height: 8),
            _AddSourceOption(
              icon: Icons.cloud_queue,
              title: 'S3 Bucket',
              subtitle: 'AWS S3 or compatible object storage',
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('S3 support coming soon')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLocalDirDialog(BuildContext context, PhotoCubit cubit) {
    final active = cubit.activeSource;
    final controller = TextEditingController(
      text: active is PhotoSourceLocalDirectory ? active.path : '',
    );
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: LandfallColors.surface,
        title: const Text(
          'Local Directory',
          style: TextStyle(color: LandfallColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: LandfallColors.textPrimary),
          decoration: const InputDecoration(
            hintText: '/home/pi/photos',
            hintStyle: TextStyle(color: LandfallColors.textTertiary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel',
                style: TextStyle(color: LandfallColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              final path = _sanitizePath(controller.text);
              Navigator.of(dialogContext).pop();
              if (path.isNotEmpty) {
                await cubit.setSource(PhotoSourceLocalDirectory(path: path));
                if (context.mounted) _showFeedback(context, cubit.state);
              }
            },
            child: const Text('Apply',
                style: TextStyle(color: LandfallColors.accent)),
          ),
        ],
      ),
    );
  }

  void _showNetworkUrlsDialog(BuildContext context, PhotoCubit cubit) {
    final active = cubit.activeSource;
    final controller = TextEditingController(
      text: active is PhotoSourceNetwork
          ? active.urls.join('\n')
          : '',
    );
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: LandfallColors.surface,
        title: const Text(
          'Network URLs',
          style: TextStyle(color: LandfallColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: LandfallColors.textPrimary),
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'One URL per line\nhttps://example.com/photo.jpg',
            hintStyle: TextStyle(color: LandfallColors.textTertiary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel',
                style: TextStyle(color: LandfallColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              final urls = controller.text
                  .split('\n')
                  .map((u) => u.trim())
                  .where((u) => u.isNotEmpty)
                  .toList();
              Navigator.of(dialogContext).pop();
              if (urls.isNotEmpty) {
                await cubit.setSource(PhotoSourceNetwork(urls: urls));
                if (context.mounted) _showFeedback(context, cubit.state);
              }
            },
            child: const Text('Apply',
                style: TextStyle(color: LandfallColors.accent)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _ActiveSourceTile extends StatelessWidget {
  const _ActiveSourceTile({required this.source, required this.state});

  final PhotoSource source;
  final PhotoState state;

  @override
  Widget build(BuildContext context) {
    final (icon, title, detail) = switch (source) {
      PhotoSourceServerpod() => (
          Icons.cloud_outlined,
          'Landfall Server',
          'Google Drive sync',
        ),
      PhotoSourceLocalDirectory(:final path) => (
          Icons.folder_outlined,
          'Local Directory',
          path,
        ),
      PhotoSourceNetwork(:final urls) => (
          Icons.link,
          'Network URLs',
          '${urls.length} URL(s)',
        ),
      PhotoSourceS3(:final bucket) => (
          Icons.cloud_queue,
          'S3 Bucket',
          bucket,
        ),
    };

    final (statusLabel, statusColor) = switch (state) {
      PhotoLoaded(:final photos) => ('${photos.length} photos', const Color(0xFF3DD68C)),
      PhotoLoading() => ('Loading…', LandfallColors.textTertiary),
      PhotoEmpty() => ('No photos found', const Color(0xFFF5A623)),
      PhotoError() => ('Error loading photos', const Color(0xFFFF6B6B)),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LandfallColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: LandfallColors.accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: LandfallColors.accent, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: LandfallColors.textPrimary,
                        fontWeight: FontWeight.w600)),
                Text(detail,
                    style: const TextStyle(
                        color: LandfallColors.textSecondary, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (state is PhotoLoading)
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: LandfallColors.textTertiary,
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: statusColor.withValues(alpha: 0.4)),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon,
          color: isActive ? LandfallColors.accent : LandfallColors.textTertiary,
          size: 22),
      title: Text(title,
          style: TextStyle(
              color: isActive
                  ? LandfallColors.textPrimary
                  : LandfallColors.textSecondary)),
      subtitle: Text(subtitle,
          style: const TextStyle(
              color: LandfallColors.textTertiary, fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      trailing: isActive
          ? const Icon(Icons.check_circle,
              color: LandfallColors.accent, size: 18)
          : null,
      onTap: isActive ? null : onTap,
    );
  }
}

// ---------------------------------------------------------------------------

class _AddSourceOption extends StatelessWidget {
  const _AddSourceOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, color: LandfallColors.accent, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: LandfallColors.textPrimary, fontSize: 14)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: LandfallColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: LandfallColors.textTertiary, size: 18),
          ],
        ),
      ),
    );
  }
}
