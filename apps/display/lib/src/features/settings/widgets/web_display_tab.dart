import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:landfall_client/landfall_client.dart' as lf;
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';

import 'section_header.dart';

class WebDisplayTab extends StatefulWidget {
  const WebDisplayTab({
    super.key,
    required this.displayId,
    required this.onLoad,
    required this.onSave,
    required this.onPush,
  });

  final String displayId;
  final Future<lf.RemoteDisplaySettings?> Function() onLoad;
  final Future<void> Function(lf.RemoteDisplaySettings settings) onSave;
  final void Function(String action) onPush;

  @override
  State<WebDisplayTab> createState() => _WebDisplayTabState();
}

// ── State ─────────────────────────────────────────────────────────────────────

sealed class _TabState {}

class _Loading extends _TabState {}

class _Loaded extends _TabState {
  _Loaded(this.settings);
  final lf.RemoteDisplaySettings settings;
}

class _Error extends _TabState {
  _Error(this.message);
  final String message;
}

// ── Photo source type (for the segmented picker) ──────────────────────────────

enum _SourceType { server, network }

// ── State ─────────────────────────────────────────────────────────────────────

class _WebDisplayTabState extends State<WebDisplayTab> {
  _TabState _state = _Loading();

  // Form fields
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _locationCtrl;
  late bool _dimEnabled;
  late int _dimStartHour;
  late int _dimEndHour;
  late double _dimLevel;

