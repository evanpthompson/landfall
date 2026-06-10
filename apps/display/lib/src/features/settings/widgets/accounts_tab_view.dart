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
    this.webServerUrl,
    this.leanback = false,
    this.onOpenUrl,
    this.onCreateLinkTicket,
    this.onListKeys,
    this.onGenerateKey,
    this.onRevokeKey,
  });

  /// Loads (credentials, userId) from the server.
  final Future<(List<LinkedCredentialSummary>, String)> Function() onLoad;

  /// Base URL of the API (RPC) server. Used for display only.
  final String serverUrl;

  /// Base URL of the Serverpod **web** server, where the OAuth connect
  /// routes (`/calendar/oauth/start`, …) are registered. The API server
  /// ([serverUrl]) does not serve these routes, so the connect links must
  /// target this origin. Falls back to [serverUrl] when not provided.
  final String? webServerUrl;
  final bool leanback;

  /// When provided (web context), connect tiles show an "Open" button that
  /// calls this with the OAuth URL. On TV (null), tiles show only "Copy URL".
  final void Function(String url)? onOpenUrl;

  /// SEC-06: mints a short-lived, single-use link ticket bound to the
  /// signed-in user, returning the ticket string (or null on failure). The
  /// connect URL carries this ticket — never a caller-supplied identity — so
  /// it is created fresh when the user taps Open/Copy. Required for the
  /// connect buttons to be enabled.
  final Future<String?> Function()? onCreateLinkTicket;

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
        // userId is intentionally unused for URL construction: SEC-06 means
        // identity travels in the server-minted ticket, never the URL.
        final (credentials, _) = snapshot.data!;
        return _AccountsList(
          credentials: credentials,
          serverUrl: widget.serverUrl,
          webServerUrl: widget.webServerUrl ?? widget.serverUrl,
          leanback: widget.leanback,
          onRefresh: () => setState(() => _future = widget.onLoad()),
          onOpenUrl: widget.onOpenUrl,
          onCreateLinkTicket: widget.onCreateLinkTicket,
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
    required this.serverUrl,
    required this.webServerUrl,
    required this.onRefresh,
    this.leanback = false,
    this.onOpenUrl,
    this.onCreateLinkTicket,
    this.onListKeys,
    this.onGenerateKey,
    this.onRevokeKey,
  });

  final List<LinkedCredentialSummary> credentials;
  final String serverUrl;
  final String webServerUrl;
  final VoidCallback onRefresh;
  final bool leanback;
  final void Function(String url)? onOpenUrl;
  final Future<String?> Function()? onCreateLinkTicket;
  final Future<List<ApiKey>> Function(String token)? onListKeys;
  final Future<ApiKeyCreateResponse> Function(String name, String token)?
      onGenerateKey;
  final Future<bool> Function(int id, String token)? onRevokeKey;

  @override
  Widget build(BuildContext context) {
    // OAuth connect routes are registered on the Serverpod web server, not
    // the API server, so build the connect URLs from [webServerUrl]. The
    // single-use ticket is appended at tap time (see _ConnectUrlTile).
    final base = webServerUrl.endsWith('/') ? webServerUrl : '$webServerUrl/';
    final googleStartUrl = '${base}calendar/oauth/start';
    final microsoftStartUrl = '${base}calendar/microsoft/oauth/start';

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
          'Connect a calendar account from this signed-in device. The link is '
          'authorized for your account and expires within minutes.',
          style: TextStyle(color: LandfallColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 16),
        _ConnectUrlTile(
          provider: 'Google Calendar',
          color: const Color(0xFF4285F4),
          startUrl: googleStartUrl,
          onOpenUrl: onOpenUrl,
          onCreateLinkTicket: onCreateLinkTicket,
        ),
        const SizedBox(height: 12),
        _ConnectUrlTile(
          provider: 'Microsoft Calendar',
          color: const Color(0xFF00A4EF),
          startUrl: microsoftStartUrl,
          onOpenUrl: onOpenUrl,
          onCreateLinkTicket: onCreateLinkTicket,
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
            leanback: leanback,
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
    required this.startUrl,
    this.onOpenUrl,
    this.onCreateLinkTicket,
  });

  final String provider;
  final Color color;

  /// The OAuth start endpoint, without a ticket. A single-use ticket is
  /// minted and appended when the user taps Open/Copy.
  final String startUrl;
  final void Function(String url)? onOpenUrl;
  final Future<String?> Function()? onCreateLinkTicket;

  bool get _enabled => onCreateLinkTicket != null;

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
            Row(
              children: [
                Expanded(
                  child: LandfallFocusable(
                    borderRadius: BorderRadius.circular(4),
                    child: OutlinedButton.icon(
                      onPressed: _enabled ? () => _copyUrl(context) : null,
                      icon: const Icon(Icons.copy, size: 14),
                      label: const Text('Copy URL'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: color,
                        side: BorderSide(color: color.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ),
                if (onOpenUrl != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: LandfallFocusable(
                      borderRadius: BorderRadius.circular(4),
                      child: OutlinedButton.icon(
                        onPressed: _enabled ? () => _open(context) : null,
                        icon: const Icon(Icons.open_in_new, size: 14),
                        label: const Text('Open'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: color,
                          side: BorderSide(color: color.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
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

  /// Mints a single-use ticket and returns the full connect URL, or null on
  /// failure (after surfacing a message via [messenger]).
  Future<String?> _ticketUrl(ScaffoldMessengerState messenger) async {
    final create = onCreateLinkTicket;
    if (create == null) return null;
    final ticket = await create();
    if (ticket == null || ticket.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not start the connection. Please try again.'),
          duration: Duration(seconds: 3),
        ),
      );
      return null;
    }
    final separator = startUrl.contains('?') ? '&' : '?';
    return '$startUrl${separator}ticket=$ticket';
  }

  Future<void> _open(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final url = await _ticketUrl(messenger);
    if (url != null) onOpenUrl!(url);
  }

  Future<void> _copyUrl(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final url = await _ticketUrl(messenger);
    if (url == null) return;
    await Clipboard.setData(ClipboardData(text: url));
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Connect link copied — open it within a few minutes'),
        duration: Duration(seconds: 3),
      ),
    );
  }
}
