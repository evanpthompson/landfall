import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';

import 'package:display/src/app/landfall_root.dart';
import 'package:display/src/data/server/server_health_checker.dart';
import 'package:display/src/features/server/cubit/change_server_cubit.dart';
import 'package:display/src/widgets/landfall_text_field.dart';

/// Single-field screen for re-pointing the app at a different Landfall server.
///
/// Reachable from the sign-in screen (recovery before auth) and Settings →
/// Display (server moved while running). On success it persists the new URL and
/// relaunches the app via [AppRelauncher] so the whole tree rebinds to it.
class ChangeServerScreen extends StatelessWidget {
  const ChangeServerScreen({
    super.key,
    this.leanback = false,
    this.currentUrl,
    this.healthChecker,
  });

  final bool leanback;

  /// The currently configured server URL, shown for reference.
  final String? currentUrl;

  /// Test seam. Production uses [HttpServerHealthChecker].
  final ServerHealthChecker? healthChecker;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => ChangeServerCubit(
        healthChecker: healthChecker ?? HttpServerHealthChecker(),
        settingsRepository: ctx.read<DisplaySettingsRepository>(),
      ),
      child: _ChangeServerView(leanback: leanback, currentUrl: currentUrl),
    );
  }
}

class _ChangeServerView extends StatefulWidget {
  const _ChangeServerView({required this.leanback, this.currentUrl});

  final bool leanback;
  final String? currentUrl;

  @override
  State<_ChangeServerView> createState() => _ChangeServerViewState();
}

class _ChangeServerViewState extends State<_ChangeServerView> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.currentUrl ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() => context.read<ChangeServerCubit>().submit(_ctrl.text);

  void _appendText(String text) {
    _ctrl.text += text;
    _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LandfallColors.background,
      appBar: AppBar(
        backgroundColor: LandfallColors.background,
        foregroundColor: LandfallColors.textPrimary,
        title: const Text('Server address'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: BlocConsumer<ChangeServerCubit, ChangeServerState>(
            listener: (context, state) {
              if (state is ChangeServerSaved) {
                // Rebind the whole app to the new URL; this screen's route is
                // discarded along with the old tree.
                AppRelauncher.of(context).relaunch();
              }
            },
            builder: (context, state) {
              final validating = state is ChangeServerValidating;
              final error =
                  state is ChangeServerEditing ? state.error : null;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
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
                      'Enter the URL where your Landfall server is running — '
                      'the same address your phone uses to sign in.',
                      style: TextStyle(
                        color: LandfallColors.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                    if (widget.currentUrl != null &&
                        widget.currentUrl!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Current: ${widget.currentUrl}',
                        style: const TextStyle(
                          color: LandfallColors.textTertiary,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    LandfallTextField(
                      controller: _ctrl,
                      autofocus: true,
                      enabled: !validating,
                      keyboardType: TextInputType.url,
                      style: const TextStyle(
                        color: LandfallColors.textPrimary,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: 'https://app.yourdomain.com/',
                        hintStyle:
                            const TextStyle(color: LandfallColors.textTertiary),
                        filled: true,
                        fillColor: LandfallColors.surface,
                        errorText: error,
                        errorMaxLines: 3,
                        errorStyle:
                            const TextStyle(color: LandfallColors.warning),
                        border: _border(LandfallColors.cardBorder),
                        enabledBorder: _border(LandfallColors.cardBorder),
                        focusedBorder: _border(LandfallColors.accent),
                        errorBorder: _border(LandfallColors.warning),
                        focusedErrorBorder: _border(LandfallColors.warning),
                      ),
                      onSubmitted: (_) => _submit(),
                    ),
                    if (widget.leanback) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          _Chip('http://', () => _appendText('http://')),
                          _Chip('https://', () => _appendText('https://')),
                          _Chip(':8080/', () => _appendText(':8080/')),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: validating ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: LandfallColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: validating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Connect',
                              style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: color),
      );
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, this.onTap);

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: LandfallColors.surface,
      labelStyle: const TextStyle(
        color: LandfallColors.textSecondary,
        fontFamily: 'monospace',
      ),
      side: const BorderSide(color: LandfallColors.cardBorder),
    );
  }
}
