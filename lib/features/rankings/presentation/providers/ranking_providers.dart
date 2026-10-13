import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/supabase_provider.dart';
import '../../data/datasources/ranking_remote_datasource.dart';
import '../../data/repositories/ranking_repository_impl.dart';
import '../../domain/entities/ranking_entry.dart';
import '../../domain/repositories/ranking_repository.dart';
import '../../domain/usecases/get_rankings.dart';

final rankingRemoteDataSourceProvider = Provider<RankingRemoteDataSource>((ref) {
  return RankingRemoteDataSource(ref.watch(supabaseClientProvider));
});

final rankingRepositoryProvider = Provider<RankingRepository>((ref) {
  return RankingRepositoryImpl(ref.watch(rankingRemoteDataSourceProvider));
});

final getRankingsUseCaseProvider = Provider(
  (ref) => GetRankings(ref.watch(rankingRepositoryProvider)),
);

/// Paramètres d'une requête de classement — utilisés comme clé de
/// `rankingsProvider.family` pour que chaque combinaison
/// catégorie/région soit indépendamment mise en cache.
typedef RankingQuery = ({String category, String? country, String? city});

final rankingsProvider =
    FutureProvider.family<List<RankingEntry>, RankingQuery>((ref, query) async {
  final result = await ref.watch(getRankingsUseCaseProvider)(
    category: query.category,
    country: query.country,
    city: query.city,
  );
  return result.fold((failure) => throw failure, (entries) => entries);
});
