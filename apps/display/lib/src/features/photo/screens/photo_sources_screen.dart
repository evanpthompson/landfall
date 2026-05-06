import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';

import '../cubit/photo_cubit.dart';

/// Settings screen for managing photo sources.
///
/// Lists configured sources and allows adding new ones (Local Directory,
/// Network URLs, S3). Tapping a source sets it active via [PhotoCubit.setSource].
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SourceTile(
            icon: Icons.cloud_outlined,
            title: 'Landfall Server',
            subtitle: 'Photos synced from Google Drive via your Landfall account',
            onTap: () =>
                context.read<PhotoCubit>().setSource(const PhotoSourceServerpod()),
          ),
        ],
      ),
    );
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
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: LandfallColors.surface,
        title: const Text(
          'Local Directory',
          style: TextStyle(color: LandfallColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: LandfallColors.textPrimary),
          decoration: const InputDecoration(
            hintText: '/home/pi/photos',
            hintStyle: TextStyle(color: LandfallColors.textTertiary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel',
                style: TextStyle(color: LandfallColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final path = controller.text.trim();
              if (path.isNotEmpty) {
                cubit.setSource(PhotoSourceLocalDirectory(path: path));
              }
              Navigator.of(context).pop();
            },
            child: const Text('Apply',
                style: TextStyle(color: LandfallColors.accent)),
          ),
        ],
      ),
    );
  }

  void _showNetworkUrlsDialog(BuildContext context, PhotoCubit cubit) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel',
                style: TextStyle(color: LandfallColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final urls = controller.text
                  .split('\n')
                  .map((u) => u.trim())
                  .where((u) => u.isNotEmpty)
                  .toList();
              if (urls.isNotEmpty) {
                cubit.setSource(PhotoSourceNetwork(urls: urls));
              }
              Navigator.of(context).pop();
            },
            child: const Text('Apply',
                style: TextStyle(color: LandfallColors.accent)),
          ),
        ],
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
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
    return ListTile(
      leading: Icon(icon, color: LandfallColors.accent, size: 22),
      title: Text(title,
          style: const TextStyle(color: LandfallColors.textPrimary)),
      subtitle: Text(subtitle,
          style: const TextStyle(color: LandfallColors.textSecondary, fontSize: 12)),
      onTap: onTap,
    );
  }
}

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
