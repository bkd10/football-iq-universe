import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/supabase_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/challenge_remote_datasource.dart';
import '../../data/repositories/challenge_repository_impl.dart';
import '../../domain/entities/battle_opponent.dart';
import '../../domain/entities/challenge.dart';
import '../../domain/entities/challenge_participation.dart';
import '../../domain/repositories/challenge_repository.dart';
import '../../domain/usecases/create_challenge.dart';
import '../../domain/usecases/get_challenge_by_id.dart';
import '../../domain/usecases/get_challenges.dart';
import '../../domain/usecases/get_participations.dart';
import '../../domain/usecases/join_challenge.dart';
import '../../domain/usecases/vote_for_participant.dart';

final challengeRemoteDataSourceProvider = Provider<ChallengeRemoteDataSource>((ref) {
  return ChallengeRemoteDataSource(ref.watch(supabaseClientProvider));
});

final challengeRepositoryProvider = Provider<ChallengeRepository>((ref) {
  return ChallengeRepositoryImpl(ref.watch(challengeRemoteDataSourceProvider));
});

/// Adversaires proposés pour une Battle (abonnés et abonnements), filtrés
/// par la recherche saisie.
final battleOpponentSuggestionsProvider =
    FutureProvider.autoDispose.family<List<BattleOpponent>, String>((ref, query) async {
  final result =
      await ref.watch(challengeRepositoryProvider).getBattleOpponentSuggestions(query);
  return result.fold((failure) => throw failure, (opponents) => opponents);
});

final getChallengesUseCaseProvider = Provider(
  (ref) => GetChallenges(ref.watch(challengeRepositoryProvider)),
);
final getChallengeByIdUseCaseProvider = Provider(
  (ref) => GetChallengeById(ref.watch(challengeRepositoryProvider)),
);
final getParticipationsUseCaseProvider = Provider(
  (ref) => GetParticipations(ref.watch(challengeRepositoryProvider)),
);
final joinChallengeUseCaseProvider = Provider(
  (ref) => JoinChallenge(ref.watch(challengeRepositoryProvider)),
);
final voteForParticipantUseCaseProvider = Provider(
  (ref) => VoteForParticipant(ref.watch(challengeRepositoryProvider)),
);
final createChallengeUseCaseProvider = Provider(
  (ref) => CreateChallenge(ref.watch(challengeRepositoryProvider)),
);

/// Liste des défis, filtrée par type (`null` = "Tous").
final challengesProvider =
    FutureProvider.family<List<Challenge>, String?>((ref, type) async {
  final result = await ref.watch(getChallengesUseCaseProvider)(type: type);
  return result.fold((failure) => throw failure, (challenges) => challenges);
});

final challengeByIdProvider =
    FutureProvider.family<Challenge?, String>((ref, challengeId) async {
  final result = await ref.watch(getChallengeByIdUseCaseProvider)(challengeId);
  return result.fold((failure) => throw failure, (challenge) => challenge);
});

final participationsProvider =
    FutureProvider.family<List<ChallengeParticipation>, String>((ref, challengeId) async {
  final result = await ref.watch(getParticipationsUseCaseProvider)(challengeId);
  return result.fold((failure) => throw failure, (list) => list);
});

/// Actions défis : participer, voter, créer. Invalide les providers
/// concernés après succès pour refléter le nouvel état serveur.
class ChallengeActionsController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> join({required String challengeId, required String videoId}) async {
    final result = await ref.read(joinChallengeUseCaseProvider)(
      challengeId: challengeId,
      videoId: videoId,
    );
    return result.fold(
      (failure) {
        state = AsyncError(failure, StackTrace.current);
        return false;
      },
      (_) {
        ref.invalidate(challengeByIdProvider(challengeId));
        ref.invalidate(participationsProvider(challengeId));
        ref.invalidate(currentProfileProvider);
        state = const AsyncData(null);
        return true;
      },
    );
  }

  Future<bool> vote({
    required String challengeId,
    required String participantUserId,
  }) async {
    final result = await ref.read(voteForParticipantUseCaseProvider)(
      challengeId: challengeId,
      participantUserId: participantUserId,
    );
    return result.fold(
      (failure) {
        state = AsyncError(failure, StackTrace.current);
        return false;
      },
      (_) {
        ref.invalidate(participationsProvider(challengeId));
        state = const AsyncData(null);
        return true;
      },
    );
  }

  Future<Challenge?> create({
    required String title,
    required String description,
    required String type,
    String? category,
    required DateTime endDate,
    int prizePool = 0,
    int? maxParticipants,
    String? recordUnit,
    String? prizeDescription,
    DateTime? startDate,
  }) async {
    state = const AsyncLoading();
    final result = await ref.read(createChallengeUseCaseProvider)(
      title: title,
      description: description,
      type: type,
      category: category,
      endDate: endDate,
      prizePool: prizePool,
      maxParticipants: maxParticipants,
      recordUnit: recordUnit,
      prizeDescription: prizeDescription,
      startDate: startDate,
    );
    return result.fold(
      (failure) {
        state = AsyncError(failure, StackTrace.current);
        return null;
      },
      (challenge) {
        ref.invalidate(challengesProvider);
        ref.invalidate(currentProfileProvider);
        state = const AsyncData(null);
        return challenge;
      },
    );
  }

  Future<Challenge?> createBattle({
    required String title,
    required String rules,
    required int stake,
    required String videoId,
    required DateTime endDate,
    String? opponentUsername,
    bool randomOpponent = false,
  }) async {
    state = const AsyncLoading();
    final result = await ref.read(challengeRepositoryProvider).createBattle(
          title: title,
          rules: rules,
          stake: stake,
          videoId: videoId,
          endDate: endDate,
          opponentUsername: opponentUsername,
          randomOpponent: randomOpponent,
        );
    return result.fold(
      (failure) {
        state = AsyncError(failure, StackTrace.current);
        return null;
      },
      (challenge) {
        ref.invalidate(challengesProvider);
        ref.invalidate(currentProfileProvider);
        state = const AsyncData(null);
        return challenge;
      },
    );
  }
}

final challengeActionsControllerProvider =
    AsyncNotifierProvider<ChallengeActionsController, void>(
  ChallengeActionsController.new,
);
