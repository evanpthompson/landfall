import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';

import '../cubit/license_cubit.dart';

/// Settings tab showing license status, upgrade paths, and key activation.
class LicenseTab extends StatelessWidget {
  const LicenseTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LicenseCubit, LicenseState>(
      builder: (context, state) => switch (state) {
        LicenseLoading() || LicenseActivating() => const Center(
            child: CircularProgressIndicator(),
          ),
        LicenseError(:final message) => _ErrorView(message: message),
        LicenseLoaded(:final status) => _LicenseView(status: status),
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _LicenseView extends StatelessWidget {
  const _LicenseView({required this.status});

  final LicenseStatus status;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _TierBadge(status: status),
        const SizedBox(height: 32),
        if (!status.isPro) ...[
          _UpgradeSection(),
          const SizedBox(height: 32),
        ],
        if (status.isPro) ...[
          _ActiveLicenseSection(status: status),
          const SizedBox(height: 32),
        ],
        _ActivateKeySection(),
      ],
    );
  }
}

class _TierBadge extends StatelessWidget {
  const _TierBadge({required this.status});

  final LicenseStatus status;

  @override
  Widget build(BuildContext context) {
    final color = status.isPro ? const Color(0xFFFFD700) : LandfallColors.textSecondary;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: LandfallColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: status.isPro ? const Color(0xFFFFD700).withValues(alpha: 0.4) : LandfallColors.cardBorder,
          width: status.isPro ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            status.isPro ? Icons.workspace_premium : Icons.person_outline,
            color: color,
            size: 28,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                status.tier.displayName,
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (status.activatedAt != null)
                Text(
                  'Activated ${_formatDate(status.activatedAt!)}',
                  style: const TextStyle(
                    color: LandfallColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

class _UpgradeSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader('Upgrade'),
        const SizedBox(height: 12),
        const Text(
          'Unlock multi-display support, unlimited API rate limits, advanced layout features, and 90-day card history.',
          style: TextStyle(color: LandfallColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 16),
        _PriceCard(
          name: 'Pro',
          price: '\$50',
          description: 'One-time purchase. No subscriptions, ever.',
          color: LandfallColors.accent,
          onBuy: () => _copyPaymentLink(context, 'Pro'),
        ),
        const SizedBox(height: 12),
        _PriceCard(
          name: 'Founding Member',
          price: '\$80',
          description: 'Pro + early access to new features for the first 18 months.',
          color: const Color(0xFFFFD700),
          onBuy: () => _copyPaymentLink(context, 'Founding Member'),
        ),
      ],
    );
  }

  void _copyPaymentLink(BuildContext context, String tier) {
    // Payment links are opened in-browser; show the link to copy.
    // In a full integration this would use url_launcher to open the Stripe link.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Visit landfall.dev/buy to purchase $tier'),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({
    required this.name,
    required this.price,
    required this.description,
    required this.color,
    required this.onBuy,
  });

  final String name;
  final String price;
  final String description;
  final Color color;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: LandfallColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: LandfallColors.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    price,
                    style: const TextStyle(
                      color: LandfallColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      color: LandfallColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: onBuy,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.black,
              ),
              child: const Text('Buy'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveLicenseSection extends StatelessWidget {
  const _ActiveLicenseSection({required this.status});

  final LicenseStatus status;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader('Active License'),
        const SizedBox(height: 12),
        if (status.maskedKey != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: LandfallColors.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: LandfallColors.cardBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    status.maskedKey!,
                    style: const TextStyle(
                      color: LandfallColors.textSecondary,
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 16),
                  color: LandfallColors.textSecondary,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: status.maskedKey!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('License key copied'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ActivateKeySection extends StatefulWidget {
  @override
  State<_ActivateKeySection> createState() => _ActivateKeySectionState();
}

class _ActivateKeySectionState extends State<_ActivateKeySection> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _activate() {
    final key = _ctrl.text.trim();
    if (key.isEmpty) return;
    context.read<LicenseCubit>().activateLicense(key);
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader('Activate a Key'),
        const SizedBox(height: 4),
        const Text(
          'Enter the license key from your purchase confirmation email.',
          style: TextStyle(color: LandfallColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                style: const TextStyle(
                  color: LandfallColors.textPrimary,
                  fontFamily: 'monospace',
                ),
                decoration: InputDecoration(
                  hintText: 'LF-PRO-XXXX-XXXX',
                  hintStyle: const TextStyle(
                    color: LandfallColors.textTertiary,
                    fontFamily: 'monospace',
                  ),
                  filled: true,
                  fillColor: LandfallColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: LandfallColors.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: LandfallColors.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: LandfallColors.accent),
                  ),
                ),
                onSubmitted: (_) => _activate(),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _activate,
              style: ElevatedButton.styleFrom(
                backgroundColor: LandfallColors.accent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              child: const Text('Activate'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        BlocBuilder<LicenseCubit, LicenseState>(
          builder: (context, state) {
            if (state is LicenseError) {
              return Text(
                state.message.replaceAll('Exception: ', ''),
                style: const TextStyle(
                  color: LandfallColors.warning,
                  fontSize: 12,
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(color: LandfallColors.textSecondary),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;
  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: LandfallColors.textTertiary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}
