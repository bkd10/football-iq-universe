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
  String? get country => throw _privateConstructorUsedError;
  String? get position => throw _privateConstructorUsedError;
  String? get preferredFoot => throw _privateConstructorUsedError;
  int get stars => throw _privateConstructorUsedError;
  int get videosCount => throw _privateConstructorUsedError;
  int get likesReceivedCount => throw _privateConstructorUsedError;
  int get movesCreatedCount => throw _privateConstructorUsedError;
  int get challengesWonCount => throw _privateConstructorUsedError;

  /// Forme sur les 30 derniers jours (-6 à +10), calculée côté serveur.
  int get formScore => throw _privateConstructorUsedError;

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
      bool isVerified,
      String? country,
      String? position,
      String? preferredFoot,
      int stars,
      int videosCount,
      int likesReceivedCount,
      int movesCreatedCount,
      int challengesWonCount,
      int formScore});
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
    Object? country = freezed,
    Object? position = freezed,
    Object? preferredFoot = freezed,
    Object? stars = null,
    Object? videosCount = null,
    Object? likesReceivedCount = null,
    Object? movesCreatedCount = null,
    Object? challengesWonCount = null,
    Object? formScore = null,
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
      country: freezed == country
          ? _value.country
          : country // ignore: cast_nullable_to_non_nullable
              as String?,
      position: freezed == position
          ? _value.position
          : position // ignore: cast_nullable_to_non_nullable
              as String?,
      preferredFoot: freezed == preferredFoot
          ? _value.preferredFoot
          : preferredFoot // ignore: cast_nullable_to_non_nullable
              as String?,
      stars: null == stars
          ? _value.stars
          : stars // ignore: cast_nullable_to_non_nullable
              as int,
      videosCount: null == videosCount
          ? _value.videosCount
          : videosCount // ignore: cast_nullable_to_non_nullable
              as int,
      likesReceivedCount: null == likesReceivedCount
          ? _value.likesReceivedCount
          : likesReceivedCount // ignore: cast_nullable_to_non_nullable
              as int,
      movesCreatedCount: null == movesCreatedCount
          ? _value.movesCreatedCount
          : movesCreatedCount // ignore: cast_nullable_to_non_nullable
              as int,
      challengesWonCount: null == challengesWonCount
          ? _value.challengesWonCount
          : challengesWonCount // ignore: cast_nullable_to_non_nullable
              as int,
      formScore: null == formScore
          ? _value.formScore
          : formScore // ignore: cast_nullable_to_non_nullable
              as int,
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
      bool isVerified,
      String? country,
      String? position,
      String? preferredFoot,
      int stars,
      int videosCount,
      int likesReceivedCount,
      int movesCreatedCount,
      int challengesWonCount,
      int formScore});
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
    Object? country = freezed,
    Object? position = freezed,
    Object? preferredFoot = freezed,
    Object? stars = null,
    Object? videosCount = null,
    Object? likesReceivedCount = null,
    Object? movesCreatedCount = null,
    Object? challengesWonCount = null,
    Object? formScore = null,
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
      country: freezed == country
          ? _value.country
          : country // ignore: cast_nullable_to_non_nullable
              as String?,
      position: freezed == position
          ? _value.position
          : position // ignore: cast_nullable_to_non_nullable
              as String?,
      preferredFoot: freezed == preferredFoot
          ? _value.preferredFoot
          : preferredFoot // ignore: cast_nullable_to_non_nullable
              as String?,
      stars: null == stars
          ? _value.stars
          : stars // ignore: cast_nullable_to_non_nullable
              as int,
      videosCount: null == videosCount
          ? _value.videosCount
          : videosCount // ignore: cast_nullable_to_non_nullable
              as int,
      likesReceivedCount: null == likesReceivedCount
          ? _value.likesReceivedCount
          : likesReceivedCount // ignore: cast_nullable_to_non_nullable
              as int,
      movesCreatedCount: null == movesCreatedCount
          ? _value.movesCreatedCount
          : movesCreatedCount // ignore: cast_nullable_to_non_nullable
              as int,
      challengesWonCount: null == challengesWonCount
          ? _value.challengesWonCount
          : challengesWonCount // ignore: cast_nullable_to_non_nullable
              as int,
      formScore: null == formScore
          ? _value.formScore
          : formScore // ignore: cast_nullable_to_non_nullable
              as int,
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
      this.isVerified = false,
      this.country,
      this.position,
      this.preferredFoot,
      this.stars = 0,
      this.videosCount = 0,
      this.likesReceivedCount = 0,
      this.movesCreatedCount = 0,
      this.challengesWonCount = 0,
      this.formScore = 0});

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
  final String? country;
  @override
  final String? position;
  @override
  final String? preferredFoot;
  @override
  @JsonKey()
  final int stars;
  @override
  @JsonKey()
  final int videosCount;
  @override
  @JsonKey()
  final int likesReceivedCount;
  @override
  @JsonKey()
  final int movesCreatedCount;
  @override
  @JsonKey()
  final int challengesWonCount;

  /// Forme sur les 30 derniers jours (-6 à +10), calculée côté serveur.
  @override
  @JsonKey()
  final int formScore;

  @override
  String toString() {
    return 'VideoCreator(id: $id, username: $username, displayName: $displayName, avatarUrl: $avatarUrl, level: $level, isVerified: $isVerified, country: $country, position: $position, preferredFoot: $preferredFoot, stars: $stars, videosCount: $videosCount, likesReceivedCount: $likesReceivedCount, movesCreatedCount: $movesCreatedCount, challengesWonCount: $challengesWonCount, formScore: $formScore)';
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
                other.isVerified == isVerified) &&
            (identical(other.country, country) || other.country == country) &&
            (identical(other.position, position) ||
                other.position == position) &&
            (identical(other.preferredFoot, preferredFoot) ||
                other.preferredFoot == preferredFoot) &&
            (identical(other.stars, stars) || other.stars == stars) &&
            (identical(other.videosCount, videosCount) ||
                other.videosCount == videosCount) &&
            (identical(other.likesReceivedCount, likesReceivedCount) ||
                other.likesReceivedCount == likesReceivedCount) &&
            (identical(other.movesCreatedCount, movesCreatedCount) ||
                other.movesCreatedCount == movesCreatedCount) &&
            (identical(other.challengesWonCount, challengesWonCount) ||
                other.challengesWonCount == challengesWonCount) &&
            (identical(other.formScore, formScore) ||
                other.formScore == formScore));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      username,
      displayName,
      avatarUrl,
      level,
      isVerified,
      country,
      position,
      preferredFoot,
      stars,
      videosCount,
      likesReceivedCount,
      movesCreatedCount,
      challengesWonCount,
      formScore);

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
      final bool isVerified,
      final String? country,
      final String? position,
      final String? preferredFoot,
      final int stars,
      final int videosCount,
      final int likesReceivedCount,
      final int movesCreatedCount,
      final int challengesWonCount,
      final int formScore}) = _$VideoCreatorImpl;

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
  @override
  String? get country;
  @override
  String? get position;
  @override
  String? get preferredFoot;
  @override
  int get stars;
  @override
  int get videosCount;
  @override
  int get likesReceivedCount;
  @override
  int get movesCreatedCount;
  @override
  int get challengesWonCount;

  /// Forme sur les 30 derniers jours (-6 à +10), calculée côté serveur.
  @override
  int get formScore;

  /// Create a copy of VideoCreator
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VideoCreatorImplCopyWith<_$VideoCreatorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
