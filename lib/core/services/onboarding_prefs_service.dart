import 'package:shared_preferences/shared_preferences.dart';

/// Persiste si l'utilisateur a déjà vu l'onboarding, pour ne le montrer
/// qu'une seule fois même après déconnexion.
class OnboardingPrefsService {
  const OnboardingPrefsService._();

  static const _key = 'has_seen_onboarding';

  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  static Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}
