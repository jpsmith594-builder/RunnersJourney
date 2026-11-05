import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _showPassword = false;
  bool _signUp = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _forgot() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _toast('Type your email address above first, then tap "Forgot password?".');
      return;
    }
    setState(() => _busy = true);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.runnersjourney.app://login-callback/',
      );
      _toast('If that email has an account, a reset link is on its way.');
    } on AuthException catch (e) {
      _toast(e.message);
    } catch (e) {
      _toast('Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.length < 6) {
      _toast('Enter an email and a password of at least 6 characters.');
      return;
    }
    setState(() => _busy = true);
    final auth = Supabase.instance.client.auth;
    try {
      if (_signUp) {
        final res = await auth.signUp(
          email: email,
          password: password,
          // The confirmation link opens the app instead of a web page.
          emailRedirectTo: 'io.runnersjourney.app://login-callback/',
        );
        if (res.session == null && mounted) {
          _toast('Check your email to confirm your account, then sign in.');
          setState(() => _signUp = false);
        }
      } else {
        await auth.signInWithPassword(email: email, password: password);
      }
    } on AuthException catch (e) {
      _toast(e.message);
    } catch (e) {
      _toast('Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF37003C), Color(0xFF6B1B9A), Color(0xFFE90052)],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(24),
                children: [
                  const Icon(Icons.directions_run,
                      size: 72, color: Colors.white),
                  const SizedBox(height: 8),
                  const Text("My Running Journal",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  const Text('Every race, pinned on your map',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF00FF85), fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 24,
                            offset: Offset(0, 10)),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.mail_outline),
                              border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _password,
                          obscureText: !_showPassword,
                          autofillHints: const [AutofillHints.password],
                          onSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              tooltip: _showPassword
                                  ? 'Hide password'
                                  : 'Show password',
                              icon: Icon(_showPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined),
                              onPressed: () =>
                                  setState(() => _showPassword = !_showPassword),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _busy ? null : _submit,
                            child: _busy
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : Text(_signUp ? 'Create account' : 'Sign in'),
                          ),
                        ),
                        if (!_signUp)
                          TextButton(
                            onPressed: _busy ? null : _forgot,
                            child: const Text('Forgot password?'),
                          ),
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => setState(() => _signUp = !_signUp),
                          child: Text(_signUp
                              ? 'Have an account? Sign in'
                              : 'New here? Create an account'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
