import 'dart:async';

import 'package:flutter/material.dart' hide Card;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:landfall_client/landfall_client.dart';
import 'package:landfall_shared/landfall_shared.dart';

import 'package:display/src/features/calendar/cubit/calendar_cubit.dart';
import 'package:display/src/features/calendar/cubit/calendar_state.dart';
import 'package:display/src/features/calendar/widgets/calendar_card.dart';
import 'package:display/src/features/cards/cubit/card_cubit.dart';
import 'package:display/src/features/cards/cubit/card_state.dart';
import 'package:display/src/features/cards/widgets/generic_agent_card.dart';
import 'package:display/src/features/clock/cubit/clock_cubit.dart';
import 'package:display/src/features/clock/cubit/clock_state.dart';
import 'package:display/src/features/clock/widgets/clock_card.dart';
import 'package:display/src/features/display/widgets/ambient_dim_overlay.dart';
import 'package:display/src/features/profile/cubit/dashboard_profile_cubit.dart';
import 'package:display/src/features/profile/cubit/dashboard_profile_state.dart';
import 'package:display/src/features/theme/cubit/theme_cubit.dart';
import 'package:display/src/features/theme/cubit/theme_state.dart';
import 'package:display/src/features/photo/cubit/photo_cubit.dart';
import 'package:display/src/features/photo/widgets/photo_frame_card.dart';
import 'package:display/src/features/settings/cubit/display_settings_cubit.dart';
import 'package:display/src/features/settings/screens/settings_screen.dart';
import 'package:display/src/features/ticker/cubit/ticker_cubit.dart';
import 'package:display/src/features/ticker/widgets/ticker_strip_widget.dart';
import 'package:display/src/features/weather/cubit/weather_cubit.dart';
import 'package:display/src/features/weather/cubit/weather_state.dart';
import 'package:display/src/features/weather/widgets/current_weather_card.dart';
import 'package:display/src/features/weather/widgets/forecast_strip_card.dart';
import 'package:ui_kit/ui_kit.dart';

/// The primary display surface — renders all active widgets on a grid and
/// shows agent-pushed cards in a live feed panel.
///
/// On [initState]:
///   - [DashboardProfileCubit.loadProfiles] — loads the active profile and grid
///   - [ClockCubit.startTicking] — starts the 1-second clock stream
///   - [CardCubit.fetchCards] — fetches the initial agent card set
///   - [WeatherCubit.loadWeather] — fetches initial weather data
///   - [CalendarCubit.loadEvents] — fetches initial calendar events
///   - [PhotoCubit.loadPhotos] — fetches initial photo list
///   - [DisplaySettingsCubit.loadSettings] — loads display settings
///   - Periodic refresh timers for each data source
///
/// A gear icon appears in the bottom-right corner on tap and navigates to
/// [SettingsScreen]. The [AmbientDimOverlay] dims the display on schedule.
class DisplayScreen extends StatefulWidget {
  const DisplayScreen({
    super.key,
    required this.client,
    required this.serverUrl,
  });

  final Client client;
  final String serverUrl;

  @override
  State<DisplayScreen> createState() => _DisplayScreenState();
}

class _DisplayScreenState extends State<DisplayScreen> {
  Timer? _cardRefreshTimer;
  Timer? _weatherRefreshTimer;
  Timer? _calendarRefreshTimer;
  Timer? _photoSlideshowTimer;
  Timer? _photoRefreshTimer;
  Timer? _tickerRefreshTimer;
  Timer? _gearHideTimer;
  final FocusNode _settingsFocusNode = FocusNode();

  bool _gearVisible = false;

  static const _photoSlideshowInterval = Duration(seconds: 45);
  static const _gearAutoHideDuration = Duration(seconds: 5);

  void _showGear() {
    _gearHideTimer?.cancel();
    setState(() => _gearVisible = true);
    _gearHideTimer = Timer(_gearAutoHideDuration, () {
      if (mounted) setState(() => _gearVisible = false);
    });
  }

