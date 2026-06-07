import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:landfall_client/landfall_client.dart';
import 'package:ui_kit/ui_kit.dart';

import 'package:display/src/features/settings/widgets/agent_keys_section.dart';
import 'package:display/src/features/settings/widgets/section_header.dart';

class AccountsTabView extends StatefulWidget {
  const AccountsTabView({
    super.key,
    required this.onLoad,
    required this.serverUrl,
    this.onOpenUrl,
    this.onListKeys,
    this.onGenerateKey,
    this.onRevokeKey,
  });

  /// Loads (credentials, userId) from the server.
  final Future<(List<LinkedCredentialSummary>, String)> Function() onLoad;
  final String serverUrl;

  /// When provided (web context), connect tiles show an "Open" button that
  /// calls this with the OAuth URL. On TV (null), tiles show only "Copy URL".
  final void Function(String url)? onOpenUrl;

  // Agent key callbacks — optional so the widget can be rendered without them.
  final Future<List<ApiKey>> Function(String token)? onListKeys;
  final Future<ApiKeyCreateResponse> Function(String name, String token)?
      onGenerateKey;
  final Future<bool> Function(int id, String token)? onRevokeKey;

  @override
  State<AccountsTabView> createState() => _AccountsTabViewState();
}

class _AccountsTabViewState extends State<AccountsTabView> {
  late Future<(List<LinkedCredentialSummary>, String)> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.onLoad();
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
          onRefresh: () => setState(() => _future = widget.onLoad()),
          onOpenUrl: widget.onOpenUrl,
          onListKeys: widget.onListKeys,
          onGenerateKey: widget.onGenerateKey,
          onRevokeKey: widget.onRevokeKey,
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
    this.onOpenUrl,
    this.onListKeys,
    this.onGenerateKey,
    this.onRevokeKey,
  });

  final List<LinkedCredentialSummary> credentials;
  final String userId;
  final String serverUrl;
  final VoidCallback onRefresh;
  final void Function(String url)? onOpenUrl;
  final Future<List<ApiKey>> Function(String token)? onListKeys;
  final Future<ApiKeyCreateResponse> Function(String name, String token)?
      onGenerateKey;
  final Future<bool> Function(int id, String token)? onRevokeKey;

  @override
  Widget build(BuildContext context) {
    final base = serverUrl.endsWith('/') ? serverUrl : '$serverUrl/';
    final googleUrl = '${base}calendar/oauth/start?authUserId=$userId';
    final microsoftUrl =
        '${base}calendar/microsoft/oauth/start?authUserId=$userId';

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SectionHeader('Connected Accounts'),
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
        const SectionHeader('Connect an Account'),
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
          onOpenUrl: onOpenUrl,
        ),
        const SizedBox(height: 12),
        _ConnectUrlTile(
          provider: 'Microsoft Calendar',
          color: const Color(0xFF00A4EF),
          url: microsoftUrl,
          onOpenUrl: onOpenUrl,
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
        if (onListKeys != null &&
            onGenerateKey != null &&
            onRevokeKey != null) ...[
          const SizedBox(height: 32),
          AgentKeysSection(
            onListKeys: onListKeys!,
            onGenerateKey: onGenerateKey!,
            onRevokeKey: onRevokeKey!,
          ),
          const SizedBox(height: 24),
        ],
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
    this.onOpenUrl,
  });

  final String provider;
  final Color color;
  final String url;
  final void Function(String url)? onOpenUrl;

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
                  style:
                      TextStyle(color: color, fontWeight: FontWeight.w600),
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
            Row(
              children: [
                Expanded(
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
                if (onOpenUrl != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => onOpenUrl!(url),
                      icon: const Icon(Icons.open_in_new, size: 14),
                      label: const Text('Open'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: color,
                        side: BorderSide(color: color.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ],
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
