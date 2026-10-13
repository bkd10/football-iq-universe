import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Persistance de la session Supabase (access/refresh tokens) dans le
/// keychain/keystore du device plutôt que dans SharedPreferences (le
/// comportement par défaut du SDK) — voir PARTIE 14.1 de la spécification.
class SecureLocalStorage extends LocalStorage {
  SecureLocalStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _sessionKey = 'fiu_supabase_session';

  final FlutterSecureStorage _storage;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() {
    return _storage.containsKey(key: _sessionKey);
  }

  @override
  Future<String?> accessToken() {
    return _storage.read(key: _sessionKey);
  }

  @override
  Future<void> persistSession(String persistSessionString) {
    return _storage.write(key: _sessionKey, value: persistSessionString);
  }

  @override
  Future<void> removePersistedSession() {
    return _storage.delete(key: _sessionKey);
  }
}
