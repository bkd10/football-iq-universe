import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/config/supabase_config.dart';
import 'core/services/auth_link_flags.dart';
import 'core/l10n/l10n.dart';

/// Point d'entrée commun aux trois flavors (dev/staging/prod) — voir
/// `main_dev.dart`, `main_staging.dart`, `main_prod.dart`. Centraliser
/// l'initialisation ici évite de la dupliquer par flavor.
Future<void> bootstrap(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();
  L10n.init();

  // Polices lues dans l'appli (assets/google_fonts), jamais téléchargées
  // chez Google : pas d'adresse IP des joueurs envoyée à un tiers.
  GoogleFonts.config.allowRuntimeFetching = false;
  _registerFontLicenses();

  // Sur le web, Flutter n'active l'accessibilité (lecteurs d'écran,
  // descriptions des images) que sur demande : on l'active d'office.
  if (kIsWeb) SemanticsBinding.instance.ensureSemantics();
  AuthLinkFlags.capture();

  await SupabaseConfig.initialize(config);
  AuthLinkFlags.clearUrl();

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

/// Licences des polices (SIL Open Font License), affichées dans
/// Réglages > Licences.
void _registerFontLicenses() {
  const fonts = {
    'Montserrat': 'montserrat',
    'Inter': 'inter',
    'Barlow Condensed': 'barlowcondensed',
    'Space Mono': 'spacemono',
  };
  LicenseRegistry.addLicense(() async* {
    for (final entry in fonts.entries) {
      final text = await rootBundle.loadString('assets/licenses/OFL_${entry.value}.txt');
      yield LicenseEntryWithLineBreaks([entry.key], text);
    }
  });
}
