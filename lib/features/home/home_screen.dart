import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../bucket/bucket_item.dart';
import '../bucket/bucket_list_screen.dart';
import '../bucket/bucket_store.dart';
import '../album/album_screen.dart';
import '../calendar/calendar_screen.dart';
import '../calendar/show_sa_races.dart';
import '../friends/friends_screen.dart';
import '../goals/goal_store.dart';
import '../../core/settings.dart';
import '../help/faq_screen.dart';
import '../settings/settings_screen.dart';
import '../goals/goal_strip.dart';
import '../goals/goals_screen.dart';
import '../stats/badges_screen.dart';
import '../stats/charts_screen.dart';
import '../stats/year_review_screen.dart';
import 'on_this_day_banner.dart';
import 'upcoming_banner.dart';
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
import '../subscription/limits.dart';
import '../subscription/paywall_screen.dart';
import '../subscription/subscription_store.dart';

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
  final GoalStore _goals = GoalStore();
  final FriendsStore _friends = FriendsStore();
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _store.load();
    _profile.load();
    _bucket.load();
    _goals.load();
    _friends.load();
    subscription.init();
  }

  void _openPaywall() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const PaywallScreen()));
  }

  @override
  void dispose() {
    _friends.dispose();
    _bucket.dispose();
    _goals.dispose();
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
          onAddOwn: (name) async {
            final changed = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                  builder: (_) => RaceFormScreen(initialName: name)),
            );
            if (changed == true) _store.load();
          },
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
          myRaces: () => _store.races,
          myClub: _profile.profile.club,
        ),
      ),
    );
  }

  void _openAlbum() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AlbumScreen(
          store: _store,
          name: _profile.profile.displayName ?? '',
        ),
      ),
    );
  }

  void _openCharts() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ChartsScreen(store: _store)),
    );
  }

  void _openGoals() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GoalsScreen(races: _store, goals: _goals),
      ),
    );
  }

  void _openBadges() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BadgesScreen(store: _store)),
    );
  }

  void _openReview() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => YearReviewScreen(
          store: _store,
          name: _profile.profile.displayName ?? '',
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
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: settings,
        builder: (context, _) => _buildHome(context),
      );

  Widget _buildHome(BuildContext context) {
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
                case 'review':
                  _openReview();
                case 'badges':
                  _openBadges();
                case 'charts':
                  _openCharts();
                case 'goals':
                  _openGoals();
                case 'faq':
                  Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const FaqScreen()));
                case 'settings':
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const SettingsScreen()));
                case 'album':
                  _openAlbum();
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
                  _goals.load();
                  _friends.load();
                  subscription.refresh();
                case 'plan':
                  _openPaywall();
                case 'signout':
                  subscription.reset();
                  Supabase.instance.client.auth.signOut();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.badge_outlined),
                  title: Text('Profile'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              if (showSouthAfricanRaces(
                races: _store.races,
                homeTown: _profile.profile.homeTown,
                localeCountry:
                    WidgetsBinding.instance.platformDispatcher.locale.countryCode,
              ))
                const PopupMenuItem(
                value: 'calendar',
                child: ListTile(
                  leading: Icon(Icons.event_outlined),
                  title: Text('South African races'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'review',
                child: ListTile(
                  leading: Icon(Icons.auto_awesome_outlined),
                  title: Text('Year in review'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'badges',
                child: ListTile(
                  leading: Icon(Icons.workspace_premium_outlined),
                  title: Text('Badges'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'charts',
                child: ListTile(
                  leading: Icon(Icons.insights),
                  title: Text('Charts'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'faq',
                child: ListTile(
                  leading: Icon(Icons.help_outline),
                  title: Text('Frequently asked questions'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'goals',
                child: ListTile(
                  leading: Icon(Icons.flag_outlined),
                  title: Text('Goals'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'album',
                child: ListTile(
                  leading: Icon(Icons.auto_stories),
                  title: Text('Journey album'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'results',
                child: ListTile(
                  leading: Icon(Icons.table_chart_outlined),
                  title: Text('My results'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'friends',
                child: ListTile(
                  leading: Icon(Icons.group_outlined),
                  title: Text('Friends'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'bucket',
                child: ListTile(
                  leading: Icon(Icons.checklist),
                  title: Text('Race bucket list'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings_outlined),
                  title: Text('Settings'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'plan',
                child: ListTile(
                  leading: Icon(Icons.workspace_premium_outlined),
                  title: Text('Go unlimited'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'refresh',
                child: ListTile(
                  leading: Icon(Icons.refresh),
                  title: Text('Refresh'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
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
      body: Column(
        children: [
          ListenableBuilder(
            listenable: Listenable.merge([_store, subscription]),
            builder: (context, _) {
              final note = freePlanNotice(countedRaces(_store.races),
                  subscribed: subscription.active);
              return Column(
                children: [
                  if (note != null)
                    FreePlanBanner(message: note, onTap: _openPaywall),
                  UpcomingBanner(races: _store.races),
                  OnThisDayBanner(races: _store.races),
                  GoalStrip(races: _store, goals: _goals, onTap: _openGoals),
                ],
              );
            },
          ),
          Expanded(
            child: _tab == 0
                ? MapView(
                    store: _store,
                    bucket: _bucket,
                    onEdit: (race) => _openForm(race),
                    onAddAtPlace: (place) => _openForm(null, place),
                    onShowList: () => setState(() => _tab = 1),
                  )
                : ListenableBuilder(
                    listenable: _store,
                    builder: (context, _) => RaceListView(
                        store: _store, onEdit: (race) => _openForm(race)),
                  ),
          ),
        ],
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
