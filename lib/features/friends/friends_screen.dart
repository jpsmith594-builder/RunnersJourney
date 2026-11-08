import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../clubs/club_mates.dart';
import '../clubs/club_mates_section.dart';
import 'friend_card_screen.dart';
import 'friend_entry.dart';
import 'friends_store.dart';
import 'leaderboard_screen.dart';
import '../races/race.dart';

/// Add friends with a friend code, invite people by WhatsApp, answer requests
/// and open a friend's runner card.
class FriendsScreen extends StatefulWidget {
  final FriendsStore store;
  final String myName;
  final List<Race> Function() myRaces;

  /// The club name on the runner's profile, if any.
  final String? myClub;
  const FriendsScreen(
      {super.key,
      required this.store,
      required this.myName,
      required this.myRaces,
      this.myClub});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _codeField = TextEditingController();
  final _clubMates = ClubMatesStore();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    widget.store.load();
    _clubMates.load();
  }

  @override
  void dispose() {
    _codeField.dispose();
    _clubMates.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  String get _inviteText {
    final who = widget.myName.trim().isEmpty ? 'I' : widget.myName.trim();
    return '$who invited you to My Running Journal, the app that pins your '
        'races on a map of the world. Install it, then add me as a friend '
        'with my friend code: ${widget.store.code}';
  }

  Future<void> _whatsApp() async {
    final uri = Uri.parse(
        'https://wa.me/?text=${Uri.encodeComponent(_inviteText)}');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) _toast('Could not open WhatsApp. Use Copy invite instead.');
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _inviteText));
    _toast('Invite copied. Paste it into any chat or message.');
  }

  Future<void> _add() async {
    final code = _codeField.text.trim();
    if (code.isEmpty) return;
    setState(() => _busy = true);
    try {
      final name = await widget.store.addByCode(code);
      _codeField.clear();
      final accepted = widget.store.friends.any((f) => f.name == name);
      _toast(accepted
          ? 'You and $name are now friends.'
          : 'Request sent to $name.');
    } catch (e) {
      final msg = e.toString();
      _toast(msg.contains('No runner')
          ? 'No runner found with that code.'
          : msg.contains('own code')
              ? 'That is your own code.'
              : 'Could not add friend: $msg');
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _confirmRemove(FriendEntry e, String title) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(e.name),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Yes')),
        ],
      ),
    );
    if (ok == true) await widget.store.remove(e);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        actions: [
          IconButton(
            tooltip: 'Leaderboard',
            icon: const Icon(Icons.leaderboard_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => LeaderboardScreen(
                friends: widget.store.friends,
                myName: widget.myName,
                myRaces: widget.myRaces(),
              ),
            )),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.store,
        builder: (context, _) {
          final s = widget.store;
          return RefreshIndicator(
            onRefresh: s.load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (s.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Could not load friends: ${s.error}\n'
                      '(Have you run supabase/006_friends.sql?)',
                      style: t.bodySmall,
                    ),
                  ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your friend code', style: t.labelLarge),
                        const SizedBox(height: 6),
                        SelectableText(
                          s.code.isEmpty ? '...' : s.code,
                          style: t.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w900, letterSpacing: 4),
                        ),
                        const SizedBox(height: 4),
                        Text(
                            'Friends who add this code can see your runner card and races.',
                            style: t.bodySmall),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilledButton.icon(
                              onPressed: s.code.isEmpty ? null : _whatsApp,
                              icon: const Icon(Icons.chat),
                              label: const Text('Invite on WhatsApp'),
                            ),
                            OutlinedButton.icon(
                              onPressed: s.code.isEmpty ? null : _copy,
                              icon: const Icon(Icons.copy),
                              label: const Text('Copy invite'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Add a friend', style: t.titleMedium),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _codeField,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                            labelText: 'Their friend code',
                            border: OutlineInputBorder()),
                        onSubmitted: (_) => _add(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _busy ? null : _add,
                      child: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Add'),
                    ),
                  ],
                ),
                ClubMatesSection(
                  store: _clubMates,
                  clubName: widget.myClub,
                  onFriendsChanged: s.load,
                ),
                if (s.requests.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('Friend requests', style: t.titleMedium),
                  for (final e in s.requests)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(child: Icon(Icons.person_add)),
                      title: Text(e.name),
                      subtitle: const Text('wants to be your friend'),
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          IconButton(
                            tooltip: 'Accept',
                            icon: const Icon(Icons.check_circle,
                                color: Colors.green),
                            onPressed: () => s.accept(e),
                          ),
                          IconButton(
                            tooltip: 'Decline',
                            icon: const Icon(Icons.cancel_outlined),
                            onPressed: () => s.remove(e),
                          ),
                        ],
                      ),
                    ),
                ],
                const SizedBox(height: 20),
                Text('My friends (${s.friends.length})', style: t.titleMedium),
                if (s.friends.isEmpty && !s.loading)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                        'No friends yet. Share your code or invite someone on WhatsApp.',
                        style: t.bodyMedium),
                  ),
                for (final e in s.friends)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                        child: Text(e.name.isEmpty ? 'R' : e.name[0].toUpperCase())),
                    title: Text(e.name),
                    subtitle: const Text('Tap to see their runner card'),
                    trailing: IconButton(
                      tooltip: 'Remove friend',
                      icon: const Icon(Icons.person_remove_outlined),
                      onPressed: () => _confirmRemove(e, 'Remove friend?'),
                    ),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => FriendCardScreen(entry: e))),
                  ),
                if (s.sent.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('Waiting for a reply', style: t.titleMedium),
                  for (final e in s.sent)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(child: Icon(Icons.hourglass_top)),
                      title: Text(e.name),
                      trailing: IconButton(
                        tooltip: 'Cancel request',
                        icon: const Icon(Icons.close),
                        onPressed: () => _confirmRemove(e, 'Cancel request?'),
                      ),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
