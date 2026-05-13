import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

import 'package:display/src/data/companion/companion_poll_service.dart';
import '../companion_event_bus.dart';
import '../cubit/companion_cubit.dart';
import '../provider/petdex_provider.dart';
import '../renderer/sprite_sheet_renderer.dart';

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
    // TODO: multiple poll loops can accumulate if the widget is deactivated and
    // reactivated without dispose() being called (e.g. layout reordering). The
    // _polling flag only guards the first start; investigate whether
    // deactivate() + reactivate() can bypass it and add a guard or cancel the
    // previous loop future before starting a new one.
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
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius - 1),
              child: _renderer.buildView(),
            ),
          ),

          // Bottom metadata strip — QR lives inside it now
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
              qrUrl: qrUrl,
              radius: radius,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _QrWidget extends StatelessWidget {
  const _QrWidget({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Size the QR to the available height, clamped to a readable range.
        final size = constraints.maxHeight.isFinite
            ? constraints.maxHeight.clamp(48.0, 96.0)
            : 64.0;
        return Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5),
          ),
          child: QrImageView(
            data: url,
            semanticsLabel: url,
            version: QrVersions.auto,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: Color(0xFF111318),
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: Color(0xFF111318),
            ),
          ),
        );
      },
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
    required this.qrUrl,
    required this.radius,
  });

  final String displayName;
  final String rarityLabel;
  final Color rarityColor;
  final int evolutionStage;
  final String? assetCredit;
  final String qrUrl;
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
        padding: const EdgeInsets.fromLTRB(14, 8, 10, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left: name, rarity, credit.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
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
              ),
            ),

            const SizedBox(width: 10),

            // Right: QR code, sized to match strip height naturally.
            _QrWidget(url: qrUrl),
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
