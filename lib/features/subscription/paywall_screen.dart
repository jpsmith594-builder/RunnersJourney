import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme.dart';
import 'limits.dart';
import 'subscription_store.dart';

/// Shows the plans (R50 a month or R400 a year in South Africa; $3 or $25 elsewhere) and starts the purchase.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _yearly = true;

  @override
  void initState() {
    super.initState();
    if (subscription.storeAvailable &&
        subscription.monthly == null &&
        subscription.yearly == null) {
      subscription.init();
    }
  }

  Widget _benefit(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.cyan),
            const SizedBox(width: 12),
            Expanded(
                child: Text(text,
                    style: const TextStyle(color: Colors.white, fontSize: 16))),
          ],
        ),
      );

  Widget _plan({
    required bool selected,
    required String title,
    required String price,
    required String note,
    String? badge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white12,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: selected ? AppTheme.cyan : Colors.white54,
              width: selected ? 3 : 1.5),
        ),
        child: Row(
          children: [
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppTheme.purple : Colors.white70),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(title,
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: selected ? AppTheme.purple : Colors.white)),
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                            color: AppTheme.magenta,
                            borderRadius: BorderRadius.circular(10)),
                        child: Text(badge,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ]),
                  Text(note,
                      style: TextStyle(
                          color: selected ? Colors.black54 : Colors.white70)),
                ],
              ),
            ),
            Text(price,
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: selected ? AppTheme.purple : Colors.white)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Running Journal'),
        backgroundColor: AppTheme.purple,
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(
            color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.purple, AppTheme.purpleMid],
          ),
        ),
        child: ListenableBuilder(
          listenable: subscription,
          builder: (context, _) {
            final s = subscription;
            if (s.active) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.workspace_premium,
                          size: 72, color: AppTheme.cyan),
                      const SizedBox(height: 12),
                      Text(
                          s.isAdmin
                              ? 'Admin account'
                              : (s.hasGift ? 'Premium account' : 'You are subscribed'),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Text(
                          s.hasGift
                              ? 'Unlimited races and up to 10 photos per race, included with your account.'
                              : 'Unlimited races and up to 10 photos per race. Thank you for supporting the app!',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 20),
                      if (!s.hasGift)
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white)),
                        onPressed: () => launchUrl(
                            Uri.parse(
                                'https://play.google.com/store/account/subscriptions'),
                            mode: LaunchMode.externalApplication),
                        child: const Text('Manage subscription'),
                      ),
                    ],
                  ),
                ),
              );
            }
            final yearlyPrice = s.yearly?.storeProduct.priceString ?? 'R400';
            final monthlyPrice = s.monthly?.storeProduct.priceString ?? 'R50';
            final chosen = _yearly ? s.yearly : s.monthly;
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text('Go unlimited',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                const Text(
                    'The free plan keeps $freeRaceLimit finished races. Planned races and the bucket list are always free.',
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 16),
                _benefit(Icons.all_inclusive, 'Unlimited races in your journey'),
                _benefit(Icons.photo_library_outlined,
                    'Up to 10 photos per race (free: 1)'),
                _benefit(Icons.edit_outlined,
                    'Keep editing every race, always'),
                const SizedBox(height: 20),
                _plan(
                  selected: _yearly,
                  title: 'Yearly',
                  price: '$yearlyPrice / year',
                  note: 'Best value, about R21 a month',
                  badge: 'SAVE 30%',
                  onTap: () => setState(() => _yearly = true),
                ),
                _plan(
                  selected: !_yearly,
                  title: 'Monthly',
                  price: '$monthlyPrice / month',
                  note: 'Cancel any time',
                  onTap: () => setState(() => _yearly = false),
                ),
                const SizedBox(height: 8),
                if (!s.storeAvailable)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                        'Subscriptions are not switched on in this build yet.',
                        style: TextStyle(color: AppTheme.cyan)),
                  ),
                if (s.message != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(s.message!,
                        style: const TextStyle(color: AppTheme.cyan)),
                  ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.purple,
                  ),
                  onPressed:
                      (s.busy || chosen == null) ? null : () => s.purchase(chosen),
                  child: s.busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 3))
                      : Text(_yearly ? 'Subscribe yearly' : 'Subscribe monthly'),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  onPressed: s.busy ? null : s.restore,
                  child: const Text('Restore purchases'),
                ),
                const SizedBox(height: 8),
                const Text(
                    'Billed through Google Play and renews until you cancel. If you cancel, '
                    'your races are kept safe but become read-only once the paid period ends.',
                    style: TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            );
          },
        ),
      ),
    );
  }
}
