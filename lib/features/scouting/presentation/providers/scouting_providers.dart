import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/supabase_provider.dart';
import '../../data/datasources/scouting_remote_datasource.dart';
import '../../data/repositories/scouting_repository_impl.dart';
import '../../domain/entities/scout_player_result.dart';
import '../../domain/entities/scout_subscription.dart';
import '../../domain/repositories/scouting_repository.dart';
import '../../domain/usecases/get_my_scout_subscription.dart';
import '../../domain/usecases/search_players.dart';
import '../../domain/usecases/start_scout_trial.dart';

final scoutingRemoteDataSourceProvider = Provider<ScoutingRemoteDataSource>((ref) {
  return ScoutingRemoteDataSource(ref.watch(supabaseClientProvider));
});

final scoutingRepositoryProvider = Provider<ScoutingRepository>((ref) {
  return ScoutingRepositoryImpl(ref.watch(scoutingRemoteDataSourceProvider));
});

final searchPlayersUseCaseProvider = Provider(
  (ref) => SearchPlayers(ref.watch(scoutingRepositoryProvider)),
);
final startScoutTrialUseCaseProvider = Provider(
  (ref) => StartScoutTrial(ref.watch(scoutingRepositoryProvider)),
);
final getMyScoutSubscriptionUseCaseProvider = Provider(
  (ref) => GetMyScoutSubscription(ref.watch(scoutingRepositoryProvider)),
);

/// État de la recherche — un simple critère texte + filtres, mis à jour
/// par l'écran de recherche.
class ScoutSearchQuery {
  const ScoutSearchQuery({this.query = '', this.position, this.country});

  final String query;
  final String? position;
  final String? country;

  ScoutSearchQuery copyWith({String? query, String? position, String? country}) {
    return ScoutSearchQuery(
      query: query ?? this.query,
      position: position,
      country: country,
    );
  }
}

final scoutSearchQueryProvider =
    StateProvider<ScoutSearchQuery>((ref) => const ScoutSearchQuery());

final scoutSearchResultsProvider =
    FutureProvider<List<ScoutPlayerResult>>((ref) async {
  final query = ref.watch(scoutSearchQueryProvider);
  final result = await ref.watch(searchPlayersUseCaseProvider)(
    query: query.query,
    position: query.position,
    country: query.country,
  );
  return result.fold((failure) => throw failure, (list) => list);
});

final myScoutSubscriptionProvider = FutureProvider<ScoutSubscription?>((ref) async {
  final result = await ref.watch(getMyScoutSubscriptionUseCaseProvider)();
  return result.fold((failure) => throw failure, (sub) => sub);
});

class ScoutTrialController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> start() async {
    state = const AsyncLoading();
    final result = await ref.read(startScoutTrialUseCaseProvider)();
    return result.fold(
      (failure) {
        state = AsyncError(failure, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncData(null);
        ref.invalidate(myScoutSubscriptionProvider);
        return true;
      },
    );
  }
}

final scoutTrialControllerProvider =
    AsyncNotifierProvider<ScoutTrialController, void>(ScoutTrialController.new);