  void _openSettings() {
    _gearHideTimer?.cancel();
    setState(() => _gearVisible = false);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(
          client: widget.client,
          serverUrl: widget.serverUrl,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    context.read<DashboardProfileCubit>().loadProfiles();
    context.read<ClockCubit>().startTicking();
    context.read<CardCubit>().fetchCards();
    context.read<WeatherCubit>().loadWeather();
    context.read<CalendarCubit>().loadEvents();
    context.read<PhotoCubit>().loadPhotos();
    context.read<DisplaySettingsCubit>().loadSettings();
    context.read<TickerCubit>().loadTicker();

    _cardRefreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        if (mounted) context.read<CardCubit>().fetchCards();
      },
    );

    _weatherRefreshTimer = Timer.periodic(
      const Duration(minutes: 10),
      (_) {
        if (mounted) context.read<WeatherCubit>().loadWeather();
      },
    );

    _calendarRefreshTimer = Timer.periodic(
      const Duration(minutes: 15),
      (_) {
        if (mounted) context.read<CalendarCubit>().loadEvents();
      },
    );

    _photoSlideshowTimer = Timer.periodic(
      _photoSlideshowInterval,
      (_) {
        if (mounted) context.read<PhotoCubit>().advance();
      },
    );

    _photoRefreshTimer = Timer.periodic(
      const Duration(minutes: 30),
      (_) {
        if (mounted) context.read<PhotoCubit>().loadPhotos();
      },
    );

