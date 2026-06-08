import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:landfall_client/landfall_client.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';

import 'package:display/src/widgets/landfall_text_field.dart';
import 'package:display/src/features/companion/companion_url.dart';
import 'package:display/src/features/companion/cubit/companion_cubit.dart';
import 'package:display/src/features/companion/widgets/companion_qr_code.dart';
import 'package:display/src/features/license/cubit/license_cubit.dart';
import 'package:display/src/features/license/screens/license_screen.dart';
import 'package:display/src/features/photo/cubit/photo_cubit.dart';
import 'package:display/src/features/photo/screens/photo_sources_screen.dart';
import 'package:display/src/features/server/screens/change_server_screen.dart';
import 'package:display/src/features/settings/cubit/display_settings_cubit.dart';
import 'package:display/src/features/settings/widgets/layout_tab_view.dart';
import 'package:display/src/features/settings/widgets/accounts_tab_view.dart';
import 'package:display/src/features/settings/widgets/section_header.dart';
import 'package:display/src/features/settings/widgets/themes_tab_view.dart';

/// Full-screen settings panel pushed over [DisplayScreen].
///
/// Sections:
///   Display  — dim schedule + level, location name override
///   Accounts — list of linked calendar/photo credentials + OAuth connect URLs
///   Layout   — drag-to-move grid editor
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.client,
    required this.serverUrl,
    this.leanback = false,
  });

  final Client client;
  final String serverUrl;

  /// Test seam for leanback detection. When true, the Layout tab shows a
  /// remote-editing placeholder instead of the pointer-only LayoutEditor.
  final bool leanback;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  /// True while the leanback layout editor has a card in move mode.
  bool _lbEditorInMoveMode = false;

  /// Cancels an in-progress leanback move; set by the editor when move starts.
  VoidCallback? _cancelLbEditorMove;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
    context.read<LicenseCubit>().loadStatus();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // Back while leanback editor is moving a card → cancel the move.
        // The editor's cancelLbMove fires onMoveModeChanged(false) which
        // sets _lbEditorInMoveMode back to false via the callback above.
        if (_lbEditorInMoveMode) {
          _cancelLbEditorMove?.call();
          return;
        }
        // Dismiss the soft keyboard on Back if a text field has focus.
        // viewInsets.bottom is unreliable on Fire TV (the IME runs as a
        // separate activity and does not push layout insets), so check the
        // focus tree directly.
        final focus = FocusManager.instance.primaryFocus;
        final textFieldFocused = focus?.context?.widget is EditableText;
        if (MediaQuery.of(context).viewInsets.bottom > 0 || textFieldFocused) {
          FocusManager.instance.primaryFocus?.unfocus();
          return;
        }
        Navigator.of(context).pop();
      },
      child: Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.arrowDown): NextFocusIntent(),
          SingleActivator(LogicalKeyboardKey.arrowUp): PreviousFocusIntent(),
        },
        child: FocusTraversalGroup(
          policy: ReadingOrderTraversalPolicy(),
          child: Scaffold(
            backgroundColor: LandfallColors.background,
            appBar: AppBar(
              backgroundColor: LandfallColors.surface,
              foregroundColor: LandfallColors.textPrimary,
              elevation: 0,
              scrolledUnderElevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, size: 20),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Back to display',
                color: LandfallColors.textSecondary,
              ),
              title: const Text(
                'Settings',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.1,
                ),
              ),
              bottom: TabBar(
                controller: _tabs,
                labelColor: LandfallColors.accent,
                unselectedLabelColor: LandfallColors.textSecondary,
                indicatorColor: LandfallColors.accent,
                indicatorWeight: 2,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
                tabs: const [
                  Tab(text: 'Display'),
                  Tab(text: 'Accounts'),
                  Tab(text: 'Layout'),
                  Tab(text: 'Themes'),
                  Tab(text: 'License'),
                ],
              ),
            ),
            body: TabBarView(
              controller: _tabs,
              children: [
                _DisplayTab(serverUrl: widget.serverUrl, leanback: widget.leanback),
                AccountsTabView(
                  leanback: widget.leanback,
                  onLoad: () async {
                    final credentials =
                        await widget.client.settings.getLinkedCredentials();
                    final userId =
                        await widget.client.settings.getMyAuthUserId();
                    return (credentials, userId);
                  },
                  serverUrl: widget.serverUrl,
                  onListKeys: (token) =>
                      widget.client.apiKey.listKeys(token),
                  onGenerateKey: (name, token) =>
                      widget.client.apiKey.generateKey(name, token),
                  onRevokeKey: (id, token) =>
                      widget.client.apiKey.revokeKey(id, token),
                ),
                LayoutTabView(
                  leanback: widget.leanback,
                  onMoveModeChanged: (v) =>
                      setState(() => _lbEditorInMoveMode = v),
                  onCancelMoveRegistered: (cancel) =>
                      _cancelLbEditorMove = cancel,
                ),
                const ThemesTabView(),
                LicenseTab(leanback: widget.leanback),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Display tab
// ─────────────────────────────────────────────────────────────────────────────

class _DisplayTab extends StatelessWidget {
  const _DisplayTab({required this.serverUrl, required this.leanback});

  final String serverUrl;
  final bool leanback;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        SectionHeader('Remote Control'),
        const SizedBox(height: 12),
        _RemoteControlTile(),
        const SizedBox(height: 24),
        BlocBuilder<DisplaySettingsCubit, DisplaySettingsState>(
          builder: (context, state) {
            if (state is! DisplaySettingsLoaded) {
              return const Center(child: CircularProgressIndicator());
            }
            return _DisplayFormBody(
              settings: state.settings,
              serverUrl: serverUrl,
              leanback: leanback,
            );
          },
        ),
      ],
    );
  }
}

