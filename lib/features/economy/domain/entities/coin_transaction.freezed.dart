// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'coin_transaction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$CoinTransaction {
  String get id => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  int get amount => throw _privateConstructorUsedError;
  String get currency => throw _privateConstructorUsedError;
  String get reason => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  int? get balanceAfter => throw _privateConstructorUsedError;
  String? get referenceType => throw _privateConstructorUsedError;
  String? get referenceId => throw _privateConstructorUsedError;

  /// Create a copy of CoinTransaction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CoinTransactionCopyWith<CoinTransaction> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CoinTransactionCopyWith<$Res> {
  factory $CoinTransactionCopyWith(
          CoinTransaction value, $Res Function(CoinTransaction) then) =
      _$CoinTransactionCopyWithImpl<$Res, CoinTransaction>;
  @useResult
  $Res call(
      {String id,
      String type,
      int amount,
      String currency,
      String reason,
      DateTime createdAt,
      int? balanceAfter,
      String? referenceType,
      String? referenceId});
}

/// @nodoc
class _$CoinTransactionCopyWithImpl<$Res, $Val extends CoinTransaction>
    implements $CoinTransactionCopyWith<$Res> {
  _$CoinTransactionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CoinTransaction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? amount = null,
    Object? currency = null,
    Object? reason = null,
    Object? createdAt = null,
    Object? balanceAfter = freezed,
    Object? referenceType = freezed,
    Object? referenceId = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as int,
      currency: null == currency
          ? _value.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String,
      reason: null == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      balanceAfter: freezed == balanceAfter
          ? _value.balanceAfter
          : balanceAfter // ignore: cast_nullable_to_non_nullable
              as int?,
      referenceType: freezed == referenceType
          ? _value.referenceType
          : referenceType // ignore: cast_nullable_to_non_nullable
              as String?,
      referenceId: freezed == referenceId
          ? _value.referenceId
          : referenceId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CoinTransactionImplCopyWith<$Res>
    implements $CoinTransactionCopyWith<$Res> {
  factory _$$CoinTransactionImplCopyWith(_$CoinTransactionImpl value,
          $Res Function(_$CoinTransactionImpl) then) =
      __$$CoinTransactionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String type,
      int amount,
      String currency,
      String reason,
      DateTime createdAt,
      int? balanceAfter,
      String? referenceType,
      String? referenceId});
}

/// @nodoc
class __$$CoinTransactionImplCopyWithImpl<$Res>
    extends _$CoinTransactionCopyWithImpl<$Res, _$CoinTransactionImpl>
    implements _$$CoinTransactionImplCopyWith<$Res> {
  __$$CoinTransactionImplCopyWithImpl(
      _$CoinTransactionImpl _value, $Res Function(_$CoinTransactionImpl) _then)
      : super(_value, _then);

  /// Create a copy of CoinTransaction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? amount = null,
    Object? currency = null,
    Object? reason = null,
    Object? createdAt = null,
    Object? balanceAfter = freezed,
    Object? referenceType = freezed,
    Object? referenceId = freezed,
  }) {
    return _then(_$CoinTransactionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as int,
      currency: null == currency
          ? _value.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String,
      reason: null == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      balanceAfter: freezed == balanceAfter
          ? _value.balanceAfter
          : balanceAfter // ignore: cast_nullable_to_non_nullable
              as int?,
      referenceType: freezed == referenceType
          ? _value.referenceType
          : referenceType // ignore: cast_nullable_to_non_nullable
              as String?,
      referenceId: freezed == referenceId
          ? _value.referenceId
          : referenceId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$CoinTransactionImpl implements _CoinTransaction {
  const _$CoinTransactionImpl(
      {required this.id,
      required this.type,
      required this.amount,
      required this.currency,
      required this.reason,
      required this.createdAt,
      this.balanceAfter,
      this.referenceType,
      this.referenceId});

  @override
  final String id;
  @override
  final String type;
  @override
  final int amount;
  @override
  final String currency;
  @override
  final String reason;
  @override
  final DateTime createdAt;
  @override
  final int? balanceAfter;
  @override
  final String? referenceType;
  @override
  final String? referenceId;

  @override
  String toString() {
    return 'CoinTransaction(id: $id, type: $type, amount: $amount, currency: $currency, reason: $reason, createdAt: $createdAt, balanceAfter: $balanceAfter, referenceType: $referenceType, referenceId: $referenceId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CoinTransactionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.reason, reason) || other.reason == reason) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.balanceAfter, balanceAfter) ||
                other.balanceAfter == balanceAfter) &&
            (identical(other.referenceType, referenceType) ||
                other.referenceType == referenceType) &&
            (identical(other.referenceId, referenceId) ||
                other.referenceId == referenceId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, type, amount, currency,
      reason, createdAt, balanceAfter, referenceType, referenceId);

  /// Create a copy of CoinTransaction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CoinTransactionImplCopyWith<_$CoinTransactionImpl> get copyWith =>
      __$$CoinTransactionImplCopyWithImpl<_$CoinTransactionImpl>(
          this, _$identity);
}

abstract class _CoinTransaction implements CoinTransaction {
  const factory _CoinTransaction(
      {required final String id,
      required final String type,
      required final int amount,
      required final String currency,
      required final String reason,
      required final DateTime createdAt,
      final int? balanceAfter,
      final String? referenceType,
      final String? referenceId}) = _$CoinTransactionImpl;

  @override
  String get id;
  @override
  String get type;
  @override
  int get amount;
  @override
  String get currency;
  @override
  String get reason;
  @override
  DateTime get createdAt;
  @override
  int? get balanceAfter;
  @override
  String? get referenceType;
  @override
  String? get referenceId;

  /// Create a copy of CoinTransaction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CoinTransactionImplCopyWith<_$CoinTransactionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
