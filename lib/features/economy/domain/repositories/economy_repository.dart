import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/coin_transaction.dart';

/// Contrat du domaine pour l'économie Ballons. Toute mutation de solde
/// passe par `award_coins`/`spend_coins` côté serveur — jamais de calcul de
/// solde côté client (voir `supabase/migrations/20260101000005_economy_rpc.sql`).
abstract class EconomyRepository {
  /// Retourne le nouveau solde après attribution, ou une [Failure] (ex :
  /// [DailyLimitReachedFailure] si la limite quotidienne est atteinte).
  Future<Either<Failure, int>> awardCoins({
    required String reason,
    String? referenceId,
  });

  /// Retourne le nouveau solde après débit, ou [InsufficientCoinsFailure].
  Future<Either<Failure, int>> spendCoins({
    required String reason,
    required int amount,
    String? referenceId,
  });

  Future<Either<Failure, List<CoinTransaction>>> getTransactions({
    int limit = 30,
  });
}
