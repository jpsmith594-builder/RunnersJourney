import 'package:flutter/material.dart';

import '../../core/tiles.dart';

/// One question and its answer.
class FaqItem {
  final String question;
  final String answer;
  const FaqItem(this.question, this.answer);
}

/// A group of questions under a heading.
class FaqSection {
  final String title;
  final List<FaqItem> items;
  const FaqSection(this.title, this.items);
}

const faqSections = <FaqSection>[
  FaqSection('Your runner card', [
    FaqItem('How does the rating work?',
        'Your rating is a score from 0 to 1000 that grows slowly as you race. '
            'Points come from:\n'
            '- Finished races: 6 each (up to 250)\n'
            '- Distance raced: 1 per 8 km (up to 200)\n'
            '- Different towns: 4 each (up to 100)\n'
            '- Medals: gold 10, silver 6, bronze 4 (up to 120)\n'
            '- Countries: 10 each (up to 80)\n'
            '- Improvement: up to 250 (see below)\n\n'
            'Only finished races count. Planned races, DNF and DNS do not '
            'add to the score.'),
    FaqItem('What are the categories?',
        'Novice (0), Rookie (80), Club runner (180), Competitor (300), '
            'Veteran (450), Master (650) and Elite (850 and up). Elite is meant '
            'to take years, so there is always a next step. Open Goals to see '
            'how many points you need for the next one.'),
    FaqItem('What is "improvement" and is it fair for slower runners?',
        'Improvement compares you with your own past, not with other people. '
            'For each standard distance (5, 10, 21 and 42 km) you earn up to '
            '40 points for how much your best time beats your first time, and '
            '10 points each time a season\'s best beats every earlier season. '
            'A slower runner earns exactly the same points as a fast one for '
            'the same improvement.'),
    FaqItem('Why did my rating or category change?',
        'The rating is worked out from your races every time you open the '
            'app. Adding a race, a medal, a new town or a faster time can '
            'raise it. Deleting a race lowers it.'),
    FaqItem('How do I share my card?',
        'Open Profile and tap the share button under the card. It makes a '
            'story-sized picture and opens your phone\'s share sheet, so you '
            'can send it to WhatsApp, Instagram, Facebook, TikTok or save it.'),
    FaqItem('How are the badges different from the card categories?',
        'Badges are crests for achievements such as your first marathon, '
            'visiting new provinces or countries, or finishing Comrades. The '
            'card category comes from your overall rating. Both are on your '
            'profile, but they are worked out separately.'),
  ]),
  FaqSection('Subscription', [
    FaqItem('What is free?',
        'You can add up to 5 finished races (completed, DNF or DNS) and 1 '
            'photo per race. Planned races and the race bucket list are always '
            'free. The map, badges, charts, goals, album, runner card and '
            'friends are all included.'),
    FaqItem('What do I get when I go unlimited?',
        'Unlimited finished races and up to 10 photos per race. Everything '
            'else stays the same.'),
    FaqItem('How much does it cost?',
        'In South Africa it is R50 a month or R400 a year. In other countries '
            'it is about \$3 a month or \$25 a year. The exact price for your '
            'country is shown on the Go unlimited screen, and the yearly plan '
            'saves about a third.'),
    FaqItem('Do planned races count towards the 5 free races?',
        'No. Only finished races count. You can plan as many races as you '
            'like.'),
    FaqItem('What happens to my races if I cancel?',
        'Nothing is deleted. When your paid period ends and you have more '
            'than 5 finished races, they all stay, but become read-only. You '
            'can still view and delete them, and everything is editable again '
            'if you subscribe or delete down to 5.'),
    FaqItem('How do I cancel?',
        'Open Google Play, then Payments and subscriptions, pick My Running '
            'Journal and cancel. Deleting the app or your account does not '
            'cancel it.'),
    FaqItem('I changed phone or reinstalled the app.',
        'Sign in with the same email, open Go unlimited and tap Restore '
            'purchases. Your races and photos come back automatically.'),
  ]),
  FaqSection('Races, map and photos', [
    FaqItem('How do I add a race?',
        'Tap the add button on the map or the Races tab. Type the race name, '
            'search for the town, then fill in the date, distance, time, '
            'positions and medal. Any town in the world works.'),
    FaqItem('Why does my race say "not on map"?',
        'It has no town yet. Edit the race and pick a town from the search '
            'box and it will appear on the map.'),
    FaqItem('Can I add several photos at once?',
        'Yes. In a race, choose from the gallery and tick as many photos as '
            'you like. The free plan allows 1 photo per race and a '
            'subscription allows 10.'),
    FaqItem('What is the Journey album?',
        'A photo album that opens like a book, with a page for each finished '
            'race. Swipe to turn the pages, press play to turn them '
            'automatically, and share any page as a picture.'),
    FaqItem('What is "On this day"?',
        'When a finished race took place on today\'s date in an earlier '
            'year, a memory strip shows it at the top of the home screen. You '
            'can close it for the day.'),
    FaqItem('What do the goals count?',
        'Only finished races count towards your distance and races goals for '
            'the year. Planned races are shown as "already planned" but only '
            'count once you have run them.'),
  ]),
  FaqSection('Friends and privacy', [
    FaqItem('Who can see my races and photos?',
        'Only you, and friends you have accepted. Your photos are private to '
            'you. Either side can remove a friendship at any time.'),
    FaqItem('How do I add a friend?',
        'Open Friends, then share your friend code on WhatsApp or type a '
            'friend\'s code to send a request. Once they accept you can see '
            'each other\'s runner card and recent races, and appear on each '
            'other\'s leaderboard.'),
    FaqItem('Does the app track my location?',
        'No. It never uses your live GPS. A race\'s place on the map comes '
            'only from the town you choose.'),
  ]),
  FaqSection('Your account', [
    FaqItem('I forgot my password.',
        'On the sign-in screen tap Forgot password, enter your email and '
            'follow the link in the email.'),
    FaqItem('The confirmation email did not arrive.',
        'Check your spam folder and try again after a few minutes. Make sure '
            'the email address was typed correctly.'),
    FaqItem('How do I delete my account?',
        'Open Profile, then Edit profile, scroll to the bottom and tap '
            'Delete my account. Type DELETE to confirm. All your races, photos '
            'and profile are removed. If you subscribed, cancel in Google Play '
            'first so you are not charged again.'),
    FaqItem('Do I need internet to use the app?',
        'Yes. Your races, photos and the map are loaded from the internet.'),
  ]),
];

/// Questions and answers, grouped by topic.
class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Frequently asked questions')),
      body: SafeArea(
        top: false,
        left: false,
        right: false,
        child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          for (final section in faqSections) ...[
            SectionTitle(section.title),
            SoftCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < section.items.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    Theme(
                      data: Theme.of(context)
                          .copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        childrenPadding:
                            const EdgeInsets.fromLTRB(16, 0, 16, 14),
                        expandedAlignment: Alignment.centerLeft,
                        title: Text(section.items[i].question,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14.5)),
                        children: [
                          Text(section.items[i].answer,
                              style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }
}
