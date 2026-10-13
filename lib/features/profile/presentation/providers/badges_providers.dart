import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/supabase_provider.dart';
import '../../data/datasources/badges_remote_datasource.dart';
import '../../data/repositories/badges_repository_impl.dart';
import '../../domain/entities/user_badge.dart';
import '../../domain/repositories/badges_repository.dart';
import '../../domain/usecases/get_user_badges.dart';

final badgesRemoteDataSourceProvider = Provider<BadgesRemoteDataSource>((ref) {
  return BadgesRemoteDataSource(ref.watch(supabaseClientProvider));
});

final badgesRepositoryProvider = Provider<BadgesRepository>((ref) {
  return BadgesRepositoryImpl(ref.watch(badgesRemoteDataSourceProvider));
});

final getUserBadgesUseCaseProvider = Provider(
  (ref) => GetUserBadges(ref.watch(badgesRepositoryProvider)),
);

final userBadgesProvider =
    FutureProvider.family<List<UserBadge>, String>((ref, userId) async {
  final result = await ref.watch(getUserBadgesUseCaseProvider)(userId);
  return result.fold((failure) => throw failure, (badges) => badges);
});
