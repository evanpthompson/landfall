import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';

import '../companion_event_bus.dart';
import '../cubit/companion_cubit.dart';
import '../provider/petdex_provider.dart';
import '../renderer/sprite_sheet_renderer.dart';

/// Asset key for the Lumen petdex sprite sheet bundled with the display app.
const _kLumenAsset = 'assets/companions/lumen.webp';

/// Rarity badge colours — intentionally desaturated to complement any theme.
const _rarityColors = <RarityTier, Color>{
  RarityTier.common: Color(0xFF9E9E9E),
  RarityTier.uncommon: Color(0xFF66BB6A),
  RarityTier.rare: Color(0xFF42A5F5),
  RarityTier.epic: Color(0xFFAB47BC),
  RarityTier.legendary: Color(0xFFFFA726),
};

const _rarityLabels = <RarityTier, String>{
  RarityTier.common: 'Common',
  RarityTier.uncommon: 'Uncommon',
  RarityTier.rare: 'Rare',
  RarityTier.epic: 'Epic',
  RarityTier.legendary: 'Legendary',
};

class CompanionCard extends StatefulWidget {
  const CompanionCard({super.key});

  @override
  State<CompanionCard> createState() => _CompanionCardState();
}

class _CompanionCardState extends State<CompanionCard>
    with TickerProviderStateMixin {
  late final SpriteSheetCompanionRenderer _renderer;
  StreamSubscription<CompanionTrigger>? _busSub;

  @override
  void initState() {
    super.initState();
    _renderer = SpriteSheetCompanionRenderer(
      provider: PetdexProvider(),
      vsync: this,
    );
    _renderer
        .load(rootBundle, _kLumenAsset)
        .then((_) { if (mounted) setState(() {}); });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _busSub?.cancel();
    // CompanionEventBus is provided as a singleton via get_it; for now we
    // tolerate its absence so the card renders even without the bus wired.
    try {
      final bus = context.read<CompanionEventBus>();
      _busSub = bus.events.listen(_onTrigger);
    } catch (_) {}
  }

  void _onTrigger(CompanionTrigger trigger) {
    _renderer.triggerState(CompanionEventBus.triggerToState(trigger));
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _busSub?.cancel();
    _renderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CompanionCubit, CompanionState>(
      builder: (context, state) {
        if (state is! CompanionLoaded) {
          return const _LoadingShell();
        }
        return _buildCard(context, state.entity);
      },
    );
  }

  Widget _buildCard(BuildContext context, CompanionEntity entity) {
    final tokens = LandfallActiveTheme.of(context);
    final bgColor = tokenColor(tokens.cardFill);
    final borderColor = tokenColor(tokens.cardBorderColor);
    final radius = tokens.cardRadius.toDouble();

    final displayName = entity.customName ?? entity.name;
    final rarityColor = _rarityColors[entity.rarityTier] ?? const Color(0xFF9E9E9E);
    final rarityLabel = _rarityLabels[entity.rarityTier] ?? '';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor, width: tokens.cardBorderWidth),
      ),
      child: Stack(
        children: [
          // Sprite — fills the card above the meta strip
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius - 1),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 72),
                child: _renderer.buildView(),
              ),
            ),
          ),

          // Bottom metadata strip — dark overlay for legibility on any sprite bg
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _MetaStrip(
              displayName: displayName,
              rarityLabel: rarityLabel,
              rarityColor: rarityColor,
              evolutionStage: entity.evolutionStage,
              assetCredit: entity.assetCredit,
              radius: radius,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _MetaStrip extends StatelessWidget {
  const _MetaStrip({
    required this.displayName,
    required this.rarityLabel,
    required this.rarityColor,
    required this.evolutionStage,
    required this.assetCredit,
    required this.radius,
  });

  final String displayName;
  final String rarityLabel;
  final Color rarityColor;
  final int evolutionStage;
  final String? assetCredit;
  final double radius;

  static const _bg = Color(0xCC0D0D0F);
  static const _nameColor = Colors.white;
  static const _creditColor = Color(0x99FFFFFF);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(radius),
          bottomRight: Radius.circular(radius),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  displayName,
                  style: LandfallTypography.cardTitle.copyWith(color: _nameColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: rarityColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: rarityColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    rarityLabel,
                    style: LandfallTypography.caption.copyWith(
                      color: rarityColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (evolutionStage > 0) ...[
                  const SizedBox(width: 8),
                  Text(
                    'Stage $evolutionStage',
                    style: LandfallTypography.caption.copyWith(color: _creditColor),
                  ),
                ],
              ],
            ),
            if (assetCredit != null) ...[
              const SizedBox(height: 2),
              Text(
                assetCredit!,
                style: LandfallTypography.caption.copyWith(color: _creditColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _LoadingShell extends StatelessWidget {
  const _LoadingShell();

  @override
  Widget build(BuildContext context) {
    final tokens = LandfallActiveTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokenColor(tokens.cardFill),
        borderRadius: BorderRadius.circular(tokens.cardRadius.toDouble()),
        border: Border.all(
          color: tokenColor(tokens.cardBorderColor),
          width: tokens.cardBorderWidth,
        ),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF4F8EF7),
          ),
        ),
      ),
    );
  }
}
