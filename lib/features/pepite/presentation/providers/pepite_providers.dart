import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/supabase_provider.dart';
import '../../data/datasources/pepite_remote_datasource.dart';
import '../../data/repositories/pepite_repository_impl.dart';
import '../../domain/entities/pepite_of_the_day.dart';
import '../../domain/repositories/pepite_repository.dart';
import '../../domain/usecases/get_pepite_of_the_day.dart';

final pepiteRemoteDataSourceProvider = Provider<PepiteRemoteDataSource>((ref) {
  return PepiteRemoteDataSource(ref.watch(supabaseClientProvider));
});

final pepiteRepositoryProvider = Provider<PepiteRepository>((ref) {
  return PepiteRepositoryImpl(ref.watch(pepiteRemoteDataSourceProvider));
});

final getPepiteOfTheDayUseCaseProvider = Provider(
  (ref) => GetPepiteOfTheDay(ref.watch(pepiteRepositoryProvider)),
);

final pepiteOfTheDayProvider = FutureProvider<PepiteOfTheDay?>((ref) async {
  final result = await ref.watch(getPepiteOfTheDayUseCaseProvider)();
  return result.fold((failure) => throw failure, (pepite) => pepite);
});
