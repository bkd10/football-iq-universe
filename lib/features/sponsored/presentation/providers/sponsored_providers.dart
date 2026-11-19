import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/supabase_provider.dart';
import '../../data/sponsored_remote_datasource.dart';
import '../../domain/sponsored_models.dart';

final sponsoredDataSourceProvider = Provider<SponsoredRemoteDataSource>(
  (ref) => SponsoredRemoteDataSource(ref.watch(supabaseClientProvider)),
);

/// Fréquence de la carte dans le fil (panneau admin). Erreur : valeur par
/// défaut, le fil continue de s'afficher.
final sponsoredFeedConfigProvider = FutureProvider<SponsoredFeedConfig>((ref) async {
  try {
    return await ref.watch(sponsoredDataSourceProvider).getFeedConfig();
  } catch (_) {
    return const SponsoredFeedConfig();
  }
});

/// Défis sponsorisés actifs à montrer dans le fil. Erreur : aucun (le fil
/// reste un fil de vidéos).
final sponsoredFeedChallengesProvider = FutureProvider<List<SponsoredFeedChallenge>>((ref) async {
  try {
    return await ref.watch(sponsoredDataSourceProvider).getFeedChallenges();
  } catch (_) {
    return const [];
  }
});

/// Défis en cours d'une vidéo (vide : pas de bouton Voter). Les vidéos
/// demandées en même temps partent en un seul appel.
final videoChallengeEntriesProvider =
    FutureProvider.autoDispose.family<List<VideoChallengeEntry>, String>((ref, videoId) async {
  final link = ref.keepAlive();
  // Gardé 2 minutes pour ne pas redemander en revenant sur une vidéo.
  Future<void>.delayed(const Duration(minutes: 2), link.close);
  try {
    return await ref.watch(sponsoredDataSourceProvider).getEntries(videoId);
  } catch (_) {
    link.close();
    return const [];
  }
});

/// Joueur connecté ? (sinon le bouton Voter invite à se connecter).
final voteSignedInProvider = Provider<bool>(
  (ref) => ref.watch(supabaseClientProvider).auth.currentUser != null,
);

/// Votes déjà faits dans cette session : le bouton change tout de suite,
/// partout où la vidéo apparaît (challengeId → participant choisi).
final localVotesProvider = StateProvider<Map<String, String>>((ref) => const {});
