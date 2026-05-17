import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';

import 'package:display/src/data/companion/companion_poll_service.dart';
import '../companion_event_bus.dart';
import '../cubit/companion_cubit.dart';
import '../provider/petdex_provider.dart';
import '../renderer/sprite_sheet_renderer.dart';
import 'companion_qr_code.dart';

const _kLumenAsset = 'assets/companions/lumen.webp';

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

  /// Derives the Serverpod web server URL from the API server URL.
  ///
  /// Serverpod runs the web server on API port + 2 by default (8080 → 8082).
  /// This lets the companion QR use a single configured URL while hitting the
  /// correct port for the static web content.
  static String _webServerUrl(String apiUrl) {
    final uri = Uri.tryParse(apiUrl);
    if (uri == null || uri.port == 0) return apiUrl;
    return uri.replace(port: uri.port + 2).toString();
  }

  /// Maps a raw action kind string from the server to an animation state.
  static CompanionAnimationState kindToState(String kind) {
    return switch (kind) {
      'pet' => CompanionAnimationState.pet,
      'play' => CompanionAnimationState.play,
      'feed' => CompanionAnimationState.reactCelebratory,
      _ => CompanionAnimationState.idle,
    };
  }

  @override
  State<CompanionCard> createState() => _CompanionCardState();
}

class _CompanionCardState extends State<CompanionCard>
    with TickerProviderStateMixin {
  late final SpriteSheetCompanionRenderer _renderer;
  StreamSubscription<CompanionTrigger>? _busSub;
  Timer? _lookAtViewerTimer;
  bool _polling = false;

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
    try {
      final bus = context.read<CompanionEventBus>();
      _busSub = bus.events.listen(_onTrigger);
    } catch (_) {}

    if (!_polling) {
      _polling = true;
      _startPollLoop();
    }
    // _polling is never reset while this State is alive: deactivate() does not
    // clear it, so a deactivate+reactivate cycle (layout reorder) re-enters
    // didChangeDependencies with _polling=true and skips a duplicate start.
    // dispose() is never called on a reactivated State — a new State would get
    // _polling=false, but the old loop is already dead (mounted=false).
    _scheduleLookAtViewer();
  }

  void _onTrigger(CompanionTrigger trigger) {
    _renderer.triggerState(CompanionEventBus.triggerToState(trigger));
    if (mounted) setState(() {});
  }

  void _startPollLoop() {
    final cubit = context.read<CompanionCubit>();
    CompanionPollService? pollService;
    try {
      pollService = context.read<CompanionPollService>();
    } catch (_) {
      return;
    }
    _pollLoop(cubit.displayId, pollService);
  }

  Future<void> _pollLoop(
    String displayId,
    CompanionPollService pollService,
  ) async {
    while (mounted) {
      try {
        final action = await pollService.pollForEvents(
          displayId,
          timeoutSeconds: 30,
        );
        if (!mounted) break;
        if (action != null) {
          _renderer.triggerState(CompanionCard.kindToState(action.kind));
          setState(() {});
        }
      } catch (_) {
        // Network error — wait briefly before retrying to avoid hammering.
        await Future<void>.delayed(const Duration(seconds: 5));
      }
    }
  }

  void _scheduleLookAtViewer() {
    _lookAtViewerTimer?.cancel();
    final delay = Duration(
      seconds: 60 + Random().nextInt(60),
    );
    _lookAtViewerTimer = Timer(delay, () {
      if (!mounted) return;
      _renderer.triggerState(CompanionAnimationState.lookAtViewer);
      setState(() {});
      _scheduleLookAtViewer();
    });
  }

  @override
  void dispose() {
    _busSub?.cancel();
    _lookAtViewerTimer?.cancel();
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
        return _buildCard(context, state.entity, state.companionBaseUrl);
      },
    );
  }

  Widget _buildCard(
    BuildContext context,
    CompanionEntity entity,
    String serverReportedBaseUrl,
  ) {
    final tokens = LandfallActiveTheme.of(context);
    const bgColor = Color(0xFF111318);
    final borderColor = tokenColor(tokens.cardBorderColor);
    final radius = tokens.cardRadius.toDouble();

    final cubit = context.read<CompanionCubit>();
    // Prefer the server-reported LAN URL (Caddy domain on Pi, RFC1918 IP on
    // macOS/Fire-TV dev). Only fall back to the API-URL-derived web port if
    // the server returned an empty string — that path produces a loopback
    // URL on Pi which is useless for phones, but it keeps the QR rendering
    // when something has misconfigured the deployment.
    final baseUrl = serverReportedBaseUrl.isNotEmpty
        ? serverReportedBaseUrl
        : CompanionCard._webServerUrl(cubit.serverUrl);
    final separator = baseUrl.endsWith('/') ? '' : '/';
    final qrUrl = '$baseUrl${separator}c/${entity.displayId}';

    final displayName = entity.customName ?? entity.name;
    final rarityColor = _rarityColors[entity.rarityTier] ?? const Color(0xFF9E9E9E);
    final rarityLabel = _rarityLabels[entity.rarityTier] ?? '';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor, width: tokens.cardBorderWidth),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - 1),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= _kWideBreakpoint;
            return wide
                ? _WideCompanionLayout(
                    renderer: _renderer,
                    displayName: displayName,
                    rarityLabel: rarityLabel,
                    rarityColor: rarityColor,
                    evolutionStage: entity.evolutionStage,
                    assetCredit: entity.assetCredit,
                    qrUrl: qrUrl,
                  )
                : _StackedCompanionLayout(
                    renderer: _renderer,
                    displayName: displayName,
                    rarityLabel: rarityLabel,
                    rarityColor: rarityColor,
                    evolutionStage: entity.evolutionStage,
                    assetCredit: entity.assetCredit,
                    qrUrl: qrUrl,
                    radius: radius,
                  );
          },
        ),
      ),
    );
  }
}

