import 'package:freezed_annotation/freezed_annotation.dart';

part 'coin_transaction.freezed.dart';

/// Ligne d'historique du Wallet — reflète la table `transactions`.
/// Purement informatif : le solde affiché sur le profil (`profiles.coins`)
/// fait foi, jamais recalculé côté client à partir de cet historique.
@freezed
class CoinTransaction with _$CoinTransaction {
  const factory CoinTransaction({
    required String id,
    required String type,
    required int amount,
    required String currency,
    required String reason,
    required DateTime createdAt,
    int? balanceAfter,
    String? referenceType,
    String? referenceId,
  }) = _CoinTransaction;
}
