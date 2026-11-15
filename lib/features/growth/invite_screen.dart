import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/invite.dart';
import '../../core/theme.dart';
import 'growth_repository.dart';

/// "Invite and earn": the runner's own code, free slots earned and the
/// referral credit ladder.
class InviteScreen extends StatefulWidget {
  const InviteScreen({super.key});

  @override
  State<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  final _repo = GrowthRepository();
  ReferralSummary? _s;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final s = await _repo.summary();
      if (mounted) setState(() => _s = s);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not load. Check your connection.');
      }
    }
  }

  Future<void> _share(ReferralSummary s) {
    return Share.share(
      'Join me on My Running Journal. Use my code ${s.code} when you '
      'subscribe and get 10% off your first year (then the normal price).\n\n$websiteUrl\n'
      'Google Play: $playStoreUrl',
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _s;
    return Scaffold(
      appBar: AppBar(title: const Text('Invite and earn')),
      body: SafeArea(
        top: false,
        left: false,
        right: false,
        child: s == null
            ? Center(
                child: _error != null
                    ? Text(_error!)
                    : const CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Text(
                      'Share your code. Friends get 10% off their first year, '
                      'and you earn free time and extra race slots.',
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [AppTheme.purple, AppTheme.purpleMid]),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          const Text('YOUR CODE',
                              style: TextStyle(
                                  color: Colors.white70,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          SelectableText(s.code,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(
                                        color: Colors.white70)),
                                onPressed: () async {
                                  await Clipboard.setData(
                                      ClipboardData(text: s.code));
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Code copied')));
                                },
                                icon: const Icon(Icons.copy, size: 18),
                                label: const Text('Copy'),
                              ),
                              const SizedBox(width: 12),
                              FilledButton.icon(
                                style: FilledButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppTheme.purple),
                                onPressed: () => _share(s),
                                icon: const Icon(Icons.share, size: 18),
                                label: const Text('Share'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _section(context, 'Extra race slots',
                        Icons.add_circle_outline),
                    Text(
                      '${s.bonusSlots} of 5 earned. You get a free slot for '
                      'every friend who joins with your code and adds a '
                      'finished race.',
                    ),
                    const SizedBox(height: 20),
                    _section(context, 'Free subscription time',
                        Icons.card_giftcard),
                    Text(
                      '${s.qualified} paid ${s.qualified == 1 ? 'subscriber' : 'subscribers'} '
                      'so far'
                      '${s.pending > 0 ? ' (${s.pending} still in the 30-day check)' : ''}.',
                    ),
                    const SizedBox(height: 6),
                    Text(
                      s.monthsEarned == 0
                          ? 'Your first reward comes at 3 paid subscribers.'
                          : '${s.monthsEarned} free ${s.monthsEarned == 1 ? 'month' : 'months'} earned.',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    if (s.nextTierText != null) Text(s.nextTierText!),
                    if (s.monthsBanked > 0) ...[
                      const SizedBox(height: 6),
                      Text(
                        '${s.monthsBanked} free ${s.monthsBanked == 1 ? 'month' : 'months'} '
                        'waiting. It is added to your next subscription '
                        'renewal, or when you first subscribe.',
                      ),
                    ],
                    const SizedBox(height: 12),
                    _ladder(s.qualified),
                    const SizedBox(height: 16),
                    const Text(
                      'Only new paid subscribers count, once they have kept '
                      'their subscription for 30 days. Refunds do not count. '
                      'Your friends\' 10% off applies to their first year only, '
                      'then their subscription renews at the normal price. '
                      'Free months you earn are a one-time reward, not a '
                      'permanent discount.',
                      style: TextStyle(color: Colors.black54, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _section(BuildContext context, String title, IconData icon) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [
          Icon(icon, color: AppTheme.purple),
          const SizedBox(width: 8),
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
        ]),
      );

  Widget _ladder(int qualified) {
    const tiers = [
      (3, '1 month'),
      (5, '2 months'),
      (10, '3 months (25%)'),
      (20, '4 months (35%)'),
      (30, '6 months (50%)'),
    ];
    return Column(
      children: [
        for (final (n, label) in tiers)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(children: [
              Icon(
                qualified >= n ? Icons.check_circle : Icons.circle_outlined,
                size: 20,
                color: qualified >= n ? Colors.green : Colors.black38,
              ),
              const SizedBox(width: 10),
              Text('$n subscribers'),
              const Spacer(),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            ]),
          ),
      ],
    );
  }
}
