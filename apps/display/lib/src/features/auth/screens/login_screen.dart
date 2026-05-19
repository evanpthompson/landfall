import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/auth_cubit.dart';
import '../widgets/landfall_button.dart';

/// Full-screen login UI.
///
/// Two-step OTP flow (all platforms):
///   1. Email entry → tap "Send code" → [AuthCodeSent]
///   2. 6-digit code entry → tap "Verify" → [AuthAuthenticated]
///
/// Leanback (TV) mode adds a device-authorization alternative:
///   0. TV shows a 6-char code + server URL → user signs in on phone.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.leanback = false});

  final bool leanback;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _emailFocus = FocusNode();
  final _codeFocus = FocusNode();
  Timer? _pollTimer;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _emailFocus.dispose();
    _codeFocus.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling(String deviceCode) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        context.read<AuthCubit>().pollDeviceFlow(deviceCode);
      }
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: BlocConsumer<AuthCubit, AuthState>(
            listener: (context, state) {
              if (state is AuthCodeSent) {
                _codeController.clear();
                _codeFocus.requestFocus();
              }
              if (state is AuthError && state.previous is AuthUnauthenticated) {
                _stopPolling();
                _emailFocus.requestFocus();
              }
              if (state is AuthError && state.previous is AuthCodeSent) {
                _codeController.clear();
                _codeFocus.requestFocus();
              }
              if (state is AuthDevicePending) {
                _startPolling(state.deviceCode);
              }
              if (state is AuthAuthenticated) {
                _stopPolling();
              }
            },
            builder: (context, state) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(),
                  const SizedBox(height: 48),
                  _buildBody(context, state),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AuthState state) {
    // Device pending — show the TV code + verification URL.
    if (state is AuthDevicePending) {
      return _DeviceAuthStep(
        userCode: state.userCode,
        verificationUri: state.verificationUri,
        onCancel: () {
          _stopPolling();
          context.read<AuthCubit>().signOut();
        },
      );
    }

    final email = switch (state) {
      AuthCodeSent(:final email) => email,
      AuthVerifying(:final email) => email,
      AuthError(previous: AuthCodeSent(:final email)) => email,
      _ => null,
    };

    if (email != null) {
      return _CodeStep(
        email: email,
        controller: _codeController,
        focusNode: _codeFocus,
        isLoading: state is AuthVerifying,
        error: state is AuthError ? state.message : null,
        onVerify: () => context.read<AuthCubit>().verifyCode(
          email,
          _codeController.text.trim(),
        ),
        onResend: () => context.read<AuthCubit>().resendCode(email),
        onChangeEmail: () => context.read<AuthCubit>().signOut(),
      );
    }

    // Leanback: show device-auth option first, then email fallback.
    if (widget.leanback) {
      return _LeanbackUnauthStep(
        emailController: _emailController,
        emailFocus: _emailFocus,
        isLoading: state is AuthSendingCode,
        error: state is AuthError ? state.message : null,
        onStartDeviceFlow: () => context.read<AuthCubit>().startDeviceFlow(),
        onSendCode: () => context.read<AuthCubit>().sendCode(
          _emailController.text.trim(),
        ),
      );
    }

    return _EmailStep(
      controller: _emailController,
      focusNode: _emailFocus,
      isLoading: state is AuthSendingCode,
      error: state is AuthError ? state.message : null,
      onSend: () => context.read<AuthCubit>().sendCode(
        _emailController.text.trim(),
      ),
    );
  }
}

// ── Widgets ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'LANDFALL',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: 8,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'The ambient display layer for the agentic era',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white38,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

/// Leanback unauthenticated step — device-flow button + email fallback.
class _LeanbackUnauthStep extends StatelessWidget {
  const _LeanbackUnauthStep({
    required this.emailController,
    required this.emailFocus,
    required this.isLoading,
    required this.error,
    required this.onStartDeviceFlow,
    required this.onSendCode,
  });

