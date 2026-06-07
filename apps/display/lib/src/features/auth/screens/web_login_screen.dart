import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pinput/pinput.dart';
import 'package:ui_kit/ui_kit.dart';

import '../cubit/auth_cubit.dart';

/// Web OTP login screen (no leanback / no device-code flow).
///
/// Step 1: email entry → sends OTP code.
/// Step 2: 6-digit code entry → verifies and authenticates.
class WebLoginScreen extends StatefulWidget {
  const WebLoginScreen({super.key});

  @override
  State<WebLoginScreen> createState() => _WebLoginScreenState();
}

class _WebLoginScreenState extends State<WebLoginScreen> {
  final _emailController = TextEditingController();
  final _emailFocus = FocusNode();
  final _codeFocus = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocus.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LandfallColors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: BlocConsumer<AuthCubit, AuthState>(
            listener: (context, state) {
              if (state is AuthCodeSent) {
                _codeFocus.requestFocus();
              }
              if (state is AuthError &&
                  state.previous is AuthUnauthenticated) {
                _emailFocus.requestFocus();
              }
            },
            builder: (context, state) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Landfall Settings',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: LandfallColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sign in with your Landfall account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: LandfallColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 40),
                    if (state is AuthCodeSent ||
                        state is AuthVerifying ||
                        (state is AuthError &&
                            state.previous is AuthCodeSent)) ...[
                      Builder(builder: (context) {
                        final email = switch (state) {
                          AuthCodeSent(:final email) => email,
                          AuthVerifying(:final email) => email,
                          AuthError(:final previous) => switch (previous) {
                              AuthCodeSent(:final email) => email,
                              _ => '',
                            },
                          _ => '',
                        };
                        return _CodeForm(
                          email: email,
                          focusNode: _codeFocus,
                          loading: state is AuthVerifying,
                          error: state is AuthError ? state.message : null,
                          onSubmit: (code) {
                            if (email.isNotEmpty) {
                              context
                                  .read<AuthCubit>()
                                  .verifyCode(email, code);
                            }
                          },
                          onBack: () {
                            context.read<AuthCubit>().sendCode(email);
                          },
                        );
                      }),
                    ] else ...[
                      _EmailForm(
                        controller: _emailController,
                        focusNode: _emailFocus,
                        loading: state is AuthSendingCode,
                        error: state is AuthError ? state.message : null,
                        onSubmit: () {
                          final email = _emailController.text.trim();
                          if (email.isNotEmpty) {
                            context.read<AuthCubit>().sendCode(email);
                          }
                        },
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _EmailForm extends StatelessWidget {
  const _EmailForm({
    required this.controller,
    required this.focusNode,
    required this.loading,
    required this.onSubmit,
    this.error,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool loading;
  final VoidCallback onSubmit;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          focusNode: focusNode,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: LandfallColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Email address',
            hintStyle:
                const TextStyle(color: LandfallColors.textTertiary),
            filled: true,
            fillColor: LandfallColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: LandfallColors.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: LandfallColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: LandfallColors.accent),
            ),
          ),
          onSubmitted: (_) => onSubmit(),
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(
            error!,
            style: const TextStyle(
              color: LandfallColors.alert,
              fontSize: 13,
            ),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: loading ? null : onSubmit,
          style: FilledButton.styleFrom(
            backgroundColor: LandfallColors.accent,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: loading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
              : const Text(
                  'Send code',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
        ),
      ],
    );
  }
}

class _CodeForm extends StatelessWidget {
  const _CodeForm({
    required this.email,
    required this.focusNode,
    required this.loading,
    required this.onSubmit,
    required this.onBack,
    this.error,
  });

  final String email;
  final FocusNode focusNode;
  final bool loading;
  final ValueChanged<String> onSubmit;
  final VoidCallback onBack;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Code sent to $email',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: LandfallColors.textSecondary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Pinput(
            focusNode: focusNode,
            autofocus: true,
            length: 6,
            enabled: !loading,
            defaultPinTheme: PinTheme(
              width: 48,
              height: 56,
              textStyle: const TextStyle(
                color: LandfallColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
              decoration: BoxDecoration(
                color: LandfallColors.surface,
                border: Border.all(color: LandfallColors.cardBorder),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            focusedPinTheme: PinTheme(
              width: 48,
              height: 56,
              textStyle: const TextStyle(
                color: LandfallColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
              decoration: BoxDecoration(
                color: LandfallColors.surface,
                border: Border.all(color: LandfallColors.accent),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onCompleted: onSubmit,
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(
            error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: LandfallColors.alert,
              fontSize: 13,
            ),
          ),
        ],
        if (loading) ...[
          const SizedBox(height: 16),
          const Center(child: CircularProgressIndicator()),
        ],
        const SizedBox(height: 16),
        TextButton(
          onPressed: loading ? null : onBack,
          child: const Text(
            'Resend code',
            style: TextStyle(color: LandfallColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
