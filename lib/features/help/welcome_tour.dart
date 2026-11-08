import 'package:flutter/material.dart';

class TourPage {
  final IconData icon;
  final String title;
  final String body;
  const TourPage(this.icon, this.title, this.body);
}

const tourPages = [
  TourPage(Icons.map_outlined, 'Your life on a map',
      'Every race you add becomes a pin on the map. Over the years the map '
          'fills up with the places your running has taken you.'),
  TourPage(Icons.add_circle_outline, 'Add a race in a minute',
      'Tap the + button, pick the race, add your time, and a photo or two. '
          'Planning one? Mark it as upcoming and finish it later.'),
  TourPage(Icons.auto_stories_outlined, 'Your story, not just numbers',
      'Flip through your Journey album, relive a year in review, and see '
          'what you ran on this day in past years.'),
  TourPage(Icons.badge_outlined, 'Grow your runner card',
      'Races, distance, new towns, medals and improvement build your rating '
          'from Novice towards Elite. It is a long journey, enjoy it.'),
  TourPage(Icons.flag_outlined, 'Set goals, share with friends',
      'Set a yearly goal in the menu, add friends to see their journeys, and '
          'share your card whenever you are proud of it.'),
];

/// A short swipe-through shown once after a runner first opens the app.
class WelcomeTour extends StatefulWidget {
  const WelcomeTour({super.key});

  @override
  State<WelcomeTour> createState() => _WelcomeTourState();
}

class _WelcomeTourState extends State<WelcomeTour> {
  final _controller = PageController();
  int _page = 0;

  bool get _last => _page == tourPages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(_last ? '' : 'Skip'),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  for (final p in tourPages)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                                color: scheme.primaryContainer,
                                shape: BoxShape.circle),
                            child: Icon(p.icon,
                                size: 72, color: scheme.onPrimaryContainer),
                          ),
                          const SizedBox(height: 32),
                          Text(p.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 12),
                          Text(p.body,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16, height: 1.4)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < tourPages.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.all(4),
                    width: i == _page ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: i == _page
                            ? scheme.primary
                            : scheme.outlineVariant,
                        borderRadius: BorderRadius.circular(4)),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (_last) {
                      Navigator.of(context).pop();
                    } else {
                      _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut);
                    }
                  },
                  child: Text(_last ? 'Start my journey' : 'Next'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
