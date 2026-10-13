import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/economy_remote_datasource.dart';
import '../../data/repositories/economy_repository_impl.dart';
import '../../domain/entities/coin_transaction.dart';
import '../../domain/repositories/economy_repository.dart';
import '../../domain/usecases/award_coins.dart';
import '../../domain/usecases/get_transactions.dart';
import '../../domain/usecases/spend_coins.dart';

final economyRemoteDataSourceProvider = Provider<EconomyRemoteDataSource>((ref) {
  return EconomyRemoteDataSource(ref.watch(supabaseClientProvider));
});

final economyRepositoryProvider = Provider<EconomyRepository>((ref) {
  return EconomyRepositoryImpl(ref.watch(economyRemoteDataSourceProvider));
});

final awardCoinsUseCaseProvider = Provider(
  (ref) => AwardCoins(ref.watch(economyRepositoryProvider)),
);
final spendCoinsUseCaseProvider = Provider(
  (ref) => SpendCoins(ref.watch(economyRepositoryProvider)),
);
final getTransactionsUseCaseProvider = Provider(
  (ref) => GetTransactions(ref.watch(economyRepositoryProvider)),
);

/// Historique du Wallet, invalidé après chaque gain/dépense.
final transactionsProvider = FutureProvider<List<CoinTransaction>>((ref) async {
  final result = await ref.watch(getTransactionsUseCaseProvider)();
  return result.fold((failure) => throw failure, (list) => list);
});

/// Actions économie exposées aux écrans. Volontairement silencieuses par
/// défaut (pas de `state` de chargement global) : la réclamation du bonus
/// quotidien ou la récompense de publication ne doivent pas bloquer l'UI —
/// l'appelant inspecte l'`Either` retourné s'il veut réagir à l'échec.
class EconomyController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<Either<Failure, int>> awardCoins(
    String reason, {
    String? referenceId,
  }) async {
    final result = await ref.read(awardCoinsUseCaseProvider)(
      reason: reason,
      referenceId: referenceId,
    );
    result.fold((_) {}, (_) => _refreshDependents());
    return result;
  }

  Future<Either<Failure, int>> spendCoins(
    String reason,
    int amount, {
    String? referenceId,
  }) async {
    final result = await ref.read(spendCoinsUseCaseProvider)(
      reason: reason,
      amount: amount,
      referenceId: referenceId,
    );
    result.fold((_) {}, (_) => _refreshDependents());
    return result;
  }

  void _refreshDependents() {
    ref.invalidate(currentProfileProvider);
    ref.invalidate(transactionsProvider);
  }
}

final economyControllerProvider = AsyncNotifierProvider<EconomyController, void>(
  EconomyController.new,
);
