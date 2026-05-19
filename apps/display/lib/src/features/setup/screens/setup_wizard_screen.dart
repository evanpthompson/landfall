import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui_kit/ui_kit.dart';

import 'package:display/src/data/discovery/mdns_server_discovery.dart';
import 'package:display/src/features/setup/cubit/setup_wizard_cubit.dart';
import 'package:display/src/widgets/landfall_text_field.dart';

/// Full-screen first-run setup wizard.
///
/// Shown when [DisplaySettings.serverUrl] is empty or [wizardComplete] is false.
/// [onComplete] is called with the confirmed server URL when the user finishes;
/// the caller is responsible for calling [runApp] with [LandfallApp].
class SetupWizardScreen extends StatelessWidget {
  const SetupWizardScreen({super.key, required this.onComplete});

  final ValueChanged<String> onComplete;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SetupWizardCubit, SetupWizardState>(
      listener: (context, state) {
        if (state is SetupWizardComplete) {
          onComplete(state.serverUrl);
        }
      },
      builder: (context, state) {
        final step = switch (state) {
          SetupWizardAt(:final step) => step,
          SetupWizardStepError(:final step) => step,
          SetupWizardValidating() => SetupWizardStep.discover,
          SetupWizardComplete() => SetupWizardStep.done,
        };

        return Scaffold(
          backgroundColor: LandfallColors.background,
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    _StepIndicator(current: step),
                    const SizedBox(height: 40),
                    Expanded(
                      child: SingleChildScrollView(
                        child: _StepBody(state: state),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step indicator dots
// ─────────────────────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current});

  final SetupWizardStep current;

  // serverUrl is a fallback sub-step — not shown as a main-path dot.
  static const _steps = [
    SetupWizardStep.discover,
    SetupWizardStep.location,
    SetupWizardStep.linkAccount,
    SetupWizardStep.done,
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _steps.map((s) {
        final active = s == current;
        final past = s.index < current.index;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: active ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: active || past
                  ? LandfallColors.accent
                  : LandfallColors.divider,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Per-step body — routes to the right step widget
// ─────────────────────────────────────────────────────────────────────────────

class _StepBody extends StatelessWidget {
  const _StepBody({required this.state});

  final SetupWizardState state;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      SetupWizardAt(:final step, :final serverUrl, :final discoveredServers) =>
        switch (step) {
          SetupWizardStep.discover =>
            _DiscoverStep(discoveredServers: discoveredServers),
          SetupWizardStep.serverUrl => const _ServerUrlStep(),
          SetupWizardStep.location => const _LocationStep(),
          SetupWizardStep.linkAccount =>
            _LinkAccountStep(serverUrl: serverUrl),
          SetupWizardStep.done => _DoneStep(serverUrl: serverUrl),
        },
      SetupWizardValidating() =>
        const _DiscoverStep(discoveredServers: [], validating: true),
      SetupWizardStepError(:final message, :final step) => switch (step) {
          SetupWizardStep.serverUrl => _ServerUrlStep(error: message),
          _ => _LocationStep(error: message),
        },
      SetupWizardComplete() => const SizedBox.shrink(),
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 1 — Discover servers
// ─────────────────────────────────────────────────────────────────────────────

class _DiscoverStep extends StatelessWidget {
  const _DiscoverStep({
    required this.discoveredServers,
    this.validating = false,
  });

  final List<DiscoveredServer> discoveredServers;
  final bool validating;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Find your server',
          style: TextStyle(
            color: LandfallColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Scanning your network for a Landfall server...',
          style: TextStyle(color: LandfallColors.textSecondary, fontSize: 15),
        ),
        const SizedBox(height: 32),
        if (discoveredServers.isEmpty && !validating)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(color: LandfallColors.accent),
            ),
          )
        else if (validating)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(color: LandfallColors.accent),
            ),
          )
        else
          Column(
            children: discoveredServers
                .map((s) => _ServerTile(server: s))
                .toList(),
          ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => context.read<SetupWizardCubit>().skipDiscovery(),
          style: TextButton.styleFrom(
            foregroundColor: LandfallColors.textSecondary,
          ),
          child: const Text('Enter manually'),
        ),
      ],
    );
  }
}

class _ServerTile extends StatelessWidget {
  const _ServerTile({required this.server});

  final DiscoveredServer server;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => context
            .read<SetupWizardCubit>()
            .selectDiscoveredServer(server.serverUrl),
        borderRadius: BorderRadius.circular(8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: LandfallColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: LandfallColors.cardBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  Icons.dns_outlined,
                  color: LandfallColors.accent,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        server.name,
                        style: const TextStyle(
                          color: LandfallColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        server.serverUrl,
                        style: const TextStyle(
                          color: LandfallColors.textSecondary,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: LandfallColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 1b — Server URL (manual fallback)
// ─────────────────────────────────────────────────────────────────────────────

class _ServerUrlStep extends StatefulWidget {
  const _ServerUrlStep({this.error});

  final String? error;

  @override
  State<_ServerUrlStep> createState() => _ServerUrlStepState();
}

class _ServerUrlStepState extends State<_ServerUrlStep> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<SetupWizardCubit>().submitServerUrl(_ctrl.text);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Connect to your server',
          style: TextStyle(
            color: LandfallColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Enter the URL where your Landfall server is running.',
          style: TextStyle(color: LandfallColors.textSecondary, fontSize: 15),
        ),
        const SizedBox(height: 32),
        LandfallTextField(
          controller: _ctrl,
          autofocus: true,
          keyboardType: TextInputType.url,
          style: const TextStyle(color: LandfallColors.textPrimary, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'https://api.yourdomain.com/',
            hintStyle: const TextStyle(color: LandfallColors.textTertiary),
            filled: true,
            fillColor: LandfallColors.surface,
            errorText: widget.error,
            errorStyle: const TextStyle(color: LandfallColors.warning),
            border: _inputBorder(LandfallColors.cardBorder),
            enabledBorder: _inputBorder(LandfallColors.cardBorder),
            focusedBorder: _inputBorder(LandfallColors.accent),
            errorBorder: _inputBorder(LandfallColors.warning),
            focusedErrorBorder: _inputBorder(LandfallColors.warning),
          ),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 8),
        const Text(
          'Running locally?  http://localhost:8080/',
          style: TextStyle(
            color: LandfallColors.textTertiary,
            fontSize: 12,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor: LandfallColors.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Connect', style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 2 — Location
// ─────────────────────────────────────────────────────────────────────────────

class _LocationStep extends StatefulWidget {
  const _LocationStep({this.error});

  final String? error;

  @override
  State<_LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends State<_LocationStep> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() =>
      context.read<SetupWizardCubit>().submitLocation(_ctrl.text);

  void _skip() => context.read<SetupWizardCubit>().submitLocation('');

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Where are you?',
          style: TextStyle(
            color: LandfallColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Used for the weather card. You can change this later in Settings.',
          style: TextStyle(color: LandfallColors.textSecondary, fontSize: 15),
        ),
        const SizedBox(height: 32),
        LandfallTextField(
          controller: _ctrl,
          autofocus: true,
          style: const TextStyle(color: LandfallColors.textPrimary, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'e.g. Seattle, WA',
            hintStyle: const TextStyle(color: LandfallColors.textTertiary),
            filled: true,
            fillColor: LandfallColors.surface,
            errorText: widget.error,
            errorStyle: const TextStyle(color: LandfallColors.warning),
            border: _inputBorder(LandfallColors.cardBorder),
            enabledBorder: _inputBorder(LandfallColors.cardBorder),
            focusedBorder: _inputBorder(LandfallColors.accent),
          ),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor: LandfallColors.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Save & Continue', style: TextStyle(fontSize: 16)),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _skip,
          style: TextButton.styleFrom(
            foregroundColor: LandfallColors.textSecondary,
          ),
          child: const Text('Skip for now'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 3 — Link account
// ─────────────────────────────────────────────────────────────────────────────

class _LinkAccountStep extends StatelessWidget {
  const _LinkAccountStep({required this.serverUrl});

  final String serverUrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Connect accounts',
          style: TextStyle(
            color: LandfallColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Calendar and photo accounts are connected from Settings → Accounts after signing in.',
          style: TextStyle(color: LandfallColors.textSecondary, fontSize: 15),
        ),
        const SizedBox(height: 24),
        _InfoTile(
          icon: Icons.calendar_today_outlined,
          title: 'Calendar',
          body: 'Google and Microsoft calendars. Link multiple accounts for a family display.',
        ),
        const SizedBox(height: 12),
        _InfoTile(
          icon: Icons.photo_library_outlined,
          title: 'Photos',
          body: 'A Google Drive folder you designate. Landfall rotates through it as a photo frame.',
        ),
        const SizedBox(height: 12),
        _InfoTile(
          icon: Icons.key_outlined,
          title: 'Agent API keys',
          body: 'Generate keys for Claude, n8n, Home Assistant, and any other agent in Settings → API Keys.',
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: () => context.read<SetupWizardCubit>().advanceToDone(),
          style: FilledButton.styleFrom(
            backgroundColor: LandfallColors.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Got it', style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: LandfallColors.accent, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: LandfallColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: const TextStyle(
                      color: LandfallColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 4 — Done
// ─────────────────────────────────────────────────────────────────────────────

class _DoneStep extends StatelessWidget {
  const _DoneStep({required this.serverUrl});

  final String serverUrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "You're all set",
          style: TextStyle(
            color: LandfallColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Connected to $serverUrl',
          style: const TextStyle(
            color: LandfallColors.textSecondary,
            fontSize: 14,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Sign in to finish connecting accounts and generate your first agent API key. '
          'Everything else is in Settings — tap the gear icon on the display.',
          style: TextStyle(color: LandfallColors.textSecondary, fontSize: 15),
        ),
        const SizedBox(height: 40),
        FilledButton(
          onPressed: () => context.read<SetupWizardCubit>().complete(),
          style: FilledButton.styleFrom(
            backgroundColor: LandfallColors.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Launch Landfall', style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

OutlineInputBorder _inputBorder(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: color),
    );
