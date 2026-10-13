import 'bootstrap.dart';
import 'core/config/app_config.dart';

/// `flutter build appbundle --flavor prod -t lib/main_prod.dart \
///   --dart-define-from-file=env/prod.json`
Future<void> main() async {
  const base = AppConfig(
    environment: Environment.prod,
    supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
    supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
    enableAnalytics: true,
    enableCrashReporting: true,
    sentryDsn: String.fromEnvironment('SENTRY_DSN'),
  );
  await bootstrap(base);
}