  // Photo source
  _SourceType? _sourceType; // null = read-only (local_directory / unknown)
  PhotoSource? _readOnlySource;
  late final TextEditingController _networkUrlsCtrl;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _locationCtrl = TextEditingController();
    _networkUrlsCtrl = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _locationCtrl.dispose();
    _networkUrlsCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _state = _Loading());
    try {
      final remote = await widget.onLoad();
      if (!mounted) return;
      _populate(remote);
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = _Error('Failed to load display settings.'));
    }
  }

  void _populate(lf.RemoteDisplaySettings? remote) {
    final s = remote ??
        lf.RemoteDisplaySettings(
          displayId: widget.displayId,
          updatedAt: DateTime.now().toUtc(),
        );

    _locationCtrl.text = s.locationName;
    _dimEnabled = s.dimEnabled;
    _dimStartHour = s.dimStartHour;
    _dimEndHour = s.dimEndHour;
    _dimLevel = s.dimLevel;

    final source = _parseSource(s.photoSourceJson);
    switch (source) {
      case PhotoSourceServerpod():
        _sourceType = _SourceType.server;
        _readOnlySource = null;
      case PhotoSourceNetwork(:final urls):
        _sourceType = _SourceType.network;
        _networkUrlsCtrl.text = urls.join('\n');
        _readOnlySource = null;
      case null:
        _sourceType = _SourceType.server;
        _readOnlySource = null;
      default:
        // local_directory, s3, or unknown — read-only
        _sourceType = null;
        _readOnlySource = source;
    }

    setState(() => _state = _Loaded(s));
  }

  static PhotoSource? _parseSource(String? json) {
    if (json == null || json.isEmpty) return null;
    try {
      return PhotoSource.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  bool get _canSave {
    if (_saving) return false;
    if (_sourceType == _SourceType.network) {
      return _networkUrlsCtrl.text.trim().isNotEmpty;
    }
    return true;
  }

  lf.RemoteDisplaySettings _buildSettings(lf.RemoteDisplaySettings base) {
    final PhotoSource source = switch (_sourceType) {
      _SourceType.server => const PhotoSourceServerpod(),
      _SourceType.network => PhotoSourceNetwork(
          urls: _networkUrlsCtrl.text
              .split('\n')
              .map((u) => u.trim())
              .where((u) => u.isNotEmpty)
              .toList(),
        ),
      null => _readOnlySource ?? const PhotoSourceServerpod(),
    };

    return lf.RemoteDisplaySettings(
      id: base.id,
      displayId: base.displayId,
      dimEnabled: _dimEnabled,
      dimStartHour: _dimStartHour,
      dimEndHour: _dimEndHour,
      dimLevel: _dimLevel,
      locationName: _locationCtrl.text.trim(),
      photoSourceJson: jsonEncode(source.toJson()),
      updatedAt: DateTime.now().toUtc(),
    );
  }

  Future<void> _save() async {
    final loaded = _state;
    if (loaded is! _Loaded) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    try {
      await widget.onSave(_buildSettings(loaded.settings));
      widget.onPush('settings.changed');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved'),
            backgroundColor: Color(0xFF2A7A4F),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: const Color(0xFF7A2A2A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return switch (_state) {
      _Loading() => const Center(child: CircularProgressIndicator()),
      _Error(:final message) => _ErrorBody(message: message, onRetry: _load),
      _Loaded() => _FormBody(
          formKey: _formKey,
          locationCtrl: _locationCtrl,
          dimEnabled: _dimEnabled,
          dimStartHour: _dimStartHour,
          dimEndHour: _dimEndHour,
          dimLevel: _dimLevel,
          sourceType: _sourceType,
          readOnlySource: _readOnlySource,
          networkUrlsCtrl: _networkUrlsCtrl,
          canSave: _canSave,
          saving: _saving,
          onDimEnabledChanged: (v) => setState(() => _dimEnabled = v),
          onDimStartHourChanged: (v) => setState(() => _dimStartHour = v),
          onDimEndHourChanged: (v) => setState(() => _dimEndHour = v),
          onDimLevelChanged: (v) => setState(() => _dimLevel = v),
          onSourceTypeChanged: (v) => setState(() => _sourceType = v),
          onNetworkUrlsChanged: (_) => setState(() {}),
          onSave: _save,
        ),
    };
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message,
              style: const TextStyle(color: LandfallColors.textSecondary)),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _FormBody extends StatelessWidget {
  const _FormBody({
    required this.formKey,
    required this.locationCtrl,
    required this.dimEnabled,
    required this.dimStartHour,
    required this.dimEndHour,
    required this.dimLevel,
    required this.sourceType,
    required this.readOnlySource,
    required this.networkUrlsCtrl,
    required this.canSave,
    required this.saving,
    required this.onDimEnabledChanged,
    required this.onDimStartHourChanged,
    required this.onDimEndHourChanged,
    required this.onDimLevelChanged,
    required this.onSourceTypeChanged,
    required this.onNetworkUrlsChanged,
    required this.onSave,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController locationCtrl;
  final bool dimEnabled;
  final int dimStartHour;
  final int dimEndHour;
  final double dimLevel;
  final _SourceType? sourceType;
  final PhotoSource? readOnlySource;
  final TextEditingController networkUrlsCtrl;
  final bool canSave;
  final bool saving;
  final ValueChanged<bool> onDimEnabledChanged;
  final ValueChanged<int> onDimStartHourChanged;
  final ValueChanged<int> onDimEndHourChanged;
  final ValueChanged<double> onDimLevelChanged;
  final ValueChanged<_SourceType> onSourceTypeChanged;
  final ValueChanged<String> onNetworkUrlsChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          // ── Location ──────────────────────────────────────────────────────
          const SectionHeader('Location'),
          const SizedBox(height: 8),
          TextFormField(
            controller: locationCtrl,
            style: const TextStyle(color: LandfallColors.textPrimary),
            decoration: const InputDecoration(
              hintText: 'City, region — shown on the display',
              hintStyle: TextStyle(color: LandfallColors.textTertiary),
              filled: true,
              fillColor: LandfallColors.surface,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),

          // ── Dim ───────────────────────────────────────────────────────────
          const SectionHeader('Dim'),
          const SizedBox(height: 8),
          _DimSection(
            dimEnabled: dimEnabled,
            dimStartHour: dimStartHour,
            dimEndHour: dimEndHour,
            dimLevel: dimLevel,
            onEnabledChanged: onDimEnabledChanged,
            onStartHourChanged: onDimStartHourChanged,
            onEndHourChanged: onDimEndHourChanged,
            onLevelChanged: onDimLevelChanged,
          ),
          const SizedBox(height: 24),

          // ── Photo Source ──────────────────────────────────────────────────
          const SectionHeader('Photo Source'),
          const SizedBox(height: 8),
          _PhotoSourceSection(
            sourceType: sourceType,
            readOnlySource: readOnlySource,
            networkUrlsCtrl: networkUrlsCtrl,
            onSourceTypeChanged: onSourceTypeChanged,
            onNetworkUrlsChanged: onNetworkUrlsChanged,
          ),
          const SizedBox(height: 32),

          // ── Save ──────────────────────────────────────────────────────────
          ElevatedButton(
            key: const Key('web_display_save'),
            onPressed: canSave ? onSave : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: LandfallColors.accent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : const Text('Save', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
        ),
      ),
    );
  }
}

// ── Dim section ───────────────────────────────────────────────────────────────

class _DimSection extends StatelessWidget {
  const _DimSection({
    required this.dimEnabled,
    required this.dimStartHour,
    required this.dimEndHour,
    required this.dimLevel,
    required this.onEnabledChanged,
    required this.onStartHourChanged,
    required this.onEndHourChanged,
    required this.onLevelChanged,
  });

  final bool dimEnabled;
  final int dimStartHour;
  final int dimEndHour;
  final double dimLevel;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<int> onStartHourChanged;
  final ValueChanged<int> onEndHourChanged;
  final ValueChanged<double> onLevelChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Enable dim',
              style: TextStyle(color: LandfallColors.textPrimary)),
          subtitle: const Text('Reduce brightness during quiet hours',
              style: TextStyle(
                  color: LandfallColors.textSecondary, fontSize: 12)),
          value: dimEnabled,
          onChanged: onEnabledChanged,
          activeThumbColor: LandfallColors.accent,
        ),
        if (dimEnabled) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _HourPicker(
                  label: 'Start hour',
                  value: dimStartHour,
                  onChanged: onStartHourChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HourPicker(
                  label: 'End hour',
                  value: dimEndHour,
                  onChanged: onEndHourChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Level',
                  style: TextStyle(
                      color: LandfallColors.textSecondary, fontSize: 13)),
              Expanded(
                child: Slider(
                  value: dimLevel,
                  min: 0.1,
                  max: 1.0,
                  divisions: 18,
                  activeColor: LandfallColors.accent,
                  onChanged: onLevelChanged,
                ),
              ),
              Text(
                '${(dimLevel * 100).round()}%',
                style: const TextStyle(
                    color: LandfallColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _HourPicker extends StatelessWidget {
  const _HourPicker({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: LandfallColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 4),
        DropdownButton<int>(
          value: value,
          isExpanded: true,
          dropdownColor: LandfallColors.surface,
          style: const TextStyle(color: LandfallColors.textPrimary),
          items: List.generate(
            24,
            (h) => DropdownMenuItem(
              value: h,
              child: Text(_hourLabel(h)),
            ),
          ),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }

  static String _hourLabel(int hour) {
    if (hour == 0) return '12:00 AM';
    if (hour == 12) return '12:00 PM';
    return hour < 12 ? '$hour:00 AM' : '${hour - 12}:00 PM';
  }
}

// ── Photo source section ──────────────────────────────────────────────────────

class _PhotoSourceSection extends StatelessWidget {
  const _PhotoSourceSection({
    required this.sourceType,
    required this.readOnlySource,
    required this.networkUrlsCtrl,
    required this.onSourceTypeChanged,
    required this.onNetworkUrlsChanged,
  });

  final _SourceType? sourceType;
  final PhotoSource? readOnlySource;
  final TextEditingController networkUrlsCtrl;
  final ValueChanged<_SourceType> onSourceTypeChanged;
  final ValueChanged<String> onNetworkUrlsChanged;

  @override
  Widget build(BuildContext context) {
    // Read-only: local_directory or unrecognised source.
    if (sourceType == null) {
      return _ReadOnlySourceNotice(source: readOnlySource);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Type selector
        Row(
          children: [
            _SourceChip(
              label: 'Landfall Server',
              selected: sourceType == _SourceType.server,
              onSelected: () => onSourceTypeChanged(_SourceType.server),
              trailing: IconButton(
                icon: const Icon(Icons.info_outline,
                    size: 16, color: LandfallColors.textTertiary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'About Landfall Server',
                onPressed: () => _showServerInfo(context),
              ),
            ),
            const SizedBox(width: 8),
            _SourceChip(
              label: 'Network URLs',
              selected: sourceType == _SourceType.network,
              onSelected: () => onSourceTypeChanged(_SourceType.network),
            ),
          ],
        ),

        // Per-type fields
        if (sourceType == _SourceType.network) ...[
          const SizedBox(height: 12),
          const Text(
            'One URL per line — direct links to image files',
            style: TextStyle(
                color: LandfallColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 6),
          TextField(
            key: const Key('photo_source_network_urls'),
            controller: networkUrlsCtrl,
            onChanged: onNetworkUrlsChanged,
            style: const TextStyle(
                color: LandfallColors.textPrimary, fontSize: 13),
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Paste image URLs, one per line',
              hintStyle:
                  TextStyle(color: LandfallColors.textTertiary, fontSize: 12),
              filled: true,
              fillColor: LandfallColors.surface,
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ],
      ],
    );
  }

  void _showServerInfo(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: LandfallColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _ServerInfoSheet(),
    );
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.trailing,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: selected ? null : onSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? LandfallColors.accent.withValues(alpha: 0.15)
              : LandfallColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? LandfallColors.accent
                : LandfallColors.textTertiary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? LandfallColors.accent
                    : LandfallColors.textSecondary,
                fontSize: 13,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 4),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

class _ReadOnlySourceNotice extends StatelessWidget {
  const _ReadOnlySourceNotice({required this.source});
  final PhotoSource? source;

  @override
  Widget build(BuildContext context) {
    final (icon, label, detail) = switch (source) {
      PhotoSourceLocalDirectory(:final path) => (
          Icons.folder_outlined,
          'Local Directory',
          'Set to "$path" on the device — change this setting from the TV.',
        ),
      PhotoSourceS3(:final bucket) => (
          Icons.cloud_queue,
          'S3 Bucket ($bucket)',
          'S3 is not yet supported in the web app — change this from the TV.',
        ),
      _ => (
          Icons.help_outline,
          'Custom source',
          'This source type can only be changed from the TV.',
        ),
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LandfallColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: LandfallColors.textTertiary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: LandfallColors.textTertiary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: LandfallColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                const SizedBox(height: 2),
                Text(detail,
                    style: const TextStyle(
                        color: LandfallColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServerInfoSheet extends StatelessWidget {
  const _ServerInfoSheet();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_outlined,
                  color: LandfallColors.accent, size: 20),
              const SizedBox(width: 10),
              const Text(
                'Landfall Server',
                style: TextStyle(
                  color: LandfallColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close,
                    color: LandfallColors.textTertiary, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Photos are sourced from Google Drive via your linked Google '
            'account. Connect your account in the Accounts tab to get started.',
            style: TextStyle(color: LandfallColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 12),
          const Text(
            'Once connected, the Landfall server syncs your Drive photos '
            'automatically. Only image files are included.',
            style: TextStyle(color: LandfallColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: LandfallColors.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: LandfallColors.accent.withValues(alpha: 0.25)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline,
                    size: 14, color: LandfallColors.accent),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Only Google Drive is supported at this time. '
                    'Microsoft OneDrive and other providers are not yet available.',
                    style: TextStyle(
                        color: LandfallColors.accent,
                        fontSize: 12,
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
