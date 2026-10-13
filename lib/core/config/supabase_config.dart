import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/secure_local_storage.dart';
import 'app_config.dart';

/// Initialise le client Supabase pour toute la durée de vie de l'app.
///
/// Appelé une seule fois dans `main.dart` avant `runApp`.
class SupabaseConfig {
  const SupabaseConfig._();

  static Future<void> initialize(AppConfig config) async {
    await Supabase.initialize(
      url: config.supabaseUrl,
      publishableKey: config.supabaseAnonKey,
      debug: config.isDev,
      authOptions: FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        localStorage: SecureLocalStorage(),
      ),
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
