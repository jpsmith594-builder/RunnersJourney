import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme.dart';
import '../../core/tiles.dart';
import '../races/race.dart';
import 'paywall_screen.dart';

/// Races a free runner may keep. Planned races do not count.
const freeRaceLimit = 5;

/// Races that count towards the free limit.
int countedRaces(Iterable<Race> races) =>
    races.where((r) => r.status != RaceStatus.planned).length;

/// A short note for the home screen, or null when there is nothing to say.
String? freePlanNotice(int counted, {required bool subscribed}) {
  if (subscribed) return null;
  if (counted > freeRaceLimit) {
    return 'Your races are read-only. Subscribe to add and edit again.';
  }
  if (counted == freeRaceLimit) {
    return 'You have used all $freeRaceLimit free races. Subscribe to add more.';
  }
  if (counted >= freeRaceLimit - 2) {
    return '$counted of $freeRaceLimit free races used.';
  }
  return null;
}

/// 'free_limit', 'read_only', 'photo_limit' or 'medal_limit' when the database refused a
/// change because of the plan; otherwise null.
String? limitKind(Object e) {
  final text = e is PostgrestException ? '${e.message} ${e.details}' : '$e';
  for (final k in const ['free_limit', 'read_only', 'photo_limit', 'medal_limit']) {
    if (text.contains(k)) return k;
  }
  return null;
}

/// Shows a friendly "upgrade" dialog when [e] is a plan limit. Returns true
/// when it was one (and has been handled).
bool handleLimitError(BuildContext context, Object e) {
  final kind = limitKind(e);
  if (kind == null) return false;
  final (title, body) = switch (kind) {
    'free_limit' => (
        'Free races used up',
        'The free plan holds $freeRaceLimit races. Planned races and your bucket '
            'list are always free. Subscribe to add more.'
      ),
    'read_only' => (
        'Your races are read-only',
        'You have more than $freeRaceLimit races, so they are locked while you are '
            'not subscribed. Nothing is lost. Subscribe to edit and add again, or '
            'delete races to get back to $freeRaceLimit.'
      ),
    'medal_limit' => (
        'Your wall is full',
        'The free plan holds 5 medals on the wall. Subscribers can hang many more.'
      ),
    _ => (
        'Photo limit reached',
        'The free plan holds 1 photo per race. Subscribers can add up to 10.'
      ),
  };
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('Not now')),
        FilledButton(
          onPressed: () {
            Navigator.pop(ctx);
            Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PaywallScreen()));
          },
          child: const Text('See plans'),
        ),
      ],
    ),
  );
  return true;
}

/// Slim bar under the app bar that shows the free-plan allowance.
class FreePlanBanner extends StatelessWidget {
  final String message;
  final VoidCallback onTap;
  const FreePlanBanner({super.key, required this.message, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      onTap: onTap,
      child: Row(
        children: [
          const IconBubble(
              icon: Icons.workspace_premium,
              color: AppTheme.purpleMid,
              size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          Text('Go unlimited',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w800)),
          Icon(Icons.chevron_right,
              color: Theme.of(context).colorScheme.primary, size: 18),
        ],
      ),
    );
  }
}
