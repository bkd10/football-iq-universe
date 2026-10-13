// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'content_report.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ContentReport {
  String get id => throw _privateConstructorUsedError;
  String get targetType => throw _privateConstructorUsedError;
  String get targetId => throw _privateConstructorUsedError;
  String get reason => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  String? get reporterUsername => throw _privateConstructorUsedError;
  String? get resolutionNote => throw _privateConstructorUsedError;

  /// Create a copy of ContentReport
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ContentReportCopyWith<ContentReport> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ContentReportCopyWith<$Res> {
  factory $ContentReportCopyWith(
          ContentReport value, $Res Function(ContentReport) then) =
      _$ContentReportCopyWithImpl<$Res, ContentReport>;
  @useResult
  $Res call(
      {String id,
      String targetType,
      String targetId,
      String reason,
      String status,
      DateTime createdAt,
      String? reporterUsername,
      String? resolutionNote});
}

/// @nodoc
class _$ContentReportCopyWithImpl<$Res, $Val extends ContentReport>
    implements $ContentReportCopyWith<$Res> {
  _$ContentReportCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ContentReport
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? targetType = null,
    Object? targetId = null,
    Object? reason = null,
    Object? status = null,
    Object? createdAt = null,
    Object? reporterUsername = freezed,
    Object? resolutionNote = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      targetType: null == targetType
          ? _value.targetType
          : targetType // ignore: cast_nullable_to_non_nullable
              as String,
      targetId: null == targetId
          ? _value.targetId
          : targetId // ignore: cast_nullable_to_non_nullable
              as String,
      reason: null == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      reporterUsername: freezed == reporterUsername
          ? _value.reporterUsername
          : reporterUsername // ignore: cast_nullable_to_non_nullable
              as String?,
      resolutionNote: freezed == resolutionNote
          ? _value.resolutionNote
          : resolutionNote // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ContentReportImplCopyWith<$Res>
    implements $ContentReportCopyWith<$Res> {
  factory _$$ContentReportImplCopyWith(
          _$ContentReportImpl value, $Res Function(_$ContentReportImpl) then) =
      __$$ContentReportImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String targetType,
      String targetId,
      String reason,
      String status,
      DateTime createdAt,
      String? reporterUsername,
      String? resolutionNote});
}

/// @nodoc
class __$$ContentReportImplCopyWithImpl<$Res>
    extends _$ContentReportCopyWithImpl<$Res, _$ContentReportImpl>
    implements _$$ContentReportImplCopyWith<$Res> {
  __$$ContentReportImplCopyWithImpl(
      _$ContentReportImpl _value, $Res Function(_$ContentReportImpl) _then)
      : super(_value, _then);

  /// Create a copy of ContentReport
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? targetType = null,
    Object? targetId = null,
    Object? reason = null,
    Object? status = null,
    Object? createdAt = null,
    Object? reporterUsername = freezed,
    Object? resolutionNote = freezed,
  }) {
    return _then(_$ContentReportImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      targetType: null == targetType
          ? _value.targetType
          : targetType // ignore: cast_nullable_to_non_nullable
              as String,
      targetId: null == targetId
          ? _value.targetId
          : targetId // ignore: cast_nullable_to_non_nullable
              as String,
      reason: null == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      reporterUsername: freezed == reporterUsername
          ? _value.reporterUsername
          : reporterUsername // ignore: cast_nullable_to_non_nullable
              as String?,
      resolutionNote: freezed == resolutionNote
          ? _value.resolutionNote
          : resolutionNote // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$ContentReportImpl extends _ContentReport {
  const _$ContentReportImpl(
      {required this.id,
      required this.targetType,
      required this.targetId,
      required this.reason,
      required this.status,
      required this.createdAt,
      this.reporterUsername,
      this.resolutionNote})
      : super._();

  @override
  final String id;
  @override
  final String targetType;
  @override
  final String targetId;
  @override
  final String reason;
  @override
  final String status;
  @override
  final DateTime createdAt;
  @override
  final String? reporterUsername;
  @override
  final String? resolutionNote;

  @override
  String toString() {
    return 'ContentReport(id: $id, targetType: $targetType, targetId: $targetId, reason: $reason, status: $status, createdAt: $createdAt, reporterUsername: $reporterUsername, resolutionNote: $resolutionNote)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ContentReportImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.targetType, targetType) ||
                other.targetType == targetType) &&
            (identical(other.targetId, targetId) ||
                other.targetId == targetId) &&
            (identical(other.reason, reason) || other.reason == reason) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.reporterUsername, reporterUsername) ||
                other.reporterUsername == reporterUsername) &&
            (identical(other.resolutionNote, resolutionNote) ||
                other.resolutionNote == resolutionNote));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, targetType, targetId, reason,
      status, createdAt, reporterUsername, resolutionNote);

  /// Create a copy of ContentReport
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ContentReportImplCopyWith<_$ContentReportImpl> get copyWith =>
      __$$ContentReportImplCopyWithImpl<_$ContentReportImpl>(this, _$identity);
}

abstract class _ContentReport extends ContentReport {
  const factory _ContentReport(
      {required final String id,
      required final String targetType,
      required final String targetId,
      required final String reason,
      required final String status,
      required final DateTime createdAt,
      final String? reporterUsername,
      final String? resolutionNote}) = _$ContentReportImpl;
  const _ContentReport._() : super._();

  @override
  String get id;
  @override
  String get targetType;
  @override
  String get targetId;
  @override
  String get reason;
  @override
  String get status;
  @override
  DateTime get createdAt;
  @override
  String? get reporterUsername;
  @override
  String? get resolutionNote;

  /// Create a copy of ContentReport
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ContentReportImplCopyWith<_$ContentReportImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
