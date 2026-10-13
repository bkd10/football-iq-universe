// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'challenge_participation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ChallengeParticipation {
  String get id => throw _privateConstructorUsedError;
  String get challengeId => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get videoId => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  int get votesCount => throw _privateConstructorUsedError;
  double? get score => throw _privateConstructorUsedError;
  int? get rank => throw _privateConstructorUsedError;
  bool get hasVoted => throw _privateConstructorUsedError;
  VideoCreator? get participant => throw _privateConstructorUsedError;
  String? get videoUrl => throw _privateConstructorUsedError;
  String? get videoThumbnailUrl => throw _privateConstructorUsedError;

  /// Create a copy of ChallengeParticipation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChallengeParticipationCopyWith<ChallengeParticipation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChallengeParticipationCopyWith<$Res> {
  factory $ChallengeParticipationCopyWith(ChallengeParticipation value,
          $Res Function(ChallengeParticipation) then) =
      _$ChallengeParticipationCopyWithImpl<$Res, ChallengeParticipation>;
  @useResult
  $Res call(
      {String id,
      String challengeId,
      String userId,
      String videoId,
      DateTime createdAt,
      int votesCount,
      double? score,
      int? rank,
      bool hasVoted,
      VideoCreator? participant,
      String? videoUrl,
      String? videoThumbnailUrl});

  $VideoCreatorCopyWith<$Res>? get participant;
}