class _DisplayFormBody extends StatefulWidget {
  const _DisplayFormBody({
    required this.settings,
    required this.serverUrl,
    required this.leanback,
  });

  final DisplaySettings settings;
  final String serverUrl;
  final bool leanback;

  @override
  State<_DisplayFormBody> createState() => _DisplayFormBodyState();
}

class _DisplayFormBodyState extends State<_DisplayFormBody> {
  late bool _dimEnabled;
  late int _dimStartHour;
  late int _dimEndHour;
  late double _dimLevel;
  late TextEditingController _locationCtrl;

  @override
  void initState() {
    super.initState();
    _dimEnabled = widget.settings.dimEnabled;
    _dimStartHour = widget.settings.dimStartHour;
    _dimEndHour = widget.settings.dimEndHour;
    _dimLevel = widget.settings.dimLevel;
    _locationCtrl =
        TextEditingController(text: widget.settings.locationName);
  }

  @override
  void dispose() {
    _locationCtrl.dispose();
    super.dispose();
  }

  void _save() {
    context.read<DisplaySettingsCubit>().updateSettings(
          DisplaySettings(
            dimEnabled: _dimEnabled,
            dimStartHour: _dimStartHour,
            dimEndHour: _dimEndHour,
            dimLevel: _dimLevel,
            locationName: _locationCtrl.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SectionHeader('Server'),
        const SizedBox(height: 12),
        _NavTile(
          icon: Icons.dns_outlined,
          title: 'Server address',
          subtitle: widget.serverUrl.isEmpty ? 'Not set' : widget.serverUrl,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ChangeServerScreen(currentUrl: widget.serverUrl),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SectionHeader('Ambient Dim'),
        const SizedBox(height: 12),
        LandfallFocusable(
          borderRadius: BorderRadius.circular(4),
          child: SwitchListTile(
            title: const Text('Enable dim schedule',
                style: TextStyle(color: LandfallColors.textPrimary)),
            subtitle: const Text('Dims the display during the configured hours',
                style: TextStyle(color: LandfallColors.textSecondary)),
            value: _dimEnabled,
            activeThumbColor: LandfallColors.accent,
            onChanged: (v) => setState(() {
              _dimEnabled = v;
              _save();
            }),
          ),
        ),
        const SizedBox(height: 8),
        _HourRow(
          label: 'Dim at',
          hour: _dimStartHour,
          enabled: _dimEnabled,
          onChanged: (h) => setState(() {
            _dimStartHour = h;
            _save();
          }),
        ),
        const SizedBox(height: 8),
        _HourRow(
          label: 'Brighten at',
          hour: _dimEndHour,
          enabled: _dimEnabled,
          onChanged: (h) => setState(() {
            _dimEndHour = h;
            _save();
          }),
        ),
        const SizedBox(height: 16),
        Text(
          'Dim level  ${((_dimLevel) * 100).round()}%',
          style: const TextStyle(color: LandfallColors.textSecondary),
        ),
        Slider(
          value: _dimLevel,
          min: 0.1,
          max: 1.0,
          divisions: 18,
          activeColor: _dimEnabled ? LandfallColors.accent : LandfallColors.textTertiary,
          inactiveColor: LandfallColors.divider,
          onChanged: _dimEnabled
              ? (v) => setState(() {
                    _dimLevel = v;
                    _save();
                  })
              : null,
        ),
        const SizedBox(height: 24),
        SectionHeader('Location'),
        const SizedBox(height: 12),
        LandfallTextField(
          controller: _locationCtrl,
          leanback: widget.leanback,
          style: const TextStyle(color: LandfallColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'e.g. Seattle, WA',
            hintStyle: const TextStyle(color: LandfallColors.textTertiary),
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
          onSubmitted: (_) => _save(),
        ),
        const SizedBox(height: 8),
        Text(
          'Overrides the location label in the weather card.',
          style: const TextStyle(
              color: LandfallColors.textTertiary, fontSize: 12),
        ),
        const SizedBox(height: 24),
        SectionHeader('Photos'),
        const SizedBox(height: 12),
        _NavTile(
          icon: Icons.photo_library_outlined,
          title: 'Photo Sources',
          subtitle: 'Manage where slideshow photos are loaded from',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => BlocProvider.value(
                value: context.read<PhotoCubit>(),
                child: const PhotoSourcesScreen(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Remote Control tile — shows the companion app QR + URL in the Display tab.
// ---------------------------------------------------------------------------

class _RemoteControlTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CompanionCubit, CompanionState>(
      builder: (context, state) {
        if (state is! CompanionLoaded) {
          return const SizedBox.shrink();
        }

        final cubit = context.read<CompanionCubit>();
        final baseUrl = state.companionBaseUrl.isNotEmpty
            ? state.companionBaseUrl
            : companionWebServerUrl(cubit.serverUrl);
        final url = buildCompanionUrl(baseUrl, cubit.displayId);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scan from your phone to manage this display remotely.',
              style: const TextStyle(
                color: LandfallColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            CompanionQrCode(url: url, targetSize: 160),
            const SizedBox(height: 12),
            Text(
              url,
              style: const TextStyle(
                color: LandfallColors.textSecondary,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HourRow extends StatelessWidget {
  const _HourRow({
    required this.label,
    required this.hour,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final int hour;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              color: enabled
                  ? LandfallColors.textPrimary
                  : LandfallColors.textTertiary,
            ),
          ),
        ),
        LandfallFocusable(
          borderRadius: BorderRadius.circular(4),
          child: DropdownButton<int>(
            value: hour,
            dropdownColor: LandfallColors.surfaceElevated,
            style: TextStyle(
              color: enabled
                  ? LandfallColors.textPrimary
                  : LandfallColors.textTertiary,
            ),
            underline: const SizedBox.shrink(),
            items: List.generate(24, (i) {
              final label = _hourLabel(i);
              return DropdownMenuItem(value: i, child: Text(label));
            }),
            onChanged: enabled ? (v) => onChanged(v!) : null,
          ),
        ),
      ],
    );
  }

  static String _hourLabel(int h) {
    if (h == 0) return '12:00 AM';
    if (h == 12) return '12:00 PM';
    return h < 12 ? '$h:00 AM' : '${h - 12}:00 PM';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

class _NavTile extends StatelessWidget {
  const _NavTile({
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
    return LandfallFocusable(
      borderRadius: BorderRadius.circular(8),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: LandfallColors.accent, size: 22),
        title: Text(title,
            style: const TextStyle(color: LandfallColors.textPrimary)),
        subtitle: Text(subtitle,
            style: const TextStyle(
                color: LandfallColors.textSecondary, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right,
            color: LandfallColors.textTertiary, size: 18),
        onTap: onTap,
      ),
    );
  }
}
