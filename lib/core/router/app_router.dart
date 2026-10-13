import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/auth_callback_screen.dart';
import '../../features/auth/presentation/screens/confirm_email_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/challenges/presentation/screens/brand_home_screen.dart';
import '../../features/challenges/presentation/screens/challenge_detail_screen.dart';
import '../../features/challenges/presentation/screens/challenges_screen.dart';
import '../../features/challenges/presentation/screens/create_challenge_screen.dart';
import '../../features/economy/presentation/screens/earn_ballons_screen.dart';
import '../../features/economy/presentation/screens/shop_screen.dart';
import '../../features/economy/presentation/screens/wallet_screen.dart';
import '../../features/feed/presentation/screens/feed_screen.dart';
import '../../features/messaging/presentation/screens/conversation_screen.dart';
import '../../features/messaging/presentation/screens/guardian_approval_screen.dart';
import '../../features/messaging/presentation/screens/inbox_screen.dart';
import '../../features/missions/presentation/screens/daily_missions_screen.dart';
import '../../features/moderation/presentation/screens/admin_moderation_screen.dart';
import '../../features/moves/presentation/screens/move_detail_screen.dart';
import '../../features/moves/presentation/screens/trending_moves_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/pepite/presentation/screens/pepite_of_the_day_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/rankings/presentation/screens/rankings_screen.dart';
import '../../features/scouting/presentation/screens/scout_home_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/videos/presentation/screens/create_screen.dart';
import '../../features/videos/presentation/screens/video_detail_screen.dart';
import '../../shared/widgets/main_shell.dart';
import '../services/onboarding_prefs_service.dart';
import '../constants/route_names.dart';

/// Pont entre `authStateProvider` et `Listenable`, requis par
/// `refreshListenable` de GoRouter pour ré-évaluer `redirect` à chaque
/// changement de session (connexion, déconnexion, refresh de token).
///
/// Se branche sur `authStateProvider` lui-même (via `ref.listen`) plutôt que
/// de ré-écouter séparément le stream Supabase brut : deux abonnements
/// indépendants à `watchAuthState()` peuvent se résoudre dans un ordre non
/// garanti, et si la notification de `refreshListenable` arrive avant que
/// `authStateProvider` n'ait sa propre valeur, `redirect` reste bloqué sur
/// `isLoading` pour toujours (plus aucun événement ne survient ensuite dans
/// une session non authentifiée) — l'app reste alors coincée sur le splash.
class GoRouterRefreshNotifier extends ChangeNotifier {
  GoRouterRefreshNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}

final _authOnlyRoutes = {
  RouteNames.login,
  RouteNames.register,
  RouteNames.forgotPassword,
  RouteNames.confirmEmail,
};

