import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config.dart';
import '../../core/settings.dart';
import '../help/faq_screen.dart';

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
            const _Heading('Help'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.help_outline),
              title: const Text('Frequently asked questions'),
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FaqScreen())),
            ),
            if (AppConfig.supportEmail.isNotEmpty)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.mail_outline),
                title: const Text('Contact support'),
                subtitle: Text(AppConfig.supportEmail),
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
              subtitle: Text('Version 0.1.0'),
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
