import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/coin_transaction.dart';

part 'coin_transaction_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class CoinTransactionModel {
  const CoinTransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.currency,
    required this.reason,
    required this.createdAt,
    this.balanceAfter,
    this.referenceType,
    this.referenceId,
  });

  factory CoinTransactionModel.fromJson(Map<String, dynamic> json) =>
      _$CoinTransactionModelFromJson(json);

  Map<String, dynamic> toJson() => _$CoinTransactionModelToJson(this);

  final String id;
  final String type;
  final int amount;
  final String currency;
  final String reason;
  final DateTime createdAt;
  final int? balanceAfter;
  final String? referenceType;
  final String? referenceId;

  CoinTransaction toEntity() {
    return CoinTransaction(
      id: id,
      type: type,
      amount: amount,
      currency: currency,
      reason: reason,
      createdAt: createdAt,
      balanceAfter: balanceAfter,
      referenceType: referenceType,
      referenceId: referenceId,
    );
  }
}
