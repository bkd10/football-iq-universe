/// Chemins et noms de routes centralisés pour GoRouter.
///
/// Centraliser ces valeurs évite les chaînes de caractères en dur dispersées
/// dans les écrans et facilite le deep linking.
class RouteNames {
  const RouteNames._();

  // Auth & onboarding
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String confirmEmail = '/confirm-email';
  // Retour du lien de confirmation d'e-mail (web) — voir
  // `AuthCallbackScreen`. Supabase redirige ici avec `?code=...` (PKCE) ou
  // `?error=...` (lien expiré/invalide).
  static const String authCallback = '/auth/callback';

  // Shell principal (bottom navigation)
  static const String feed = '/feed';
  static const String challenges = '/challenges';
  static const String create = '/create';
  static const String rankings = '/rankings';
  static const String profile = '/profile';

  // Moves
  static const String moveDetail = '/move/:moveId';
  static String moveDetailPath(String moveId) => '/move/$moveId';
  static const String trendingMoves = '/moves/trending';

  // Défis
  static const String challengeDetail = '/challenge/:challengeId';
  static String challengeDetailPath(String challengeId) => '/challenge/$challengeId';
  static const String createChallenge = '/challenges/create';

  // Vidéo
  static const String videoDetail = '/video/:videoId';
  static String videoDetailPath(String videoId) => '/video/$videoId';

  // Profil d'un autre joueur (Football Passport public)
  static const String otherProfile = '/user/:userId';
  static String otherProfilePath(String userId) => '/user/$userId';

  static const String editProfile = '/profile/edit';
  static const String dailyMissions = '/missions';
  static const String notifications = '/notifications';
  static const String wallet = '/wallet';
  static const String earnBallons = '/wallet/earn';
  static const String shop = '/wallet/shop';
  static const String settings = '/settings';
  static const String search = '/search';
  static const String pepiteOfTheDay = '/pepite';

  // Messagerie joueur ↔ recruteur
  static const String inbox = '/messages';
  static const String conversation = '/messages/:conversationId';
  static String conversationPath(String conversationId) =>
      '/messages/$conversationId';
  static const String guardianApprovalEntry = '/guardian-approval';
  static const String guardianApproval = '/guardian-approval/:token';
  static String guardianApprovalPath(String token) =>
      '/guardian-approval/$token';

  // Recruteur (scout) — le Football Passport d'un joueur reste
  // `otherProfilePath` (déjà existant) : le bouton "Demander le contact" sur
  // `ProfileScreen` s'adapte déjà selon le rôle du visiteur.
  static const String scoutHome = '/scout';

  // Marque (brand) — Défis Sponsorisés en libre-service.
  static const String brandHome = '/brand';

  // Administration — entrée dans les Réglages pour role='admin' seulement ;
  // les RPC admin_* refusent tout autre compte côté serveur.
  static const String adminModeration = '/admin/moderation';
  static const String adminHome = '/admin';
  static const String adminUsers = '/admin/users';
  static const String adminOfficialChallenge = '/admin/challenge';
}