// Wide layout threshold. Below this the card stacks vertically because there
// isn't room to host sprite + QR + meta side by side. The sprite size cap
// itself lives next to the renderer as kCompanionSpriteMaxSize so every
// surface that renders the companion picks up the same value.
const double _kWideBreakpoint = 560;

// ---------------------------------------------------------------------------

/// Side-by-side composition: sprite (capped at spec size) on the left, QR +
/// meta column on the right. Used when the card slot is wide enough to host
/// both at spec sizes without crowding.
class _WideCompanionLayout extends StatelessWidget {
  const _WideCompanionLayout({
    required this.renderer,
    required this.displayName,
    required this.rarityLabel,
    required this.rarityColor,
    required this.evolutionStage,
    required this.assetCredit,
    required this.qrUrl,
  });

  final SpriteSheetCompanionRenderer renderer;
  final String displayName;
  final String rarityLabel;
  final Color rarityColor;
  final int evolutionStage;
  final String? assetCredit;
  final String qrUrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Sprite — fills its column, but the painter clamps to spec size.
          Expanded(
            flex: 3,
            child: renderer.buildView(maxSize: kCompanionSpriteMaxSize),
          ),
          const SizedBox(width: 16),
          // Right column: QR over meta block.
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CompanionQrCode(url: qrUrl),
                const SizedBox(height: 12),
                _CompanionMetaBlock(
                  displayName: displayName,
                  rarityLabel: rarityLabel,
                  rarityColor: rarityColor,
                  evolutionStage: evolutionStage,
                  assetCredit: assetCredit,
                  alignment: CrossAxisAlignment.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

/// Vertical composition for narrow slots: sprite on top, then QR centered,
/// then a meta block. Used when the card can't fit a wide side-by-side
/// layout without crowding (slot width < _kWideBreakpoint).
class _StackedCompanionLayout extends StatelessWidget {
  const _StackedCompanionLayout({
    required this.renderer,
    required this.displayName,
    required this.rarityLabel,
    required this.rarityColor,
    required this.evolutionStage,
    required this.assetCredit,
    required this.qrUrl,
    required this.radius,
  });

  final SpriteSheetCompanionRenderer renderer;
  final String displayName;
  final String rarityLabel;
  final Color rarityColor;
  final int evolutionStage;
  final String? assetCredit;
  final String qrUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: renderer.buildView(maxSize: kCompanionSpriteMaxSize),
          ),
          const SizedBox(height: 8),
          CompanionQrCode(url: qrUrl),
          const SizedBox(height: 8),
          _CompanionMetaBlock(
            displayName: displayName,
            rarityLabel: rarityLabel,
            rarityColor: rarityColor,
            evolutionStage: evolutionStage,
            assetCredit: assetCredit,
            alignment: CrossAxisAlignment.center,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _CompanionMetaBlock extends StatelessWidget {
  const _CompanionMetaBlock({
    required this.displayName,
    required this.rarityLabel,
    required this.rarityColor,
    required this.evolutionStage,
    required this.assetCredit,
    required this.alignment,
  });

  final String displayName;
  final String rarityLabel;
  final Color rarityColor;
  final int evolutionStage;
  final String? assetCredit;
  final CrossAxisAlignment alignment;

  static const _nameColor = Colors.white;
  static const _creditColor = Color(0x99FFFFFF);

  @override
  Widget build(BuildContext context) {
    final headerAlignment = alignment == CrossAxisAlignment.center
        ? MainAxisAlignment.center
        : MainAxisAlignment.start;
    return Column(
      crossAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: headerAlignment,
          children: [
            Flexible(
              child: Text(
                displayName,
                style: LandfallTypography.cardTitle.copyWith(color: _nameColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
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
