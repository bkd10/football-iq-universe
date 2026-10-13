// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scout_subscription.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ScoutSubscription {
  String get plan => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  DateTime? get expiresAt => throw _privateConstructorUsedError;

  /// Create a copy of ScoutSubscription
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ScoutSubscriptionCopyWith<ScoutSubscription> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ScoutSubscriptionCopyWith<$Res> {
  factory $ScoutSubscriptionCopyWith(
          ScoutSubscription value, $Res Function(ScoutSubscription) then) =
      _$ScoutSubscriptionCopyWithImpl<$Res, ScoutSubscription>;
  @useResult
  $Res call({String plan, String status, DateTime? expiresAt});
}

/// @nodoc
class _$ScoutSubscriptionCopyWithImpl<$Res, $Val extends ScoutSubscription>
    implements $ScoutSubscriptionCopyWith<$Res> {
  _$ScoutSubscriptionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ScoutSubscription
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? plan = null,
    Object? status = null,
    Object? expiresAt = freezed,
  }) {
    return _then(_value.copyWith(
      plan: null == plan
          ? _value.plan
          : plan // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      expiresAt: freezed == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ScoutSubscriptionImplCopyWith<$Res>
    implements $ScoutSubscriptionCopyWith<$Res> {
  factory _$$ScoutSubscriptionImplCopyWith(_$ScoutSubscriptionImpl value,
          $Res Function(_$ScoutSubscriptionImpl) then) =
      __$$ScoutSubscriptionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String plan, String status, DateTime? expiresAt});
}

/// @nodoc
class __$$ScoutSubscriptionImplCopyWithImpl<$Res>
    extends _$ScoutSubscriptionCopyWithImpl<$Res, _$ScoutSubscriptionImpl>
    implements _$$ScoutSubscriptionImplCopyWith<$Res> {
  __$$ScoutSubscriptionImplCopyWithImpl(_$ScoutSubscriptionImpl _value,
      $Res Function(_$ScoutSubscriptionImpl) _then)
      : super(_value, _then);

  /// Create a copy of ScoutSubscription
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? plan = null,
    Object? status = null,
    Object? expiresAt = freezed,
  }) {
    return _then(_$ScoutSubscriptionImpl(
      plan: null == plan
          ? _value.plan
          : plan // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      expiresAt: freezed == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc

class _$ScoutSubscriptionImpl extends _ScoutSubscription {
  const _$ScoutSubscriptionImpl(
      {required this.plan, required this.status, this.expiresAt})
      : super._();

  @override
  final String plan;
  @override
  final String status;
  @override
  final DateTime? expiresAt;

  @override
  String toString() {
    return 'ScoutSubscription(plan: $plan, status: $status, expiresAt: $expiresAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScoutSubscriptionImpl &&
            (identical(other.plan, plan) || other.plan == plan) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt));
  }

  @override
  int get hashCode => Object.hash(runtimeType, plan, status, expiresAt);

  /// Create a copy of ScoutSubscription
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ScoutSubscriptionImplCopyWith<_$ScoutSubscriptionImpl> get copyWith =>
      __$$ScoutSubscriptionImplCopyWithImpl<_$ScoutSubscriptionImpl>(
          this, _$identity);
}

abstract class _ScoutSubscription extends ScoutSubscription {
  const factory _ScoutSubscription(
      {required final String plan,
      required final String status,
      final DateTime? expiresAt}) = _$ScoutSubscriptionImpl;
  const _ScoutSubscription._() : super._();

  @override
  String get plan;
  @override
  String get status;
  @override
  DateTime? get expiresAt;

  /// Create a copy of ScoutSubscription
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ScoutSubscriptionImplCopyWith<_$ScoutSubscriptionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
