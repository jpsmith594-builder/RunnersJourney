import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../home/home_screen.dart';
import 'login_screen.dart';
import 'set_password_screen.dart';

/// Shows the login screen or the journey depending on the auth state. After a
/// password-reset link opens the app, it asks for the new password first.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _recovering = false;
  StreamSubscription<AuthState>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((s) {
      if (s.event == AuthChangeEvent.passwordRecovery && mounted) {
        setState(() => _recovering = true);
      } else if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return const LoginScreen();
    if (_recovering) {
      return SetPasswordScreen(
          onDone: () => setState(() => _recovering = false));
    }
    return const HomeScreen();
  }
}
