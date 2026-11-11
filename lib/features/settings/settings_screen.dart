import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config.dart';
import '../../core/settings.dart';
import '../../core/version.dart';
import '../help/faq_screen.dart';
import '../help/welcome_tour.dart';

/// Distance units, appearance, help and about.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _Heading('Distance'),
            SegmentedButton<DistanceUnit>(
              segments: const [
                ButtonSegment(
                    value: DistanceUnit.km, label: Text('Kilometres')),
                ButtonSegment(value: DistanceUnit.mi, label: Text('Miles')),
              ],
              selected: {settings.unit},
              onSelectionChanged: (s) => settings.setUnit(s.first),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                  'Your races are always stored in kilometres, so you can '
                  'switch at any time without losing anything.',
                  style: TextStyle(fontSize: 12)),
            ),
            const SizedBox(height: 24),
            const _Heading('Appearance'),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.system, label: Text('Phone')),
                ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (s) => settings.setThemeMode(s.first),
            ),
            const SizedBox(height: 24),
            const _Heading('Map'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Vivid map colours'),
              subtitle: const Text('Deeper, richer colours on the map.'),
              value: settings.vividMap,
              onChanged: settings.setVividMap,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Show journey trail'),
              subtitle: const Text(
                  'A faint dotted trail drifts between your races on the map.'),
              value: settings.showTrail,
              onChanged: settings.setShowTrail,
            ),
            const SizedBox(height: 24),
            const _Heading('Help'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.help_outline),
              title: const Text('Frequently asked questions'),
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FaqScreen())),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.explore_outlined),
              title: const Text('Replay the welcome tour'),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  fullscreenDialog: true, builder: (_) => const WelcomeTour())),
            ),
            if (AppConfig.supportEmail.isNotEmpty)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.mail_outline),
                title: const Text('Contact support'),
                subtitle: const Text(AppConfig.supportEmail),
                onTap: () => launchUrl(
                    Uri(scheme: 'mailto', path: AppConfig.supportEmail)),
              ),
            if (AppConfig.privacyUrl.isNotEmpty)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy policy'),
                onTap: () => launchUrl(Uri.parse(AppConfig.privacyUrl),
                    mode: LaunchMode.externalApplication),
              ),
            const SizedBox(height: 24),
            const _Heading('About'),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.directions_run),
              title: Text('My Running Journal'),
              subtitle: Text('Version $appVersion'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  final String text;
  const _Heading(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      );
}
