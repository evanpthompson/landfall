import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../provider/petdex_provider.dart';
import '../renderer/sprite_sheet_renderer.dart';

/// The companion interaction page loaded on the phone after scanning the QR code.
///
/// Shows the companion creature full-screen with three action buttons at the
/// bottom: Pet, Play, Feed. Tapping a button calls [onAction] with the action
/// kind string, which the caller wires to [CompanionEndpoint.pushAction] so the
/// TV companion animates in near-real-time.
class CompanionMobileScreen extends StatefulWidget {
  const CompanionMobileScreen({
    super.key,
    required this.displayId,
    required this.onAction,
  });

  final String displayId;

  /// Called when the user taps an action button. The [kind] argument is one of
  /// `"pet"`, `"play"`, or `"feed"`. The caller is responsible for forwarding
  /// this to the server.
  final Future<void> Function(String kind) onAction;

  @override
  State<CompanionMobileScreen> createState() => _CompanionMobileScreenState();
}

class _CompanionMobileScreenState extends State<CompanionMobileScreen>
    with TickerProviderStateMixin {
  late final SpriteSheetCompanionRenderer _renderer;
  bool _showFeedback = false;
  Timer? _feedbackTimer;

  static const _kLumenAsset = 'assets/companions/lumen.webp';

  @override
  void initState() {
    super.initState();
    _renderer = SpriteSheetCompanionRenderer(
      provider: PetdexProvider(),
      vsync: this,
    );
    rootBundle
        .load(_kLumenAsset)
        .then((_) => _renderer.load(rootBundle, _kLumenAsset))
        .then((_) {
          if (mounted) setState(() {});
        })
        .ignore();
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    _renderer.dispose();
    super.dispose();
  }

  Future<void> _onAction(String kind) async {
    setState(() => _showFeedback = true);
    _feedbackTimer?.cancel();

    await widget.onAction(kind);

    _feedbackTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showFeedback = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _renderer.buildView(),
                  if (_showFeedback)
                    const _FeedbackOverlay(),
                ],
              ),
            ),
            _ActionBar(onAction: _onAction),
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
    return const Icon(
      Icons.favorite,
      color: Color(0xFFFF6B9D),
      size: 64,
    );
  }
}

// ---------------------------------------------------------------------------

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.onAction});

  final Future<void> Function(String kind) onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
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
