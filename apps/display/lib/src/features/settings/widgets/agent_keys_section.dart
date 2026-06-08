import 'package:flutter/material.dart';
import 'package:landfall_client/landfall_client.dart';
import 'package:ui_kit/ui_kit.dart';

import 'package:display/src/widgets/landfall_text_field.dart';

/// Displays the list of agent API keys and their usage metadata.
///
/// Requires the caller to supply the management token via [onListKeys]. The
/// token is entered once by the user and used for all subsequent operations.
/// Surfaces [ApiKey.lastUsedIp] and [ApiKey.lastUsedAt] so anomalous access
/// can be spotted at a glance. A07:2025.
class AgentKeysSection extends StatefulWidget {
  const AgentKeysSection({
    super.key,
    this.leanback = false,
    required this.onListKeys,
    required this.onGenerateKey,
    required this.onRevokeKey,
  });

  final bool leanback;
  final Future<List<ApiKey>> Function(String token) onListKeys;
  final Future<ApiKeyCreateResponse> Function(String name, String token)
      onGenerateKey;
  final Future<bool> Function(int id, String token) onRevokeKey;

  @override
  State<AgentKeysSection> createState() => _AgentKeysSectionState();
}

class _AgentKeysSectionState extends State<AgentKeysSection> {
  final _tokenCtrl = TextEditingController();
  final _newKeyNameCtrl = TextEditingController();

  List<ApiKey>? _keys;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _tokenCtrl.dispose();
    _newKeyNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final token = _tokenCtrl.text.trim();
    if (token.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final keys = await widget.onListKeys(token);
      setState(() {
        _keys = keys;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load keys. Check your management token.';
        _loading = false;
      });
    }
  }

  Future<void> _revoke(int id) async {
    try {
      await widget.onRevokeKey(id, _tokenCtrl.text.trim());
      await _load();
    } catch (_) {
      setState(() => _error = 'Failed to revoke key.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Agent Keys'),
        const SizedBox(height: 12),
        _TokenRow(
          controller: _tokenCtrl,
          leanback: widget.leanback,
          loading: _loading,
          onLoad: _load,
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: const TextStyle(
              color: LandfallColors.alert,
              fontSize: 12,
            ),
          ),
        ],
        if (_keys != null) ...[
          const SizedBox(height: 16),
          if (_keys!.isEmpty)
            const Text(
              'No keys found.',
              style: TextStyle(
                color: LandfallColors.textSecondary,
                fontSize: 13,
              ),
            )
          else
            ..._keys!.map(
              (k) => _ApiKeyTile(
                apiKey: k,
                onRevoke: () => _revoke(k.id!),
              ),
            ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title);

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

class _TokenRow extends StatelessWidget {
  const _TokenRow({
    required this.controller,
    required this.loading,
    required this.onLoad,
    this.leanback = false,
  });

  final TextEditingController controller;
  final bool loading;
  final VoidCallback onLoad;
  final bool leanback;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: LandfallTextField(
            controller: controller,
            leanback: leanback,
            obscureText: true,
            style: const TextStyle(
              color: LandfallColors.textPrimary,
              fontSize: 13,
            ),
            decoration: InputDecoration(
              hintText: 'Management token',
              hintStyle: const TextStyle(
                color: LandfallColors.textTertiary,
                fontSize: 13,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: LandfallColors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: LandfallColors.accent),
              ),
              filled: true,
              fillColor: LandfallColors.surface,
            ),
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: loading ? null : onLoad,
          style: TextButton.styleFrom(
            foregroundColor: LandfallColors.accent,
          ),
          child: loading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: LandfallColors.accent,
                  ),
                )
              : const Text('Load'),
        ),
      ],
    );
  }
}

class _ApiKeyTile extends StatelessWidget {
  const _ApiKeyTile({required this.apiKey, required this.onRevoke});

  final ApiKey apiKey;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    final lastUsed = apiKey.lastUsedAt;
    final lastIp = apiKey.lastUsedIp;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LandfallColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: LandfallColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      apiKey.name,
                      style: const TextStyle(
                        color: LandfallColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      apiKey.prefix,
                      style: const TextStyle(
                        color: LandfallColors.textTertiary,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onRevoke,
                style: TextButton.styleFrom(
                  foregroundColor: LandfallColors.alert,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Revoke', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _MetaRow(
            label: 'Usage',
            value: '${apiKey.usageCount} / ${apiKey.dailyLimit} today',
          ),
          _MetaRow(
            label: 'Last used',
            value: lastUsed != null ? _formatDateTime(lastUsed) : 'never',
          ),
          _MetaRow(
            label: 'Last IP',
            value: lastIp ?? 'never',
          ),
        ],
      ),
    );
  }

  static String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.year}-${_pad(local.month)}-${_pad(local.day)} '
        '${_pad(local.hour)}:${_pad(local.minute)}';
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: const TextStyle(
                color: LandfallColors.textTertiary,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: LandfallColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
