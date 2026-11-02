import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../map/map_view.dart';
import '../map/places.dart';
import '../profile/profile_screen.dart';
import '../profile/profile_store.dart';
import '../races/race.dart';
import '../races/race_form_screen.dart';
import '../races/race_list_screen.dart';
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
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _store.load();
    _profile.load();
  }

  @override
  void dispose() {
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
                case 'refresh':
                  _store.load();
                  _profile.load();
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
