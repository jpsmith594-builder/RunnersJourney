import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../bucket/bucket_item.dart';
import '../bucket/bucket_list_screen.dart';
import '../bucket/bucket_store.dart';
import '../calendar/calendar_screen.dart';
import '../calendar/race_event.dart';
import '../friends/friends_screen.dart';
import '../friends/friends_store.dart';
import '../map/map_view.dart';
import '../map/places.dart';
import '../profile/profile_screen.dart';
import '../profile/profile_store.dart';
import '../races/race.dart';
import '../races/race_form_screen.dart';
import '../races/race_list_screen.dart';
import '../races/results_screen.dart';
import '../races/race_store.dart';

/// Main screen after login: Journey (map) and Races tabs, add-race button and
/// a menu with Profile, Refresh and Sign out.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final RaceStore _store = RaceStore();
  final ProfileStore _profile = ProfileStore();
  final BucketStore _bucket = BucketStore();
  final FriendsStore _friends = FriendsStore();
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _store.load();
    _profile.load();
    _bucket.load();
    _friends.load();
  }

  @override
  void dispose() {
    _friends.dispose();
    _bucket.dispose();
    _store.dispose();
    _profile.dispose();
    super.dispose();
  }

  Future<void> _openForm([Race? race, Place? place]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RaceFormScreen(race: race, initialPlace: place),
      ),
    );
    if (changed == true) _store.load();
  }

  void _openCalendar() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CalendarScreen(
          onPlan: (e) async {
            final changed = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => RaceFormScreen(prefill: e)),
            );
            if (changed == true) _store.load();
          },
          onBucket: (e) async {
            final messenger = ScaffoldMessenger.of(context);
            try {
              await _bucket.add(BucketItem(
                  name: e.name, locationName: e.town, distanceKm: e.distanceKm));
              messenger
                ..clearSnackBars()
                ..showSnackBar(
                    SnackBar(content: Text('${e.name} added to your bucket list')));
            } catch (err) {
              messenger.showSnackBar(
                  SnackBar(content: Text('Could not add to bucket list: $err')));
            }
          },
        ),
      ),
    );
  }

  void _openFriends() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FriendsScreen(
          store: _friends,
          myName: _profile.profile.displayName ?? '',
        ),
      ),
    );
  }

  void _openResults() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ResultsScreen(store: _store)),
    );
  }

  void _openBucket() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BucketListScreen(store: _bucket)),
    );
  }

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ProfileScreen(profileStore: _profile, raceStore: _store),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const titles = ['My Journey', 'My Races'];
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_tab]),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  _openProfile();
                case 'calendar':
                  _openCalendar();
                case 'results':
                  _openResults();
                case 'friends':
                  _openFriends();
                case 'bucket':
                  _openBucket();
                case 'refresh':
                  _store.load();
                  _profile.load();
                  _bucket.load();
                  _friends.load();
                case 'signout':
                  Supabase.instance.client.auth.signOut();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.badge_outlined),
                  title: Text('Profile'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'calendar',
                child: ListTile(
                  leading: Icon(Icons.event_outlined),
                  title: Text('Race calendar'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'results',
                child: ListTile(
                  leading: Icon(Icons.table_chart_outlined),
                  title: Text('My results'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'friends',
                child: ListTile(
                  leading: Icon(Icons.group_outlined),
                  title: Text('Friends'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'bucket',
                child: ListTile(
                  leading: Icon(Icons.checklist),
                  title: Text('Race bucket list'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'refresh',
                child: ListTile(
                  leading: Icon(Icons.refresh),
                  title: Text('Refresh'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'signout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Sign out'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: _tab == 0
          ? MapView(
              store: _store,
              bucket: _bucket,
              onEdit: (race) => _openForm(race),
              onAddAtPlace: (place) => _openForm(null, place),
              onShowList: () => setState(() => _tab = 1),
            )
          : ListenableBuilder(
              listenable: _store,
              builder: (context, _) =>
                  RaceListView(store: _store, onEdit: (race) => _openForm(race)),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add race'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map),
              label: 'Journey'),
          NavigationDestination(
              icon: Icon(Icons.format_list_bulleted), label: 'Races'),
        ],
      ),
    );
  }
}
