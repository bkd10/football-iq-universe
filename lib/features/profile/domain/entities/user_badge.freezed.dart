// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_badge.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$UserBadge {
  String get code => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  DateTime get earnedAt => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get iconUrl => throw _privateConstructorUsedError;
  String get category => throw _privateConstructorUsedError;
  String get rarity => throw _privateConstructorUsedError;

  /// Create a copy of UserBadge
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserBadgeCopyWith<UserBadge> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserBadgeCopyWith<$Res> {
  factory $UserBadgeCopyWith(UserBadge value, $Res Function(UserBadge) then) =
      _$UserBadgeCopyWithImpl<$Res, UserBadge>;
  @useResult
  $Res call(
      {String code,
      String name,
      DateTime earnedAt,
      String? description,
      String? iconUrl,
      String category,
      String rarity});
}

/// @nodoc
class _$UserBadgeCopyWithImpl<$Res, $Val extends UserBadge>
    implements $UserBadgeCopyWith<$Res> {
  _$UserBadgeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserBadge
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? name = null,
    Object? earnedAt = null,
    Object? description = freezed,
    Object? iconUrl = freezed,
    Object? category = null,
    Object? rarity = null,
  }) {
    return _then(_value.copyWith(
      code: null == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      earnedAt: null == earnedAt
          ? _value.earnedAt
          : earnedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      iconUrl: freezed == iconUrl
          ? _value.iconUrl
          : iconUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      rarity: null == rarity
          ? _value.rarity
          : rarity // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserBadgeImplCopyWith<$Res>
    implements $UserBadgeCopyWith<$Res> {
  factory _$$UserBadgeImplCopyWith(
          _$UserBadgeImpl value, $Res Function(_$UserBadgeImpl) then) =
      __$$UserBadgeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String code,
      String name,
      DateTime earnedAt,
      String? description,
      String? iconUrl,
      String category,
      String rarity});
}

/// @nodoc
class __$$UserBadgeImplCopyWithImpl<$Res>
    extends _$UserBadgeCopyWithImpl<$Res, _$UserBadgeImpl>
    implements _$$UserBadgeImplCopyWith<$Res> {
  __$$UserBadgeImplCopyWithImpl(
      _$UserBadgeImpl _value, $Res Function(_$UserBadgeImpl) _then)
      : super(_value, _then);

  /// Create a copy of UserBadge
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? name = null,
    Object? earnedAt = null,
    Object? description = freezed,
    Object? iconUrl = freezed,
    Object? category = null,
    Object? rarity = null,
  }) {
    return _then(_$UserBadgeImpl(
      code: null == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      earnedAt: null == earnedAt
          ? _value.earnedAt
          : earnedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      iconUrl: freezed == iconUrl
          ? _value.iconUrl
          : iconUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      rarity: null == rarity
          ? _value.rarity
          : rarity // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$UserBadgeImpl implements _UserBadge {
  const _$UserBadgeImpl(
      {required this.code,
      required this.name,
      required this.earnedAt,
      this.description,
      this.iconUrl,
      this.category = 'achievement',
      this.rarity = 'common'});

  @override
  final String code;
  @override
  final String name;
  @override
  final DateTime earnedAt;
  @override
  final String? description;
  @override
  final String? iconUrl;
  @override
  @JsonKey()
  final String category;
  @override
  @JsonKey()
  final String rarity;

  @override
  String toString() {
    return 'UserBadge(code: $code, name: $name, earnedAt: $earnedAt, description: $description, iconUrl: $iconUrl, category: $category, rarity: $rarity)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserBadgeImpl &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.earnedAt, earnedAt) ||
                other.earnedAt == earnedAt) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.iconUrl, iconUrl) || other.iconUrl == iconUrl) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.rarity, rarity) || other.rarity == rarity));
  }

  @override
  int get hashCode => Object.hash(runtimeType, code, name, earnedAt,
      description, iconUrl, category, rarity);

  /// Create a copy of UserBadge
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserBadgeImplCopyWith<_$UserBadgeImpl> get copyWith =>
      __$$UserBadgeImplCopyWithImpl<_$UserBadgeImpl>(this, _$identity);
}

abstract class _UserBadge implements UserBadge {
  const factory _UserBadge(
      {required final String code,
      required final String name,
      required final DateTime earnedAt,
      final String? description,
      final String? iconUrl,
      final String category,
      final String rarity}) = _$UserBadgeImpl;

  @override
  String get code;
  @override
  String get name;
  @override
  DateTime get earnedAt;
  @override
  String? get description;
  @override
  String? get iconUrl;
  @override
  String get category;
  @override
  String get rarity;

  /// Create a copy of UserBadge
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserBadgeImplCopyWith<_$UserBadgeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