/// Router unique de l'app. Le `redirect` centralise toute la logique de
/// navigation liée à l'authentification, pour que les écrans n'aient
/// jamais à décider où aller après un login/logout.
final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = GoRouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: RouteNames.splash,
    refreshListenable: refreshNotifier,
    redirect: (context, state) async {
      final location = state.matchedLocation;

      // Approbation tuteur : toujours accessible, connecté ou non — le
      // tuteur n'a pas nécessairement de compte dans l'app (voir
      // `GuardianApprovalScreen`).
      if (location.startsWith(RouteNames.guardianApprovalEntry)) {
        return null;
      }

      // Retour du lien de confirmation d'e-mail : géré entièrement à part,
      // ni comme "auth only" ni comme le flux normal. Un `?error=...`
      // signifie un lien expiré/invalide (aucune session ne sera jamais
      // établie) : on reste sur l'écran pour afficher pourquoi, plutôt que
      // de rebondir silencieusement vers login. Sinon, dès qu'une session
      // existe (le code a été échangé), direction l'app comme un point
      // d'entrée classique — ne JAMAIS rester bloqué sur cet écran une fois
      // connecté.
      if (location.startsWith(RouteNames.authCallback)) {
        if (state.uri.queryParameters['error'] != null) return null;
        final callbackProfile = ref.read(authStateProvider).valueOrNull;
        if (callbackProfile == null) return null;
        if (callbackProfile.role == 'scout') return RouteNames.scoutHome;
        if (callbackProfile.role == 'brand') return RouteNames.brandHome;
        return RouteNames.pepiteOfTheDay;
      }

      final authState = ref.read(authStateProvider);

      if (authState.isLoading && !authState.hasValue) {
        return location == RouteNames.splash ? null : RouteNames.splash;
      }

      final isLoggedIn = authState.valueOrNull != null;

      if (!isLoggedIn) {
        if (location == RouteNames.onboarding ||
            _authOnlyRoutes.contains(location)) {
          return null;
        }
        final seenOnboarding = await OnboardingPrefsService.hasSeenOnboarding();
        return seenOnboarding ? RouteNames.login : RouteNames.onboarding;
      }

      final role = authState.valueOrNull?.role;
      final isScout = role == 'scout';
      final isBrand = role == 'brand';

      final onAuthOnlyScreen = location == RouteNames.splash ||
          location == RouteNames.onboarding ||
          _authOnlyRoutes.contains(location);
      // PARTIE 8.9 : la Pépite du Jour s'affiche à chaque entrée dans l'app
      // authentifiée (démarrage à froid, juste après connexion/inscription)
      // avant le feed — jamais en boucle ensuite, `/pepite` n'étant pas
      // elle-même une route auth-only. Un compte recruteur/marque n'a pas
      // de Pépite du Jour (ni de feed) : direction son propre tableau de
      // bord.
      if (onAuthOnlyScreen) {
        if (isScout) return RouteNames.scoutHome;
        if (isBrand) return RouteNames.brandHome;
        return RouteNames.pepiteOfTheDay;
      }

      // Un recruteur/une marque n'a pas accès au shell joueur (feed/défis/
      // créer/classements/profil) ni à la Pépite du Jour — cas typique :
      // arrivée directe sur `/pepite` juste après la connexion, avant que
      // ce garde ne s'applique.
      final onPlayerEntryScreen =
          location == RouteNames.pepiteOfTheDay || location == RouteNames.feed;
      if (isScout && onPlayerEntryScreen) return RouteNames.scoutHome;
      if (isBrand && onPlayerEntryScreen) return RouteNames.brandHome;

      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: RouteNames.confirmEmail,
        builder: (context, state) => ConfirmEmailScreen(
          email: (state.extra as String?) ?? '',
        ),
      ),
      GoRoute(
        path: RouteNames.authCallback,
        builder: (context, state) => AuthCallbackScreen(
          errorDescription: state.uri.queryParameters['error_description'],
        ),
      ),
      GoRoute(
        path: RouteNames.wallet,
        builder: (context, state) => const WalletScreen(),
      ),
      GoRoute(
        path: RouteNames.earnBallons,
        builder: (context, state) => const EarnBallonsScreen(),
      ),
      GoRoute(
        path: RouteNames.shop,
        builder: (context, state) => const ShopScreen(),
      ),
      GoRoute(
        path: RouteNames.dailyMissions,
        builder: (context, state) => const DailyMissionsScreen(),
      ),
      GoRoute(
        path: RouteNames.moveDetail,
        builder: (context, state) => MoveDetailScreen(
          moveId: state.pathParameters['moveId']!,
        ),
      ),
      GoRoute(
        path: RouteNames.trendingMoves,
        builder: (context, state) => const TrendingMovesScreen(),
      ),
      GoRoute(
        path: RouteNames.challengeDetail,
        builder: (context, state) => ChallengeDetailScreen(
          challengeId: state.pathParameters['challengeId']!,
        ),
      ),
      GoRoute(
        path: RouteNames.createChallenge,
        builder: (context, state) => const CreateChallengeScreen(),
      ),
      GoRoute(
        path: RouteNames.videoDetail,
        builder: (context, state) => VideoDetailScreen(
          videoId: state.pathParameters['videoId']!,
        ),
      ),
      GoRoute(
        path: RouteNames.otherProfile,
        builder: (context, state) => ProfileScreen(
          userId: state.pathParameters['userId']!,
        ),
      ),
      GoRoute(
        path: RouteNames.editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: RouteNames.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: RouteNames.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: RouteNames.search,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: RouteNames.pepiteOfTheDay,
        builder: (context, state) => const PepiteOfTheDayScreen(),
      ),
      GoRoute(
        path: RouteNames.inbox,
        builder: (context, state) => const InboxScreen(),
      ),
      GoRoute(
        path: RouteNames.conversation,
        builder: (context, state) => ConversationScreen(
          conversationId: state.pathParameters['conversationId']!,
        ),
      ),
      GoRoute(
        path: RouteNames.guardianApprovalEntry,
        builder: (context, state) => const GuardianApprovalScreen(),
      ),
      GoRoute(
        path: RouteNames.guardianApproval,
        builder: (context, state) => GuardianApprovalScreen(
          initialToken: state.pathParameters['token'],
        ),
      ),
      GoRoute(
        path: RouteNames.scoutHome,
        builder: (context, state) => const ScoutHomeScreen(),
      ),
      GoRoute(
        path: RouteNames.brandHome,
        builder: (context, state) => const BrandHomeScreen(),
      ),
      GoRoute(
        path: RouteNames.adminModeration,
        builder: (context, state) => const AdminModerationScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.feed,
                builder: (context, state) => const FeedScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.challenges,
                builder: (context, state) => const ChallengesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.create,
                builder: (context, state) => CreateScreen(
                  originalMoveId: state.uri.queryParameters['originalMoveId'],
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.rankings,
                builder: (context, state) => const RankingsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
