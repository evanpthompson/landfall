import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/auth_cubit.dart';
import '../widgets/landfall_button.dart';

/// Full-screen login UI.
///
/// Two-step OTP flow:
///   1. Email entry → tap "Send code" → [AuthCodeSent]
///   2. 6-digit code entry → tap "Verify" → [AuthAuthenticated]
///
/// Errors are shown inline; the cubit holds previous state so tapping
/// "Try again" returns to the correct step.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _emailFocus = FocusNode();
  final _codeFocus = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _emailFocus.dispose();
    _codeFocus.dispose();
    super.dispose();
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
                _emailFocus.requestFocus();
              }
              if (state is AuthError && state.previous is AuthCodeSent) {
                _codeController.clear();
                _codeFocus.requestFocus();
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