    _tickerRefreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) {
        if (mounted) context.read<TickerCubit>().loadTicker();
      },
    );
  }

  @override
  void dispose() {
    _cardRefreshTimer?.cancel();
    _weatherRefreshTimer?.cancel();
    _calendarRefreshTimer?.cancel();
    _photoSlideshowTimer?.cancel();
    _photoRefreshTimer?.cancel();
    _tickerRefreshTimer?.cancel();
    _gearHideTimer?.cancel();
    _settingsFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        final tokens = themeState is ThemeLoaded
            ? themeState.active.tokens
            : LandfallThemeTokens.defaults();
        return LandfallActiveTheme(
          tokens: tokens,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _showGear,
            child: Scaffold(
              backgroundColor: tokenColor(tokens.backgroundValue),
              body: Stack(
                children: [
                  BlocBuilder<DashboardProfileCubit, DashboardProfileState>(
                    builder: (context, profileState) {
                      return switch (profileState) {
                        DashboardProfileLoading() => const _LoadingView(),
                        DashboardProfileLoaded(:final active) =>
                          _DisplayBody(layout: active.layout),
                        DashboardProfileError(:final message) =>
                          _ErrorView(message: message),
                      };
                    },
                  ),
                  // Ambient dim overlay — sits above content, ignores pointer events
                  const AmbientDimOverlay(),
                  // Ghost ticker strip — fixed at the bottom, zero height when empty
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: TickerStripWidget(),
                  ),
                  // Settings pill — appears on tap/focus, fades after 5 seconds
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: AnimatedOpacity(
                      opacity: _gearVisible ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: IgnorePointer(
                        ignoring: !_gearVisible,
                        child: _SettingsPill(
                          key: const Key('settings_pill'),
                          focusNode: _settingsFocusNode,
                          onTap: _openSettings,
                          onFocusGained: _showGear,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Settings pill button
// ---------------------------------------------------------------------------

/// A translucent pill that appears on tap and opens [SettingsScreen].
///
/// Designed to stay out of the way on an ambient display: low-opacity, dark
/// background, tight padding. Fades in/out managed by [_DisplayScreenState].
class _SettingsPill extends StatelessWidget {
  const _SettingsPill({
    super.key,
    required this.onTap,
    required this.focusNode,
    required this.onFocusGained,
  });

  final VoidCallback onTap;
  final FocusNode focusNode;
  final VoidCallback onFocusGained;

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: focusNode,
      onFocusChange: (gained) { if (gained) onFocusGained(); },
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
             event.logicalKey == LogicalKeyboardKey.space)) {
          onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D0F).withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.13),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.settings,
                size: 14,
                color: Colors.white.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 7),
              Text(
                'Settings',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading / Error
// ---------------------------------------------------------------------------

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFF4F8EF7)),
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
        'Layout error: $message',
        style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 16),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Main body — grid + agent feed
// ---------------------------------------------------------------------------

class _DisplayBody extends StatelessWidget {
  const _DisplayBody({required this.layout});

  final DashboardLayout layout;

  // Fixed width reserved for the agent card feed panel.
  static const double _feedPanelWidth = 416.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Grid takes all remaining space so no card slot is ever obscured by
        // the feed panel.
        Expanded(child: _GridView(key: const Key('dashboard_grid'), layout: layout)),
        // Feed panel: fixed width, always present so the grid width is stable
        // regardless of whether there are active agent cards.
        const SizedBox(
          width: _feedPanelWidth,
          child: _AgentCardFeed(),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Grid
// ---------------------------------------------------------------------------

class _GridView extends StatelessWidget {
  const _GridView({super.key, required this.layout});

  final DashboardLayout layout;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellW = constraints.maxWidth / layout.columns;
        final cellH = constraints.maxHeight / layout.rows;

        return Stack(
          children: layout.visibleCards.map((config) {
            final slot = config.slot;
            return Positioned(
              left: slot.column * cellW + _kGap,
              top: slot.row * cellH + _kGap,
              width: slot.columnSpan * cellW - _kGap * 2,
              height: slot.rowSpan * cellH - _kGap * 2,
              child: _widgetFor(context, config),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _widgetFor(BuildContext context, CardConfig config) {
    return switch (config.source) {
      'system.clock' => BlocBuilder<ClockCubit, ClockState>(
          builder: (_, state) => switch (state) {
            ClockTicking(:final entity) => ClockCard(
                entity: entity,
                displayConfig: config.displayConfig,
              ),
            _ => const _PlaceholderTile(source: 'system.clock'),
          },
        ),
      'system.weather' => BlocBuilder<WeatherCubit, WeatherState>(
          builder: (_, state) => switch (state) {
            WeatherLoaded(:final current) => CurrentWeatherCard(
                entity: current,
                displayConfig: config.displayConfig,
              ),
            _ => const _PlaceholderTile(source: 'system.weather'),
          },
        ),
      'system.weather.forecast' => BlocBuilder<WeatherCubit, WeatherState>(
          builder: (_, state) => switch (state) {
            WeatherLoaded(:final forecast) => ForecastStripCard(
                forecast: forecast,
                displayConfig: config.displayConfig,
              ),
            _ => const _PlaceholderTile(source: 'system.weather.forecast'),
          },
        ),
      'system.calendar' => BlocBuilder<CalendarCubit, CalendarState>(
          builder: (_, state) => switch (state) {
            CalendarLoaded(:final events) => CalendarCard(
                events: events,
                displayConfig: config.displayConfig,
              ),
            _ => const _PlaceholderTile(source: 'system.calendar'),
          },
        ),
      'system.photos' => const PhotoFrameCard(),
      _ => _PlaceholderTile(source: config.source),
    };
  }

  static const double _kGap = 8.0;
}

// ---------------------------------------------------------------------------
// Agent card feed
// ---------------------------------------------------------------------------

class _AgentCardFeed extends StatelessWidget {
  const _AgentCardFeed();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CardCubit, CardState>(
      builder: (context, state) {
        if (state is! CardLoaded || state.cards.isEmpty) {
          return const SizedBox.shrink();
        }

        final tokens = LandfallActiveTheme.of(context);

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
          itemCount: state.cards.length,
          separatorBuilder: (context, idx) => const SizedBox(height: 12),
          itemBuilder: (_, i) => GenericAgentCard(
            card: state.cards[i],
            tokens: tokens,
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Placeholder tile
// ---------------------------------------------------------------------------

class _PlaceholderTile extends StatelessWidget {
  const _PlaceholderTile({required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _tileColor(source).withValues(alpha: 0.08),
        border: Border.all(
          color: _tileColor(source).withValues(alpha: 0.3),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          source,
          style: TextStyle(
            color: _tileColor(source).withValues(alpha: 0.5),
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  static Color _tileColor(String source) {
    if (source.startsWith('system.clock')) return const Color(0xFF4A9EFF);
    if (source.startsWith('system.weather')) return const Color(0xFF50C878);
    if (source.startsWith('system.calendar')) return const Color(0xFFFF9500);
    if (source.startsWith('system.photos')) return const Color(0xFFBF5AF2);
    return const Color(0xFF888888);
  }
}
