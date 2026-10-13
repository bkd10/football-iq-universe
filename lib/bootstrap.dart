import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/config/supabase_config.dart';

/// Point d'entrée commun aux trois flavors (dev/staging/prod) — voir
/// `main_dev.dart`, `main_staging.dart`, `main_prod.dart`. Centraliser
/// l'initialisation ici évite de la dupliquer par flavor.
Future<void> bootstrap(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseConfig.initialize(config);

  final app = ProviderScope(child: FootballIqUniverseApp(config: config));

  if (config.enableCrashReporting && config.sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = config.sentryDsn;
        options.environment = config.environment.name;
        options.tracesSampleRate = config.isProd ? 0.2 : 1.0;
      },
      appRunner: () => runApp(app),
    );
  } else {
    runApp(app);
  }
}
