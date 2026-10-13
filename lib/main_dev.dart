import 'bootstrap.dart';
import 'core/config/app_config.dart';

/// `flutter run --flavor dev -t lib/main_dev.dart \
///   --dart-define-from-file=env/dev.json`
Future<void> main() async {
  const base = AppConfig(
    environment: Environment.dev,
    supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
    supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
    enableAnalytics: false,
    enableCrashReporting: false,
  );
  await bootstrap(base);
}
