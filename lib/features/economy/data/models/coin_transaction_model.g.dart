// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coin_transaction_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CoinTransactionModel _$CoinTransactionModelFromJson(
        Map<String, dynamic> json) =>
    CoinTransactionModel(
      id: json['id'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).toInt(),
      currency: json['currency'] as String,
      reason: json['reason'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      balanceAfter: (json['balance_after'] as num?)?.toInt(),
      referenceType: json['reference_type'] as String?,
      referenceId: json['reference_id'] as String?,
    );

Map<String, dynamic> _$CoinTransactionModelToJson(
        CoinTransactionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'amount': instance.amount,
      'currency': instance.currency,
      'reason': instance.reason,
      'created_at': instance.createdAt.toIso8601String(),
      'balance_after': instance.balanceAfter,
      'reference_type': instance.referenceType,
      'reference_id': instance.referenceId,
    };
