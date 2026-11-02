import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../journey/journey_view.dart';
import '../races/race.dart';
import '../races/race_form_screen.dart';
import '../races/race_list_screen.dart';
import '../races/race_store.dart';

/// Main screen after login: Journey and Races tabs, add-race button and menu.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final RaceStore _store = RaceStore();
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _store.load();
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  Future<void> _openForm([Race? race]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => RaceFormScreen(race: race)),
    );
    if (changed == true) _store.load();
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['My Journey', 'My Races'];
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_tab]),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'refresh') _store.load();
              if (value == 'signout') {
                Supabase.instance.client.auth.signOut();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'refresh', child: Text('Refresh')),
              PopupMenuItem(value: 'signout', child: Text('Sign out')),
            ],
          ),
        ],
      ),
      body: _tab == 0
          ? JourneyView(store: _store, onEdit: _openForm)
          : ListenableBuilder(
              listenable: _store,
              builder: (context, _) =>
                  RaceListView(store: _store, onEdit: _openForm),
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
