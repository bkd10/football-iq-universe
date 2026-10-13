// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'daily_mission.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$DailyMission {
  DateTime get missionDate => throw _privateConstructorUsedError;
  bool get loginCompleted => throw _privateConstructorUsedError;
  bool get videoPosted => throw _privateConstructorUsedError;
  bool get challengeParticipated => throw _privateConstructorUsedError;
  int get videosWatched => throw _privateConstructorUsedError;
  int get coinsEarned => throw _privateConstructorUsedError;

  /// Create a copy of DailyMission
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DailyMissionCopyWith<DailyMission> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DailyMissionCopyWith<$Res> {
  factory $DailyMissionCopyWith(
          DailyMission value, $Res Function(DailyMission) then) =
      _$DailyMissionCopyWithImpl<$Res, DailyMission>;
  @useResult
  $Res call(
      {DateTime missionDate,
      bool loginCompleted,
      bool videoPosted,
      bool challengeParticipated,
      int videosWatched,
      int coinsEarned});
}

/// @nodoc
class _$DailyMissionCopyWithImpl<$Res, $Val extends DailyMission>
    implements $DailyMissionCopyWith<$Res> {
  _$DailyMissionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DailyMission
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? missionDate = null,
    Object? loginCompleted = null,
    Object? videoPosted = null,
    Object? challengeParticipated = null,
    Object? videosWatched = null,
    Object? coinsEarned = null,
  }) {
    return _then(_value.copyWith(
      missionDate: null == missionDate
          ? _value.missionDate
          : missionDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      loginCompleted: null == loginCompleted
          ? _value.loginCompleted
          : loginCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
      videoPosted: null == videoPosted
          ? _value.videoPosted
          : videoPosted // ignore: cast_nullable_to_non_nullable
              as bool,
      challengeParticipated: null == challengeParticipated
          ? _value.challengeParticipated
          : challengeParticipated // ignore: cast_nullable_to_non_nullable
              as bool,
      videosWatched: null == videosWatched
          ? _value.videosWatched
          : videosWatched // ignore: cast_nullable_to_non_nullable
              as int,
      coinsEarned: null == coinsEarned
          ? _value.coinsEarned
          : coinsEarned // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DailyMissionImplCopyWith<$Res>
    implements $DailyMissionCopyWith<$Res> {
  factory _$$DailyMissionImplCopyWith(
          _$DailyMissionImpl value, $Res Function(_$DailyMissionImpl) then) =
      __$$DailyMissionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {DateTime missionDate,
      bool loginCompleted,
      bool videoPosted,
      bool challengeParticipated,
      int videosWatched,
      int coinsEarned});
}

/// @nodoc
class __$$DailyMissionImplCopyWithImpl<$Res>
    extends _$DailyMissionCopyWithImpl<$Res, _$DailyMissionImpl>
    implements _$$DailyMissionImplCopyWith<$Res> {
  __$$DailyMissionImplCopyWithImpl(
      _$DailyMissionImpl _value, $Res Function(_$DailyMissionImpl) _then)
      : super(_value, _then);

  /// Create a copy of DailyMission
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? missionDate = null,
    Object? loginCompleted = null,
    Object? videoPosted = null,
    Object? challengeParticipated = null,
    Object? videosWatched = null,
    Object? coinsEarned = null,
  }) {
    return _then(_$DailyMissionImpl(
      missionDate: null == missionDate
          ? _value.missionDate
          : missionDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      loginCompleted: null == loginCompleted
          ? _value.loginCompleted
          : loginCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
      videoPosted: null == videoPosted
          ? _value.videoPosted
          : videoPosted // ignore: cast_nullable_to_non_nullable
              as bool,
      challengeParticipated: null == challengeParticipated
          ? _value.challengeParticipated
          : challengeParticipated // ignore: cast_nullable_to_non_nullable
              as bool,
      videosWatched: null == videosWatched
          ? _value.videosWatched
          : videosWatched // ignore: cast_nullable_to_non_nullable
              as int,
      coinsEarned: null == coinsEarned
          ? _value.coinsEarned
          : coinsEarned // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$DailyMissionImpl extends _DailyMission {
  const _$DailyMissionImpl(
      {required this.missionDate,
      this.loginCompleted = false,
      this.videoPosted = false,
      this.challengeParticipated = false,
      this.videosWatched = 0,
      this.coinsEarned = 0})
      : super._();

  @override
  final DateTime missionDate;
  @override
  @JsonKey()
  final bool loginCompleted;
  @override
  @JsonKey()
  final bool videoPosted;
  @override
  @JsonKey()
  final bool challengeParticipated;
  @override
  @JsonKey()
  final int videosWatched;
  @override
  @JsonKey()
  final int coinsEarned;

  @override
  String toString() {
    return 'DailyMission(missionDate: $missionDate, loginCompleted: $loginCompleted, videoPosted: $videoPosted, challengeParticipated: $challengeParticipated, videosWatched: $videosWatched, coinsEarned: $coinsEarned)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DailyMissionImpl &&
            (identical(other.missionDate, missionDate) ||
                other.missionDate == missionDate) &&
            (identical(other.loginCompleted, loginCompleted) ||
                other.loginCompleted == loginCompleted) &&
            (identical(other.videoPosted, videoPosted) ||
                other.videoPosted == videoPosted) &&
            (identical(other.challengeParticipated, challengeParticipated) ||
                other.challengeParticipated == challengeParticipated) &&
            (identical(other.videosWatched, videosWatched) ||
                other.videosWatched == videosWatched) &&
            (identical(other.coinsEarned, coinsEarned) ||
                other.coinsEarned == coinsEarned));
  }

  @override
  int get hashCode => Object.hash(runtimeType, missionDate, loginCompleted,
      videoPosted, challengeParticipated, videosWatched, coinsEarned);

  /// Create a copy of DailyMission
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DailyMissionImplCopyWith<_$DailyMissionImpl> get copyWith =>
      __$$DailyMissionImplCopyWithImpl<_$DailyMissionImpl>(this, _$identity);
}

abstract class _DailyMission extends DailyMission {
  const factory _DailyMission(
      {required final DateTime missionDate,
      final bool loginCompleted,
      final bool videoPosted,
      final bool challengeParticipated,
      final int videosWatched,
      final int coinsEarned}) = _$DailyMissionImpl;
  const _DailyMission._() : super._();

  @override
  DateTime get missionDate;
  @override
  bool get loginCompleted;
  @override
  bool get videoPosted;
  @override
  bool get challengeParticipated;
  @override
  int get videosWatched;
  @override
  int get coinsEarned;

  /// Create a copy of DailyMission
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DailyMissionImplCopyWith<_$DailyMissionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
