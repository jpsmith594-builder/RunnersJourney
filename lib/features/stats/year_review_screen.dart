import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../profile/share_card.dart';
import '../races/race.dart';
import '../races/race_store.dart';
import 'year_review.dart';
import '../../core/invite.dart';
import '../../core/units.dart';

/// "My year in running": a shareable poster of the year's numbers.
class YearReviewScreen extends StatefulWidget {
  final RaceStore store;
  final String name;
  const YearReviewScreen({super.key, required this.store, required this.name});

  @override
  State<YearReviewScreen> createState() => _YearReviewScreenState();
}

class _YearReviewScreenState extends State<YearReviewScreen> {
  final GlobalKey _posterKey = GlobalKey();
  int? _year;
  PageController? _pc;
  int _pcLen = 0;

  @override
  void dispose() {
    _pc?.dispose();
    super.dispose();
  }

  String _hours(int secs) {
    final h = secs ~/ 3600;
    final m = (secs % 3600) ~/ 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final years = yearsWithRaces(widget.store.races);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Year in review'),
        actions: [
          if (years.isNotEmpty)
            IconButton(
              tooltip: 'Share',
              icon: const Icon(Icons.ios_share),
              onPressed: () => shareRunnerCard(
                context,
                _posterKey,
                message: 'My ${_year ?? years.first} in running, in My Running Journal.',
              ),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        left: false,
        right: false,
        child: ListenableBuilder(
        listenable: widget.store,
        builder: (context, _) {
          final years = yearsWithRaces(widget.store.races);
          if (years.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                    'Finish a race and your year in review will appear here.',
                    textAlign: TextAlign.center),
              ),
            );
          }
          final year = years.contains(_year) ? _year! : years.first;
          final idx = years.indexOf(year);
          if (_pc == null || _pcLen != years.length) {
            _pc?.dispose();
            _pc = PageController(initialPage: idx);
            _pcLen = years.length;
          }
          return Column(
            children: [
              if (years.length > 1)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (var i = 0; i < years.length; i++) ...[
                          ChoiceChip(
                            label: Text('${years[i]}'),
                            selected: years[i] == year,
                            onSelected: (_) => _pc!.animateToPage(i,
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeOutCubic),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                ),
              if (years.length > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('Swipe the card to change year',
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5))),
                ),
              Expanded(
                child: PageView.builder(
                  controller: _pc,
                  itemCount: years.length,
                  onPageChanged: (i) => setState(() => _year = years[i]),
                  itemBuilder: (context, i) {
                    final s = summarize(widget.store.races, years[i]);
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 380),
                          child: RepaintBoundary(
                            // Only the card on screen is the one that is shared.
                            key: i == idx ? _posterKey : null,
                            child: _Poster(
                              summary: s,
                              name: widget.name,
                              hours: _hours(s.totalSeconds),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      ),
    );
  }
}

class _Poster extends StatelessWidget {
  final YearSummary summary;
  final String name;
  final String hours;
  const _Poster(
      {required this.summary, required this.name, required this.hours});

  Widget _big(String value, String label) => Expanded(
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900)),
            ),
            const SizedBox(height: 2),
            Text(label.toUpperCase(),
                style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 10,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      );

  Widget _line(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF00FF85)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style: const TextStyle(color: Colors.white, fontSize: 14)),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final longest = s.longest;
    final fast = s.fastestPace;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 2),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6B1B9A), Color(0xFF37003C)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${s.year}',
              style: const TextStyle(
                  color: Color(0xFF00FF85),
                  fontSize: 54,
                  fontWeight: FontWeight.w900,
                  height: 1)),
          const Text('YOUR YEAR IN RUNNING',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.w700)),
          if (name.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(name.trim(),
                style: const TextStyle(color: Colors.white, fontSize: 16)),
          ],
          const SizedBox(height: 22),
          Row(children: [
            _big('${s.races}', s.races == 1 ? 'race' : 'races'),
            _big(formatNumber(toUnit(s.km)), unitLabel()),
            _big(s.totalSeconds > 0 ? hours : '-', 'racing'),
          ]),
          const SizedBox(height: 22),
          if (s.towns > 0)
            _line(Icons.place,
                '${s.towns} town${s.towns == 1 ? '' : 's'}'
                '${s.provinces > 0 ? ' in ${s.provinces} province${s.provinces == 1 ? '' : 's'}' : ''}'),
          if (longest != null)
            _line(Icons.straighten,
                'Longest: ${longest.name} (${formatDistance(longest.distanceKm!)})'),
          if (fast != null)
            _line(Icons.bolt, 'Fastest pace: ${fast.pace} at ${fast.name}'),
          if (s.busiestMonth != null && s.busiestMonthRaces > 1)
            _line(Icons.calendar_month,
                'Busiest month: ${DateFormat.MMMM().format(DateTime(2000, s.busiestMonth!))} '
                '(${s.busiestMonthRaces} races)'),
          for (final e in s.pbs.entries)
            _line(Icons.emoji_events,
                '${e.key} best: ${formatDuration(e.value)}'),
          const SizedBox(height: 14),
          const Center(
            child: Text('MY RUNNING JOURNAL',
                style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 10),
          const InviteFooter(compact: true),
        ],
      ),
    );
  }
}
