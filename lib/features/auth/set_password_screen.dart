import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors.dart';

/// Shortest password accepted when creating an account or setting a new one.
/// Sign-in does not enforce it, so people who registered earlier can still
/// get in.
const minPasswordLength = 8;

/// Null when the new password is fine, otherwise what is wrong with it.
String? passwordProblem(String password, String again) {
  if (password.length < minPasswordLength) {
    return 'Use at least $minPasswordLength characters.';
  }
  if (password != again) return 'The two passwords do not match.';
  return null;
}

/// Shown after the runner taps the reset link in their email.
class SetPasswordScreen extends StatefulWidget {
  final VoidCallback onDone;
  const SetPasswordScreen({super.key, required this.onDone});

  @override
  State<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends State<SetPasswordScreen> {
  final _pw = TextEditingController();
  final _again = TextEditingController();
  bool _busy = false;
  bool _show = false;

  @override
  void dispose() {
    _pw.dispose();
    _again.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final problem = passwordProblem(_pw.text, _again.text);
    if (problem != null) {
      _toast(problem);
      return;
    }
    setState(() => _busy = true);
    try {
      await Supabase.instance.client.auth
          .updateUser(UserAttributes(password: _pw.text));
      if (mounted) {
        _toast('Password changed.');
        widget.onDone();
      }
    } on AuthException catch (e) {
      _toast(e.message);
    } catch (e) {
      _toast(failMessage('Something went wrong', e));
    }
    if (mounted) setState(() => _busy = false);
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New password')),
      body: SafeArea(
        top: false,
        left: false,
        right: false,
        child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Choose a new password for your account.'),
          const SizedBox(height: 16),
          TextField(
            controller: _pw,
            obscureText: !_show,
            decoration: InputDecoration(
              labelText: 'New password',
              prefixIcon: const Icon(Icons.lock_outline),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                tooltip: _show ? 'Hide password' : 'Show password',
                icon: Icon(_show
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                onPressed: () => setState(() => _show = !_show),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _again,
            obscureText: !_show,
            onSubmitted: (_) => _save(),
            decoration: const InputDecoration(
                labelText: 'Repeat new password',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: _busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save new password'),
          ),
        ],
      ),
      ),
    );
  }
}