/// @nodoc
class _$ChallengeParticipationCopyWithImpl<$Res,
        $Val extends ChallengeParticipation>
    implements $ChallengeParticipationCopyWith<$Res> {
  _$ChallengeParticipationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChallengeParticipation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? challengeId = null,
    Object? userId = null,
    Object? videoId = null,
    Object? createdAt = null,
    Object? votesCount = null,
    Object? score = freezed,
    Object? rank = freezed,
    Object? hasVoted = null,
    Object? participant = freezed,
    Object? videoUrl = freezed,
    Object? videoThumbnailUrl = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      challengeId: null == challengeId
          ? _value.challengeId
          : challengeId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      videoId: null == videoId
          ? _value.videoId
          : videoId // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      votesCount: null == votesCount
          ? _value.votesCount
          : votesCount // ignore: cast_nullable_to_non_nullable
              as int,
      score: freezed == score
          ? _value.score
          : score // ignore: cast_nullable_to_non_nullable
              as double?,
      rank: freezed == rank
          ? _value.rank
          : rank // ignore: cast_nullable_to_non_nullable
              as int?,
      hasVoted: null == hasVoted
          ? _value.hasVoted
          : hasVoted // ignore: cast_nullable_to_non_nullable
              as bool,
      participant: freezed == participant
          ? _value.participant
          : participant // ignore: cast_nullable_to_non_nullable
              as VideoCreator?,
      videoUrl: freezed == videoUrl
          ? _value.videoUrl
          : videoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      videoThumbnailUrl: freezed == videoThumbnailUrl
          ? _value.videoThumbnailUrl
          : videoThumbnailUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  /// Create a copy of ChallengeParticipation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $VideoCreatorCopyWith<$Res>? get participant {
    if (_value.participant == null) {
      return null;
    }

    return $VideoCreatorCopyWith<$Res>(_value.participant!, (value) {
      return _then(_value.copyWith(participant: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ChallengeParticipationImplCopyWith<$Res>
    implements $ChallengeParticipationCopyWith<$Res> {
  factory _$$ChallengeParticipationImplCopyWith(
          _$ChallengeParticipationImpl value,
          $Res Function(_$ChallengeParticipationImpl) then) =
      __$$ChallengeParticipationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String challengeId,
      String userId,
      String videoId,
      DateTime createdAt,
      int votesCount,
      double? score,
      int? rank,
      bool hasVoted,
      VideoCreator? participant,
      String? videoUrl,
      String? videoThumbnailUrl});

  @override
  $VideoCreatorCopyWith<$Res>? get participant;
}

/// @nodoc
class __$$ChallengeParticipationImplCopyWithImpl<$Res>
    extends _$ChallengeParticipationCopyWithImpl<$Res,
        _$ChallengeParticipationImpl>
    implements _$$ChallengeParticipationImplCopyWith<$Res> {
  __$$ChallengeParticipationImplCopyWithImpl(
      _$ChallengeParticipationImpl _value,
      $Res Function(_$ChallengeParticipationImpl) _then)
      : super(_value, _then);

  /// Create a copy of ChallengeParticipation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? challengeId = null,
    Object? userId = null,
    Object? videoId = null,
    Object? createdAt = null,
    Object? votesCount = null,
    Object? score = freezed,
    Object? rank = freezed,
    Object? hasVoted = null,
    Object? participant = freezed,
    Object? videoUrl = freezed,
    Object? videoThumbnailUrl = freezed,
  }) {
    return _then(_$ChallengeParticipationImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      challengeId: null == challengeId
          ? _value.challengeId
          : challengeId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      videoId: null == videoId
          ? _value.videoId
          : videoId // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      votesCount: null == votesCount
          ? _value.votesCount
          : votesCount // ignore: cast_nullable_to_non_nullable
              as int,
      score: freezed == score
          ? _value.score
          : score // ignore: cast_nullable_to_non_nullable
              as double?,
      rank: freezed == rank
          ? _value.rank
          : rank // ignore: cast_nullable_to_non_nullable
              as int?,
      hasVoted: null == hasVoted
          ? _value.hasVoted
          : hasVoted // ignore: cast_nullable_to_non_nullable
              as bool,
      participant: freezed == participant
          ? _value.participant
          : participant // ignore: cast_nullable_to_non_nullable
              as VideoCreator?,
      videoUrl: freezed == videoUrl
          ? _value.videoUrl
          : videoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      videoThumbnailUrl: freezed == videoThumbnailUrl
          ? _value.videoThumbnailUrl
          : videoThumbnailUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$ChallengeParticipationImpl implements _ChallengeParticipation {
  const _$ChallengeParticipationImpl(
      {required this.id,
      required this.challengeId,
      required this.userId,
      required this.videoId,
      required this.createdAt,
      this.votesCount = 0,
      this.score,
      this.rank,
      this.hasVoted = false,
      this.participant,
      this.videoUrl,
      this.videoThumbnailUrl});

  @override
  final String id;
  @override
  final String challengeId;
  @override
  final String userId;
  @override
  final String videoId;
  @override
  final DateTime createdAt;
  @override
  @JsonKey()
  final int votesCount;
  @override
  final double? score;
  @override
  final int? rank;
  @override
  @JsonKey()
  final bool hasVoted;
  @override
  final VideoCreator? participant;
  @override
  final String? videoUrl;
  @override
  final String? videoThumbnailUrl;

  @override
  String toString() {
    return 'ChallengeParticipation(id: $id, challengeId: $challengeId, userId: $userId, videoId: $videoId, createdAt: $createdAt, votesCount: $votesCount, score: $score, rank: $rank, hasVoted: $hasVoted, participant: $participant, videoUrl: $videoUrl, videoThumbnailUrl: $videoThumbnailUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChallengeParticipationImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.challengeId, challengeId) ||
                other.challengeId == challengeId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.videoId, videoId) || other.videoId == videoId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.votesCount, votesCount) ||
                other.votesCount == votesCount) &&
            (identical(other.score, score) || other.score == score) &&
            (identical(other.rank, rank) || other.rank == rank) &&
            (identical(other.hasVoted, hasVoted) ||
                other.hasVoted == hasVoted) &&
            (identical(other.participant, participant) ||
                other.participant == participant) &&
            (identical(other.videoUrl, videoUrl) ||
                other.videoUrl == videoUrl) &&
            (identical(other.videoThumbnailUrl, videoThumbnailUrl) ||
                other.videoThumbnailUrl == videoThumbnailUrl));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      challengeId,
      userId,
      videoId,
      createdAt,
      votesCount,
      score,
      rank,
      hasVoted,
      participant,
      videoUrl,
      videoThumbnailUrl);

  /// Create a copy of ChallengeParticipation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChallengeParticipationImplCopyWith<_$ChallengeParticipationImpl>
      get copyWith => __$$ChallengeParticipationImplCopyWithImpl<
          _$ChallengeParticipationImpl>(this, _$identity);
}

abstract class _ChallengeParticipation implements ChallengeParticipation {
  const factory _ChallengeParticipation(
      {required final String id,
      required final String challengeId,
      required final String userId,
      required final String videoId,
      required final DateTime createdAt,
      final int votesCount,
      final double? score,
      final int? rank,
      final bool hasVoted,
      final VideoCreator? participant,
      final String? videoUrl,
      final String? videoThumbnailUrl}) = _$ChallengeParticipationImpl;

  @override
  String get id;
  @override
  String get challengeId;
  @override
  String get userId;
  @override
  String get videoId;
  @override
  DateTime get createdAt;
  @override
  int get votesCount;
  @override
  double? get score;
  @override
  int? get rank;
  @override
  bool get hasVoted;
  @override
  VideoCreator? get participant;
  @override
  String? get videoUrl;
  @override
  String? get videoThumbnailUrl;

  /// Create a copy of ChallengeParticipation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChallengeParticipationImplCopyWith<_$ChallengeParticipationImpl>
      get copyWith => throw _privateConstructorUsedError;
}
