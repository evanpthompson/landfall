import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:landfall_client/landfall_client.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';

import 'package:display/src/features/license/cubit/license_cubit.dart';
import 'package:display/src/features/license/screens/license_screen.dart';
import 'package:display/src/features/license/screens/pack_browser_screen.dart';
import 'package:display/src/features/profile/cubit/dashboard_profile_cubit.dart';
import 'package:display/src/features/theme/cubit/theme_cubit.dart';
import 'package:display/src/features/theme/cubit/theme_state.dart';
import 'package:display/src/features/theme/screens/theme_browser_screen.dart';
import 'package:display/src/features/profile/cubit/dashboard_profile_state.dart';
import 'package:display/src/features/profile/screens/profile_manager_screen.dart';
import 'package:display/src/features/profile/widgets/profile_switcher.dart';
import 'package:display/src/features/settings/cubit/display_settings_cubit.dart';
import 'package:display/src/features/settings/widgets/agent_keys_section.dart';
import 'package:display/src/features/settings/widgets/layout_editor.dart';

/// Full-screen settings panel pushed over [DisplayScreen].
///
/// Sections:
///   Display  — dim schedule + level, location name override
///   Accounts — list of linked calendar/photo credentials + OAuth connect URLs
///   Layout   — drag-to-move grid editor
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.client, required this.serverUrl});

  final Client client;
  final String serverUrl;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

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
    return Scaffold(
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
          _DisplayTab(serverUrl: widget.serverUrl),
          _AccountsTab(client: widget.client, serverUrl: widget.serverUrl),
          const _LayoutTab(),
          const _ThemesTab(),
          _LicenseTab(client: widget.client),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Display tab
// ─────────────────────────────────────────────────────────────────────────────

class _DisplayTab extends StatelessWidget {
  const _DisplayTab({required this.serverUrl});

  final String serverUrl;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DisplaySettingsCubit, DisplaySettingsState>(
      builder: (context, state) {
        if (state is! DisplaySettingsLoaded) {
          return const Center(child: CircularProgressIndicator());
        }
        return _DisplayForm(settings: state.settings, serverUrl: serverUrl);
      },
    );
  }
}

class _DisplayForm extends StatefulWidget {
  const _DisplayForm({required this.settings, required this.serverUrl});

  final DisplaySettings settings;
  final String serverUrl;

  @override
  State<_DisplayForm> createState() => _DisplayFormState();
}

class _DisplayFormState extends State<_DisplayForm> {
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
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _SectionHeader('Ambient Dim'),
        const SizedBox(height: 12),
        SwitchListTile(
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
        _SectionHeader('Location'),
        const SizedBox(height: 12),
        TextField(
          controller: _locationCtrl,
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
          onEditingComplete: _save,
        ),
        const SizedBox(height: 8),
        Text(
          'Overrides the location label in the weather card.',
          style: const TextStyle(
              color: LandfallColors.textTertiary, fontSize: 12),
        ),
      ],
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
        DropdownButton<int>(
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
// Accounts tab
// ─────────────────────────────────────────────────────────────────────────────

class _AccountsTab extends StatefulWidget {
  const _AccountsTab({required this.client, required this.serverUrl});

  final Client client;
  final String serverUrl;

  @override
  State<_AccountsTab> createState() => _AccountsTabState();
}

class _AccountsTabState extends State<_AccountsTab> {
  late Future<(List<LinkedCredentialSummary>, String)> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<(List<LinkedCredentialSummary>, String)> _load() async {
    final credentials = await widget.client.settings.getLinkedCredentials();
    final userId = await widget.client.settings.getMyAuthUserId();
    return (credentials, userId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Could not load accounts.',
              style: const TextStyle(color: LandfallColors.textSecondary),
            ),
          );
        }
        final (credentials, userId) = snapshot.data!;
        return _AccountsList(
          credentials: credentials,
          userId: userId,
          serverUrl: widget.serverUrl,
          onRefresh: () => setState(() => _future = _load()),
          client: widget.client,
        );
      },
    );
  }
}

class _AccountsList extends StatelessWidget {
  const _AccountsList({
    required this.credentials,
    required this.userId,
    required this.serverUrl,
    required this.onRefresh,
    required this.client,
  });

  final List<LinkedCredentialSummary> credentials;
  final String userId;
  final String serverUrl;
  final VoidCallback onRefresh;
  final Client client;

