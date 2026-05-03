import 'package:flutter/material.dart' hide Card;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ui_kit/ui_kit.dart';

import 'package:display/src/features/cards/cubit/card_cubit.dart';
import 'url_safety.dart';

/// Renders a single [CardAction] as a focusable button.
///
/// Action dispatch:
///   - [CardActionType.dismiss]  → calls [CardCubit.dismissCard]
///   - [CardActionType.openUrl]  → launches [action.payload] in system browser
///   - [CardActionType.webhook]  → HTTP POST to [action.payload] (fire-and-forget)
///   - [CardActionType.openSettings] → (handled by parent; no-op here)
///
/// When [action.requireConfirm] is true, an [AlertDialog] is shown first.
class CardActionButton extends StatelessWidget {
  const CardActionButton({
    super.key,
    required this.card,
    required this.action,
  });

  final Card card;
  final CardAction action;

  Future<void> _execute(BuildContext context) async {
    switch (action.type) {
      case CardActionType.dismiss:
        context.read<CardCubit>().dismissCard(card.id);

      case CardActionType.openUrl:
        final url = action.payload;
        if (url != null && isAllowedBrowserUrl(url)) {
          final uri = Uri.tryParse(url);
          if (uri != null) await launchUrl(uri);
        }

      case CardActionType.webhook:
        // Fire-and-forget HTTP POST. Errors are silent — the agent's
        // server-side handler is responsible for retries.
        final url = action.payload;
        if (url != null && isAllowedWebhookUrl(url)) _fireWebhook(url);

      case CardActionType.openSettings:
        // Opening settings is a navigation concern handled by the parent
        // screen. CardActionButton emits nothing — the parent wires this up
        // if needed via a callback.
        break;
    }
  }

  void _fireWebhook(String url) {
    // Intentionally not awaited — webhook delivery is best-effort from client.
    // Agent is responsible for any retry / confirmation logic.
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    launchUrl(uri, mode: LaunchMode.externalNonBrowserApplication)
        .catchError((_) => false);
  }

  void _handleTap(BuildContext context) {
    if (action.requireConfirm) {
      showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: LandfallColors.surface,
          title: Text(
            action.label,
            style: const TextStyle(color: LandfallColors.textPrimary),
          ),
          content: const Text(
            'Are you sure?',
            style: TextStyle(color: LandfallColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: LandfallColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
                _execute(context);
              },
              child: Text(
                'Confirm',
                style: const TextStyle(color: LandfallColors.accent),
              ),
            ),
          ],
        ),
      );
    } else {
      _execute(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      focusNode: FocusNode(),
      onPressed: () => _handleTap(context),
      style: OutlinedButton.styleFrom(
        foregroundColor: LandfallColors.accent,
        side: const BorderSide(color: LandfallColors.cardBorder),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      child: Text(action.label, style: const TextStyle(fontSize: 12)),
    );
  }
}
