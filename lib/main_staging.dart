import 'bootstrap.dart';
import 'core/config/app_config.dart';

/// `flutter run --flavor staging -t lib/main_staging.dart \
///   --dart-define-from-file=env/staging.json`
Future<void> main() async {
  const base = AppConfig(
    environment: Environment.staging,
    supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
    supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
    enableAnalytics: false,
    enableCrashReporting: true,
    sentryDsn: String.fromEnvironment('SENTRY_DSN'),
  );
  await bootstrap(base);
}
