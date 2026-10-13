/// Environnements supportés par l'application.
enum Environment { dev, staging, prod }

/// Configuration globale de l'app, injectée au démarrage selon le flavor.
///
/// Les valeurs proviennent de `--dart-define-from-file=env/<flavor>.json`
/// (voir README.md). Aucun secret n'est codé en dur ici.
class AppConfig {
  const AppConfig({
    required this.environment,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.enableAnalytics,
    required this.enableCrashReporting,
    this.sentryDsn = '',
  });

  final Environment environment;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final bool enableAnalytics;
  final bool enableCrashReporting;
  final String sentryDsn;

  static const _envName = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'dev',
  );

  /// Construit la configuration à partir des `--dart-define` passés au build.
  factory AppConfig.fromDartDefine() {
    final environment = Environment.values.firstWhere(
      (e) => e.name == _envName,
      orElse: () => Environment.dev,
    );

    return AppConfig(
      environment: environment,
      supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
      supabaseAnonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
      enableAnalytics: environment == Environment.prod,
      enableCrashReporting: environment != Environment.dev,
      sentryDsn: const String.fromEnvironment('SENTRY_DSN'),
    );
  }

  bool get isDev => environment == Environment.dev;
  bool get isStaging => environment == Environment.staging;
  bool get isProd => environment == Environment.prod;
}
