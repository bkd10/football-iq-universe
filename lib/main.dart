import 'bootstrap.dart';
import 'core/config/app_config.dart';

/// Entrypoint par défaut : lit l'environnement depuis les `--dart-define`
/// (utile en CI). Pour le développement local, préfère
/// `main_dev.dart` / `main_staging.dart` / `main_prod.dart` avec
/// `--flavor`.
Future<void> main() async {
  await bootstrap(AppConfig.fromDartDefine());
}
