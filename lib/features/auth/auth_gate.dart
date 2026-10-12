import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../races/race_list_screen.dart';
import 'login_screen.dart';

/// Shows the login screen or the journey depending on the auth state.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;
        return session == null ? const LoginScreen() : const RaceListScreen();
      },
    );
  }
}