  final TextEditingController emailController;
  final FocusNode emailFocus;
  final bool isLoading;
  final String? error;
  final VoidCallback onStartDeviceFlow;
  final VoidCallback onSendCode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LandfallButton(
          label: 'Sign in with TV code',
          isLoading: isLoading,
          onPressed: onStartDeviceFlow,
        ),
        const SizedBox(height: 24),
        const Row(
          children: [
            Expanded(child: Divider(color: Color(0xFF2A2A2A))),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('or', style: TextStyle(color: Colors.white24, fontSize: 12)),
            ),
            Expanded(child: Divider(color: Color(0xFF2A2A2A))),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Sign in with email',
          style: TextStyle(color: Colors.white70, fontSize: 15),
        ),
        const SizedBox(height: 12),
        _LandfallTextField(
          controller: emailController,
          focusNode: emailFocus,
          hint: 'you@example.com',
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          textInputAction: TextInputAction.send,
          onSubmitted: (_) => onSendCode(),
          enabled: !isLoading,
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
        ],
        const SizedBox(height: 16),
        LandfallButton(
          label: 'Send code',
          isLoading: isLoading,
          onPressed: onSendCode,
        ),
      ],
    );
  }
}

/// Device authorization step — shown on TV while waiting for phone sign-in.
class _DeviceAuthStep extends StatelessWidget {
  const _DeviceAuthStep({
    required this.userCode,
    required this.verificationUri,
    required this.onCancel,
  });

  final String userCode;
  final String verificationUri;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Sign in from your phone',
          style: const TextStyle(color: Colors.white70, fontSize: 15),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2A2A2A)),
          ),
          child: Column(
            children: [
              Text(
                userCode,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 12,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                verificationUri,
                style: const TextStyle(color: Color(0xFF4A9EFF), fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Open the URL above on your phone and enter this code.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white38, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white24,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Waiting…',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _TextLink(label: 'Cancel', onTap: onCancel),
      ],
    );
  }
}

class _EmailStep extends StatelessWidget {
  const _EmailStep({
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.error,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final String? error;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Sign in',
          style: TextStyle(color: Colors.white70, fontSize: 15),
        ),
        const SizedBox(height: 12),
        _LandfallTextField(
          controller: controller,
          focusNode: focusNode,
          hint: 'you@example.com',
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          textInputAction: TextInputAction.send,
          onSubmitted: (_) => onSend(),
          enabled: !isLoading,
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
        ],
        const SizedBox(height: 16),
        LandfallButton(
          label: 'Send code',
          isLoading: isLoading,
          onPressed: onSend,
        ),
      ],
    );
  }
}

class _CodeStep extends StatelessWidget {
  const _CodeStep({
    required this.email,
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.error,
    required this.onVerify,
    required this.onResend,
    required this.onChangeEmail,
  });

  final String email;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final String? error;
  final VoidCallback onVerify;
  final VoidCallback onResend;
  final VoidCallback onChangeEmail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.white70, fontSize: 15),
            children: [
              const TextSpan(text: 'Code sent to '),
              TextSpan(
                text: email,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _LandfallTextField(
          controller: controller,
          focusNode: focusNode,
          hint: '000000',
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onVerify(),
          enabled: !isLoading,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w600,
            letterSpacing: 12,
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
        ],
        const SizedBox(height: 16),
        LandfallButton(
          label: 'Verify',
          isLoading: isLoading,
          onPressed: onVerify,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _TextLink(label: 'Resend code', onTap: onResend),
            const SizedBox(width: 24),
            _TextLink(label: 'Change email', onTap: onChangeEmail),
          ],
        ),
      ],
    );
  }
}

class _LandfallTextField extends StatelessWidget {
  const _LandfallTextField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.autofillHints,
    this.textInputAction,
    this.onSubmitted,
    this.enabled = true,
    this.textAlign = TextAlign.start,
    this.style,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final List<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final TextAlign textAlign;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      autofillHints: autofillHints,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      textAlign: textAlign,
      style: style ?? const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF4A9EFF), width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1A1A1A)),
        ),
      ),
    );
  }
}

class _TextLink extends StatelessWidget {
  const _TextLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white38,
        textStyle: const TextStyle(fontSize: 13, decoration: TextDecoration.underline),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      child: Text(label),
    );
  }
}
