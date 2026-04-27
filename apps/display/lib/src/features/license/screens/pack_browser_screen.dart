import 'package:flutter/material.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:landfall_client/landfall_client.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../license/cubit/license_cubit.dart';
import '../../../data/license/serverpod_pack_repository.dart';

/// Full-screen pack browser listing the integration pack catalog.
///
/// Shows owned packs with a checkmark and unowned packs with a "Buy" action.
class PackBrowserScreen extends StatefulWidget {
  const PackBrowserScreen({super.key, required this.client, required this.licenseCubit});

  final Client client;
  final LicenseCubit licenseCubit;

  @override
  State<PackBrowserScreen> createState() => _PackBrowserScreenState();
}

class _PackBrowserScreenState extends State<PackBrowserScreen> {
  late Future<List<IntegrationPackInfo>> _packsFuture;

  @override
  void initState() {
    super.initState();
    _packsFuture = ServerpodPackRepository(widget.client).listPacks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LandfallColors.background,
      appBar: AppBar(
        backgroundColor: LandfallColors.surface,
        foregroundColor: LandfallColors.textPrimary,
        elevation: 0,
        title: const Text('Integration Packs', style: TextStyle(fontSize: 18)),
      ),
      body: FutureBuilder<List<IntegrationPackInfo>>(
        future: _packsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Could not load packs.',
                style: const TextStyle(color: LandfallColors.textSecondary),
              ),
            );
          }
          final packs = snapshot.data ?? [];
          return _PackGrid(packs: packs);
        },
      ),
    );
  }
}

class _PackGrid extends StatelessWidget {
  const _PackGrid({required this.packs});

  final List<IntegrationPackInfo> packs;

  @override
  Widget build(BuildContext context) {
    if (packs.isEmpty) {
      return const Center(
        child: Text(
          'No packs available yet.',
          style: TextStyle(color: LandfallColors.textSecondary),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'One-time purchases — no subscriptions.',
            style: TextStyle(color: LandfallColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 360,
                mainAxisExtent: 180,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: packs.length,
              itemBuilder: (context, i) => _PackCard(pack: packs[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _PackCard extends StatelessWidget {
  const _PackCard({required this.pack});

  final IntegrationPackInfo pack;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: LandfallColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: pack.isOwned
              ? LandfallColors.success.withValues(alpha: 0.5)
              : LandfallColors.cardBorder,
          width: pack.isOwned ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    pack.name,
                    style: const TextStyle(
                      color: LandfallColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (pack.isOwned)
                  const Icon(
                    Icons.check_circle,
                    color: LandfallColors.success,
                    size: 18,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Text(
                pack.description,
                style: const TextStyle(
                  color: LandfallColors.textSecondary,
                  fontSize: 12,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '\$${pack.priceUsd.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: LandfallColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  '  one-time',
                  style: TextStyle(
                    color: LandfallColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                if (pack.isOwned)
                  const Chip(
                    label: Text(
                      'Owned',
                      style: TextStyle(fontSize: 11, color: LandfallColors.success),
                    ),
                    backgroundColor: Colors.transparent,
                    side: BorderSide(color: LandfallColors.success),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  )
                else
                  TextButton(
                    onPressed: () => _showBuyDialog(context),
                    style: TextButton.styleFrom(
                      foregroundColor: LandfallColors.accent,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    ),
                    child: const Text('Buy'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showBuyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LandfallColors.surface,
        title: Text(
          pack.name,
          style: const TextStyle(color: LandfallColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              pack.description,
              style: const TextStyle(color: LandfallColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Text(
              '\$${pack.priceUsd.toStringAsFixed(0)} — one-time purchase',
              style: const TextStyle(
                color: LandfallColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Visit landfall.dev/packs from your browser to complete your purchase. '
              'Your pack will be available after Stripe confirms payment.',
              style: TextStyle(
                color: LandfallColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Close',
              style: TextStyle(color: LandfallColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
