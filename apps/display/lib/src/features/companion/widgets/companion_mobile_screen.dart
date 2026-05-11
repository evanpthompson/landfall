import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:url_launcher/url_launcher.dart';

import '../provider/petdex_provider.dart';
import '../renderer/sprite_sheet_renderer.dart';

// ---------------------------------------------------------------------------
// Data

class CompanionInfo {
  const CompanionInfo({
    required this.name,
    required this.rarityLabel,
    required this.rarityColor,
    required this.traits,
    required this.evolutionStage,
    this.assetCredit,
  });

  final String name;
  final String rarityLabel;
  final Color rarityColor;
  final List<String> traits;
  final int evolutionStage;
  final String? assetCredit;
}

// ---------------------------------------------------------------------------
// Screen

class CompanionMobileScreen extends StatefulWidget {
  const CompanionMobileScreen({
    super.key,
    required this.displayId,
    required this.onAction,
    this.info,
  });

  final String displayId;
  final Future<void> Function(String kind) onAction;

  /// Companion metadata shown in the Info tab. Null while loading.
  final CompanionInfo? info;

  @override
  State<CompanionMobileScreen> createState() => _CompanionMobileScreenState();
}

class _CompanionMobileScreenState extends State<CompanionMobileScreen>
    with TickerProviderStateMixin {
  late final SpriteSheetCompanionRenderer _renderer;
  late final TabController _tabController;
  bool _loaded = false;
  bool _showFeedback = false;
  Timer? _feedbackTimer;

  static const _kLumenAsset = 'assets/companions/lumen.webp';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _renderer = SpriteSheetCompanionRenderer(
      provider: PetdexProvider(),
      vsync: this,
    );
    _loadSprite();
  }

  Future<void> _loadSprite() async {
    try {
      await _renderer.load(rootBundle, _kLumenAsset);
    } catch (_) {
      // Asset unavailable — show buttons without sprite rather than
      // leaving the user on a permanent loading screen.
    }
    if (mounted) setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    _tabController.dispose();
    _renderer.dispose();
    super.dispose();
  }

  static CompanionAnimationState _kindToState(String kind) => switch (kind) {
    'pet'  => CompanionAnimationState.pet,
    'play' => CompanionAnimationState.play,
    'feed' => CompanionAnimationState.reactCelebratory,
    _      => CompanionAnimationState.idle,
  };

  Future<void> _onAction(String kind) async {
    _renderer.triggerState(_kindToState(kind));
    setState(() => _showFeedback = true);
    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showFeedback = false);
    });
    widget.onAction(kind).ignore();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      body: SafeArea(
        child: Column(
          children: [
            // Creature — always visible regardless of active tab.
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_loaded)
                    _renderer.buildView()
                  else
                    const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF4F8EF7),
                        strokeWidth: 2.5,
                      ),
                    ),
                  if (_showFeedback) const _FeedbackOverlay(),
                ],
              ),
            ),

            // Tab bar.
            TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF4F8EF7),
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF5A6070),
              dividerColor: const Color(0xFF1E2130),
              tabs: const [
                Tab(text: 'Interact'),
                Tab(text: 'Info'),
              ],
            ),

            // Tab content — fixed height so the creature area doesn't shift.
            SizedBox(
              height: 160,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _InteractTab(onAction: _onAction),
                  _InfoTab(info: widget.info),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _FeedbackOverlay extends StatelessWidget {
  const _FeedbackOverlay();

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.favorite, color: Color(0xFFFF6B9D), size: 64);
  }
}

// ---------------------------------------------------------------------------

class _InteractTab extends StatelessWidget {
  const _InteractTab({required this.onAction});

  final Future<void> Function(String kind) onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Row(
        children: [
          Expanded(child: _ActionButton(label: 'Pet', kind: 'pet', icon: Icons.back_hand, onAction: onAction)),
          const SizedBox(width: 16),
          Expanded(child: _ActionButton(label: 'Play', kind: 'play', icon: Icons.sports_esports, onAction: onAction)),
          const SizedBox(width: 16),
          Expanded(child: _ActionButton(label: 'Feed', kind: 'feed', icon: Icons.restaurant, onAction: onAction)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.kind,
    required this.icon,
    required this.onAction,
  });

  final String label;
  final String kind;
  final IconData icon;
  final Future<void> Function(String kind) onAction;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      onPressed: () => onAction(kind),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF1E2130),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _InfoTab extends StatelessWidget {
  const _InfoTab({required this.info});

  final CompanionInfo? info;

  static const _petdexUrl = 'https://github.com/crafter-station/petdex';

  @override
  Widget build(BuildContext context) {
    final info = this.info;
    if (info == null) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF4F8EF7), strokeWidth: 2),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + rarity badge row.
          Row(
            children: [
              Expanded(
                child: Text(
                  info.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _RarityBadge(label: info.rarityLabel, color: info.rarityColor),
            ],
          ),

          if (info.evolutionStage > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Stage ${info.evolutionStage}',
              style: const TextStyle(color: Color(0xFF8892A4), fontSize: 12),
            ),
          ],

          if (info.traits.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: info.traits
                  .map((t) => _TraitChip(label: _capitalize(t)))
                  .toList(),
            ),
          ],

          const SizedBox(height: 12),
          const Divider(color: Color(0xFF1E2130), height: 1),
          const SizedBox(height: 10),

          // Attribution.
          if (info.assetCredit != null) ...[
            Text(
              info.assetCredit!,
              style: const TextStyle(color: Color(0xFF8892A4), fontSize: 12),
            ),
            const SizedBox(height: 4),
          ],
          GestureDetector(
            onTap: () => launchUrl(
              Uri.parse(_petdexUrl),
              mode: LaunchMode.externalApplication,
            ),
            child: const Text(
              'Sprites via petdex (crafter.run)',
              style: TextStyle(
                color: Color(0xFF4F8EF7),
                fontSize: 12,
                decoration: TextDecoration.underline,
                decorationColor: Color(0xFF4F8EF7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

// ---------------------------------------------------------------------------

class _RarityBadge extends StatelessWidget {
  const _RarityBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _TraitChip extends StatelessWidget {
  const _TraitChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2130),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Color(0xFFB0B8C8), fontSize: 12),
      ),
    );
  }
}
