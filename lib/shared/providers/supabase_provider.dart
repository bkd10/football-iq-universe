import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';

/// Point d'accès unique au client Supabase pour tous les providers de
/// l'app — évite d'appeler `Supabase.instance.client` dispersé partout.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return SupabaseConfig.client;
});
