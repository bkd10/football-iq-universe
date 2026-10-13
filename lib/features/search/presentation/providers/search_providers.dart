import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/supabase_provider.dart';
import '../../data/datasources/search_remote_datasource.dart';
import '../../data/repositories/search_repository_impl.dart';
import '../../domain/entities/search_results.dart';
import '../../domain/repositories/search_repository.dart';
import '../../domain/usecases/search.dart';

final searchRemoteDataSourceProvider = Provider<SearchRemoteDataSource>((ref) {
  return SearchRemoteDataSource(ref.watch(supabaseClientProvider));
});

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepositoryImpl(ref.watch(searchRemoteDataSourceProvider));
});

final searchUseCaseProvider = Provider(
  (ref) => Search(ref.watch(searchRepositoryProvider)),
);

/// Query courante saisie par l'utilisateur — vide = aucune recherche
/// lancée, l'écran affiche alors un état neutre plutôt qu'une liste vide.
final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<SearchResults>((ref) async {
  final query = ref.watch(searchQueryProvider).trim();
  if (query.length < 2) return const SearchResults();

  final result = await ref.watch(searchUseCaseProvider)(query);
  return result.fold((failure) => throw failure, (results) => results);
});
