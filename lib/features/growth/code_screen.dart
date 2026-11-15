import 'package:flutter/material.dart';

import '../subscription/subscription_store.dart';
import 'growth_repository.dart';

/// "Have a code?" Enter a club code or a friend's referral code. One code per
/// runner, for new subscribers only.
class CodeScreen extends StatefulWidget {
  const CodeScreen({super.key});

  @override
  State<CodeScreen> createState() => _CodeScreenState();
}

class _CodeScreenState extends State<CodeScreen> {
  final _controller = TextEditingController();
  final _repo = GrowthRepository();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final code = _controller.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await _repo.redeem(code);
      await subscription.refresh();
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = codeErrorMessage(e) ?? 'Could not check the code. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Have a code?')),
      body: SafeArea(
        top: false,
        left: false,
        right: false,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Got a club code or a friend\'s invite code? Enter it here to '
              'unlock a discount on your first year.',
            ),
            const SizedBox(height: 8),
            const Text(
              'Club codes give 15% off. Friend codes give 10% off. Only one '
              'code can be used, and codes are for new subscribers. The '
              'discount applies to the first year only. After that the '
              'subscription renews at the normal price.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              enabled: !_busy,
              decoration: InputDecoration(
                labelText: 'Code',
                hintText: 'CLUB-... or REF-...',
                errorText: _error,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _apply(),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _apply,
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 3))
                  : const Text('Apply code'),
            ),
          ],
        ),
      ),
    );
  }
}
