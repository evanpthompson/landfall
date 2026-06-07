import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/auth_cubit.dart';
import '../screens/web_login_screen.dart';

/// Shows [child] when authenticated, [WebLoginScreen] otherwise.
///
/// Used as the entry gate for the web settings UI. Anonymous companion features
/// outside this gate are unaffected.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) return child;
        return const WebLoginScreen();
      },
    );
  }
}