  @override
  Widget build(BuildContext context) {
    final base = serverUrl.endsWith('/') ? serverUrl : '$serverUrl/';
    final googleUrl =
        '${base}calendar/oauth/start?authUserId=$userId';
    final microsoftUrl =
        '${base}calendar/microsoft/oauth/start?authUserId=$userId';

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _SectionHeader('Connected Accounts'),
        const SizedBox(height: 12),
        if (credentials.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'No accounts connected yet.',
              style: TextStyle(color: LandfallColors.textSecondary),
            ),
          )
        else
          ...credentials.map((c) => _CredentialTile(credential: c)),
        const SizedBox(height: 32),
        _SectionHeader('Connect an Account'),
        const SizedBox(height: 4),
        const Text(
          'Visit the URL below from any device on the same network to link a calendar account.',
          style: TextStyle(color: LandfallColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 16),
        _ConnectUrlTile(
          provider: 'Google Calendar',
          color: const Color(0xFF4285F4),
          url: googleUrl,
        ),
        const SizedBox(height: 12),
        _ConnectUrlTile(
          provider: 'Microsoft Calendar',
          color: const Color(0xFF00A4EF),
          url: microsoftUrl,
        ),
        const SizedBox(height: 24),
        TextButton.icon(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Refresh'),
          style: TextButton.styleFrom(
            foregroundColor: LandfallColors.textSecondary,
          ),
        ),
        const SizedBox(height: 32),
        AgentKeysSection(
          onListKeys: (token) => client.apiKey.listKeys(token),
          onGenerateKey: (name, token) =>
              client.apiKey.generateKey(name, token),
          onRevokeKey: (id, token) => client.apiKey.revokeKey(id, token),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _CredentialTile extends StatelessWidget {
  const _CredentialTile({required this.credential});

  final LinkedCredentialSummary credential;

  @override
  Widget build(BuildContext context) {
    final color = credential.provider == 'google'
        ? const Color(0xFF4285F4)
        : const Color(0xFF00A4EF);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Text(
          credential.provider[0].toUpperCase(),
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(
        credential.providerEmail,
        style: const TextStyle(color: LandfallColors.textPrimary),
      ),
      subtitle: Text(
        '${_providerLabel(credential.provider)} · ${credential.isActive ? 'Connected' : 'Disconnected'}',
        style: const TextStyle(
            color: LandfallColors.textSecondary, fontSize: 12),
      ),
      trailing: credential.isActive
          ? const Icon(Icons.check_circle_outline,
              color: LandfallColors.success, size: 18)
          : const Icon(Icons.error_outline,
              color: LandfallColors.warning, size: 18),
    );
  }

  static String _providerLabel(String provider) =>
      provider == 'google' ? 'Google' : 'Microsoft';
}

class _ConnectUrlTile extends StatelessWidget {
  const _ConnectUrlTile({
    required this.provider,
    required this.color,
    required this.url,
  });

  final String provider;
  final Color color;
  final String url;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: LandfallColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LandfallColors.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 10,
                  backgroundColor: color.withValues(alpha: 0.15),
                  child: Text(
                    provider[0],
                    style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  provider,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SelectableText(
              url,
              style: const TextStyle(
                color: LandfallColors.textSecondary,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _copyUrl(context),
                icon: const Icon(Icons.copy, size: 14),
                label: const Text('Copy URL'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: color,
                  side: BorderSide(color: color.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyUrl(BuildContext context) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('URL copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Layout tab
// ─────────────────────────────────────────────────────────────────────────────

class _LayoutTab extends StatelessWidget {
  const _LayoutTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardProfileCubit, DashboardProfileState>(
      builder: (context, state) {
        if (state is! DashboardProfileLoaded) {
          return const Center(child: CircularProgressIndicator());
        }
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader('Profile'),
              const SizedBox(height: 12),
              Row(
                children: [
                  ProfileSwitcher(
                    profiles: state.profiles,
                    activeId: state.active.id,
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ProfileManagerScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.tune, size: 16),
                    label: const Text('Manage profiles'),
                    style: TextButton.styleFrom(
                      foregroundColor: LandfallColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _SectionHeader(
                  'Tap to select  •  drag to move  •  drag corner to resize'),
              const SizedBox(height: 16),
              Expanded(
                child: LayoutEditor(
                  layout: state.active.layout,
                  onLayoutChanged: (updated) =>
                      context.read<DashboardProfileCubit>().saveActiveLayout(updated),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Themes tab
// ─────────────────────────────────────────────────────────────────────────────

class _ThemesTab extends StatelessWidget {
  const _ThemesTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _SectionHeader('Active Theme'),
            const SizedBox(height: 12),
            _ActiveThemeTile(state: state),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ThemeBrowserScreen(),
                  ),
                ),
                icon: const Icon(Icons.palette_outlined, size: 18),
                label: const Text('Browse Themes'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: LandfallColors.accent,
                  side: const BorderSide(color: LandfallColors.accent),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ActiveThemeTile extends StatelessWidget {
  const _ActiveThemeTile({required this.state});

  final ThemeState state;

  @override
  Widget build(BuildContext context) {
    if (state is! ThemeLoaded) {
      return const SizedBox(
        height: 56,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final theme = (state as ThemeLoaded).active;
    final accent = _parseHex(theme.tokens.colorAccent);
    final bg = _parseHex(theme.tokens.backgroundValue);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: LandfallColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LandfallColors.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 40,
                height: 40,
                child: Stack(
                  children: [
                    ColoredBox(color: bg, child: const SizedBox.expand()),
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      width: 6,
                      child: ColoredBox(color: accent),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    theme.name,
                    style: const TextStyle(
                      color: LandfallColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (theme.author != null)
                    Text(
                      theme.author!,
                      style: const TextStyle(
                        color: LandfallColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.check_circle,
              color: LandfallColors.accent,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  static Color _parseHex(String hex) {
    final clean = hex.replaceFirst('#', '');
    final value = int.tryParse(
      clean.length == 6 ? 'FF$clean' : clean,
      radix: 16,
    );
    return Color(value ?? 0xFF1a1a1a);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// License tab
// ─────────────────────────────────────────────────────────────────────────────

class _LicenseTab extends StatelessWidget {
  const _LicenseTab({required this.client});

  final Client client;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: const LicenseTab()),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PackBrowserScreen(
                    client: client,
                    licenseCubit: context.read<LicenseCubit>(),
                  ),
                ),
              ),
              icon: const Icon(Icons.extension_outlined, size: 18),
              label: const Text('Browse Integration Packs'),
              style: OutlinedButton.styleFrom(
                foregroundColor: LandfallColors.accent,
                side: const BorderSide(color: LandfallColors.accent),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

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
