// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'video_creator.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$VideoCreator {
  String get id => throw _privateConstructorUsedError;
  String get username => throw _privateConstructorUsedError;
  String? get displayName => throw _privateConstructorUsedError;
  String? get avatarUrl => throw _privateConstructorUsedError;
  String get level => throw _privateConstructorUsedError;
  bool get isVerified => throw _privateConstructorUsedError;

  /// Create a copy of VideoCreator
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VideoCreatorCopyWith<VideoCreator> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VideoCreatorCopyWith<$Res> {
  factory $VideoCreatorCopyWith(
          VideoCreator value, $Res Function(VideoCreator) then) =
      _$VideoCreatorCopyWithImpl<$Res, VideoCreator>;
  @useResult
  $Res call(
      {String id,
      String username,
      String? displayName,
      String? avatarUrl,
      String level,
      bool isVerified});
}

/// @nodoc
class _$VideoCreatorCopyWithImpl<$Res, $Val extends VideoCreator>
    implements $VideoCreatorCopyWith<$Res> {
  _$VideoCreatorCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VideoCreator
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? username = null,
    Object? displayName = freezed,
    Object? avatarUrl = freezed,
    Object? level = null,
    Object? isVerified = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      username: null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: freezed == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String?,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as String,
      isVerified: null == isVerified
          ? _value.isVerified
          : isVerified // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$VideoCreatorImplCopyWith<$Res>
    implements $VideoCreatorCopyWith<$Res> {
  factory _$$VideoCreatorImplCopyWith(
          _$VideoCreatorImpl value, $Res Function(_$VideoCreatorImpl) then) =
      __$$VideoCreatorImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String username,
      String? displayName,
      String? avatarUrl,
      String level,
      bool isVerified});
}

/// @nodoc
class __$$VideoCreatorImplCopyWithImpl<$Res>
    extends _$VideoCreatorCopyWithImpl<$Res, _$VideoCreatorImpl>
    implements _$$VideoCreatorImplCopyWith<$Res> {
  __$$VideoCreatorImplCopyWithImpl(
      _$VideoCreatorImpl _value, $Res Function(_$VideoCreatorImpl) _then)
      : super(_value, _then);

  /// Create a copy of VideoCreator
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? username = null,
    Object? displayName = freezed,
    Object? avatarUrl = freezed,
    Object? level = null,
    Object? isVerified = null,
  }) {
    return _then(_$VideoCreatorImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      username: null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: freezed == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String?,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as String,
      isVerified: null == isVerified
          ? _value.isVerified
          : isVerified // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$VideoCreatorImpl implements _VideoCreator {
  const _$VideoCreatorImpl(
      {required this.id,
      required this.username,
      this.displayName,
      this.avatarUrl,
      this.level = 'rookie',
      this.isVerified = false});

  @override
  final String id;
  @override
  final String username;
  @override
  final String? displayName;
  @override
  final String? avatarUrl;
  @override
  @JsonKey()
  final String level;
  @override
  @JsonKey()
  final bool isVerified;

  @override
  String toString() {
    return 'VideoCreator(id: $id, username: $username, displayName: $displayName, avatarUrl: $avatarUrl, level: $level, isVerified: $isVerified)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VideoCreatorImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.level, level) || other.level == level) &&
            (identical(other.isVerified, isVerified) ||
                other.isVerified == isVerified));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, id, username, displayName, avatarUrl, level, isVerified);

  /// Create a copy of VideoCreator
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VideoCreatorImplCopyWith<_$VideoCreatorImpl> get copyWith =>
      __$$VideoCreatorImplCopyWithImpl<_$VideoCreatorImpl>(this, _$identity);
}

abstract class _VideoCreator implements VideoCreator {
  const factory _VideoCreator(
      {required final String id,
      required final String username,
      final String? displayName,
      final String? avatarUrl,
      final String level,
      final bool isVerified}) = _$VideoCreatorImpl;

  @override
  String get id;
  @override
  String get username;
  @override
  String? get displayName;
  @override
  String? get avatarUrl;
  @override
  String get level;
  @override
  bool get isVerified;

  /// Create a copy of VideoCreator
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VideoCreatorImplCopyWith<_$VideoCreatorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
