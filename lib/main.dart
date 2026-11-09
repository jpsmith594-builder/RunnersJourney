import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config.dart';
import 'core/errors.dart';
import 'core/settings.dart';
import 'core/theme.dart';
import 'features/auth/auth_gate.dart';

Future<void> main() async {
  if (AppConfig.sentryDsn.isEmpty) {
    await _start();
    return;
  }
  // Crash reports: no personal details, no screenshots, no breadcrumbs of
  // what was typed. Only the error, the app version and the phone model.
  await SentryFlutter.init(
    (o) {
      o.dsn = AppConfig.sentryDsn;
      o.sendDefaultPii = false;
      o.attachScreenshot = false;
      o.tracesSampleRate = 0;
      o.maxBreadcrumbs = 20;
      o.beforeSend = (event, hint) {
        // Offline errors are not bugs.
        final e = event.throwable;
        if (e != null && isOffline(e)) return null;
        return event;
      };
    },
    appRunner: _start,
  );
}

Future<void> _start() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!AppConfig.isConfigured) {
    runApp(const _MissingConfigApp());
    return;
  }

  await settings.load();
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabaseAnonKey,
  );
  runApp(const RunnersJourneyApp());
}

class RunnersJourneyApp extends StatelessWidget {
  const RunnersJourneyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => MaterialApp(
        title: "My Running Journal",
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: settings.themeMode,
        home: const AuthGate(),
      ),
    );
  }
}

class _MissingConfigApp extends StatelessWidget {
  const _MissingConfigApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Supabase is not configured.\n\n'
              'Run with:\nflutter run --dart-define-from-file=env.json',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
