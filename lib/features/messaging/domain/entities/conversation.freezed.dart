// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'conversation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$Conversation {
  String get id => throw _privateConstructorUsedError;
  String get playerId => throw _privateConstructorUsedError;
  String get scoutId => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  DateTime get requestedAt => throw _privateConstructorUsedError;
  DateTime? get approvedAt => throw _privateConstructorUsedError;
  DateTime? get lastMessageAt => throw _privateConstructorUsedError;
  String? get guardianApprovalToken => throw _privateConstructorUsedError;
  String? get otherUserId => throw _privateConstructorUsedError;
  String? get otherUsername => throw _privateConstructorUsedError;
  String? get otherDisplayName => throw _privateConstructorUsedError;
  String? get otherAvatarUrl => throw _privateConstructorUsedError;
  bool get hasUnread => throw _privateConstructorUsedError;

  /// Create a copy of Conversation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ConversationCopyWith<Conversation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ConversationCopyWith<$Res> {
  factory $ConversationCopyWith(
          Conversation value, $Res Function(Conversation) then) =
      _$ConversationCopyWithImpl<$Res, Conversation>;
  @useResult
  $Res call(
      {String id,
      String playerId,
      String scoutId,
      String status,
      DateTime requestedAt,
      DateTime? approvedAt,
      DateTime? lastMessageAt,
      String? guardianApprovalToken,
      String? otherUserId,
      String? otherUsername,
      String? otherDisplayName,
      String? otherAvatarUrl,
      bool hasUnread});
}

/// @nodoc
class _$ConversationCopyWithImpl<$Res, $Val extends Conversation>
    implements $ConversationCopyWith<$Res> {
  _$ConversationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Conversation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? playerId = null,
    Object? scoutId = null,
    Object? status = null,
    Object? requestedAt = null,
    Object? approvedAt = freezed,
    Object? lastMessageAt = freezed,
    Object? guardianApprovalToken = freezed,
    Object? otherUserId = freezed,
    Object? otherUsername = freezed,
    Object? otherDisplayName = freezed,
    Object? otherAvatarUrl = freezed,
    Object? hasUnread = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      playerId: null == playerId
          ? _value.playerId
          : playerId // ignore: cast_nullable_to_non_nullable
              as String,
      scoutId: null == scoutId
          ? _value.scoutId
          : scoutId // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      requestedAt: null == requestedAt
          ? _value.requestedAt
          : requestedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      approvedAt: freezed == approvedAt
          ? _value.approvedAt
          : approvedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastMessageAt: freezed == lastMessageAt
          ? _value.lastMessageAt
          : lastMessageAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      guardianApprovalToken: freezed == guardianApprovalToken
          ? _value.guardianApprovalToken
          : guardianApprovalToken // ignore: cast_nullable_to_non_nullable
              as String?,
      otherUserId: freezed == otherUserId
          ? _value.otherUserId
          : otherUserId // ignore: cast_nullable_to_non_nullable
              as String?,
      otherUsername: freezed == otherUsername
          ? _value.otherUsername
          : otherUsername // ignore: cast_nullable_to_non_nullable
              as String?,
      otherDisplayName: freezed == otherDisplayName
          ? _value.otherDisplayName
          : otherDisplayName // ignore: cast_nullable_to_non_nullable
              as String?,
      otherAvatarUrl: freezed == otherAvatarUrl
          ? _value.otherAvatarUrl
          : otherAvatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      hasUnread: null == hasUnread
          ? _value.hasUnread
          : hasUnread // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ConversationImplCopyWith<$Res>
    implements $ConversationCopyWith<$Res> {
  factory _$$ConversationImplCopyWith(
          _$ConversationImpl value, $Res Function(_$ConversationImpl) then) =
      __$$ConversationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String playerId,
      String scoutId,
      String status,
      DateTime requestedAt,
      DateTime? approvedAt,
      DateTime? lastMessageAt,
      String? guardianApprovalToken,
      String? otherUserId,
      String? otherUsername,
      String? otherDisplayName,
      String? otherAvatarUrl,
      bool hasUnread});
}

/// @nodoc
class __$$ConversationImplCopyWithImpl<$Res>
    extends _$ConversationCopyWithImpl<$Res, _$ConversationImpl>
    implements _$$ConversationImplCopyWith<$Res> {
  __$$ConversationImplCopyWithImpl(
      _$ConversationImpl _value, $Res Function(_$ConversationImpl) _then)
      : super(_value, _then);

  /// Create a copy of Conversation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? playerId = null,
    Object? scoutId = null,
    Object? status = null,
    Object? requestedAt = null,
    Object? approvedAt = freezed,
    Object? lastMessageAt = freezed,
    Object? guardianApprovalToken = freezed,
    Object? otherUserId = freezed,
    Object? otherUsername = freezed,
    Object? otherDisplayName = freezed,
    Object? otherAvatarUrl = freezed,
    Object? hasUnread = null,
  }) {
    return _then(_$ConversationImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      playerId: null == playerId
          ? _value.playerId
          : playerId // ignore: cast_nullable_to_non_nullable
              as String,
      scoutId: null == scoutId
          ? _value.scoutId
          : scoutId // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      requestedAt: null == requestedAt
          ? _value.requestedAt
          : requestedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      approvedAt: freezed == approvedAt
          ? _value.approvedAt
          : approvedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastMessageAt: freezed == lastMessageAt
          ? _value.lastMessageAt
          : lastMessageAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      guardianApprovalToken: freezed == guardianApprovalToken
          ? _value.guardianApprovalToken
          : guardianApprovalToken // ignore: cast_nullable_to_non_nullable
              as String?,
      otherUserId: freezed == otherUserId
          ? _value.otherUserId
          : otherUserId // ignore: cast_nullable_to_non_nullable
              as String?,
      otherUsername: freezed == otherUsername
          ? _value.otherUsername
          : otherUsername // ignore: cast_nullable_to_non_nullable
              as String?,
      otherDisplayName: freezed == otherDisplayName
          ? _value.otherDisplayName
          : otherDisplayName // ignore: cast_nullable_to_non_nullable
              as String?,
      otherAvatarUrl: freezed == otherAvatarUrl
          ? _value.otherAvatarUrl
          : otherAvatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      hasUnread: null == hasUnread
          ? _value.hasUnread
          : hasUnread // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$ConversationImpl extends _Conversation {
  const _$ConversationImpl(
      {required this.id,
      required this.playerId,
      required this.scoutId,
      required this.status,
      required this.requestedAt,
      this.approvedAt,
      this.lastMessageAt,
      this.guardianApprovalToken,
      this.otherUserId,
      this.otherUsername,
      this.otherDisplayName,
      this.otherAvatarUrl,
      this.hasUnread = false})
      : super._();

  @override
  final String id;
  @override
  final String playerId;
  @override
  final String scoutId;
  @override
  final String status;
  @override
  final DateTime requestedAt;
  @override
  final DateTime? approvedAt;
  @override
  final DateTime? lastMessageAt;
  @override
  final String? guardianApprovalToken;
  @override
  final String? otherUserId;
  @override
  final String? otherUsername;
  @override
  final String? otherDisplayName;
  @override
  final String? otherAvatarUrl;
  @override
  @JsonKey()
  final bool hasUnread;

  @override
  String toString() {
    return 'Conversation(id: $id, playerId: $playerId, scoutId: $scoutId, status: $status, requestedAt: $requestedAt, approvedAt: $approvedAt, lastMessageAt: $lastMessageAt, guardianApprovalToken: $guardianApprovalToken, otherUserId: $otherUserId, otherUsername: $otherUsername, otherDisplayName: $otherDisplayName, otherAvatarUrl: $otherAvatarUrl, hasUnread: $hasUnread)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConversationImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.playerId, playerId) ||
                other.playerId == playerId) &&
            (identical(other.scoutId, scoutId) || other.scoutId == scoutId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.requestedAt, requestedAt) ||
                other.requestedAt == requestedAt) &&
            (identical(other.approvedAt, approvedAt) ||
                other.approvedAt == approvedAt) &&
            (identical(other.lastMessageAt, lastMessageAt) ||
                other.lastMessageAt == lastMessageAt) &&
            (identical(other.guardianApprovalToken, guardianApprovalToken) ||
                other.guardianApprovalToken == guardianApprovalToken) &&
            (identical(other.otherUserId, otherUserId) ||
                other.otherUserId == otherUserId) &&
            (identical(other.otherUsername, otherUsername) ||
                other.otherUsername == otherUsername) &&
            (identical(other.otherDisplayName, otherDisplayName) ||
                other.otherDisplayName == otherDisplayName) &&
            (identical(other.otherAvatarUrl, otherAvatarUrl) ||
                other.otherAvatarUrl == otherAvatarUrl) &&
            (identical(other.hasUnread, hasUnread) ||
                other.hasUnread == hasUnread));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      playerId,
      scoutId,
      status,
      requestedAt,
      approvedAt,
      lastMessageAt,
      guardianApprovalToken,
      otherUserId,
      otherUsername,
      otherDisplayName,
      otherAvatarUrl,
      hasUnread);

  /// Create a copy of Conversation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ConversationImplCopyWith<_$ConversationImpl> get copyWith =>
      __$$ConversationImplCopyWithImpl<_$ConversationImpl>(this, _$identity);
}

abstract class _Conversation extends Conversation {
  const factory _Conversation(
      {required final String id,
      required final String playerId,
      required final String scoutId,
      required final String status,
      required final DateTime requestedAt,
      final DateTime? approvedAt,
      final DateTime? lastMessageAt,
      final String? guardianApprovalToken,
      final String? otherUserId,
      final String? otherUsername,
      final String? otherDisplayName,
      final String? otherAvatarUrl,
      final bool hasUnread}) = _$ConversationImpl;
  const _Conversation._() : super._();

  @override
  String get id;
  @override
  String get playerId;
  @override
  String get scoutId;
  @override
  String get status;
  @override
  DateTime get requestedAt;
  @override
  DateTime? get approvedAt;
  @override
  DateTime? get lastMessageAt;
  @override
  String? get guardianApprovalToken;
  @override
  String? get otherUserId;
  @override
  String? get otherUsername;
  @override
  String? get otherDisplayName;
  @override
  String? get otherAvatarUrl;
  @override
  bool get hasUnread;

  /// Create a copy of Conversation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ConversationImplCopyWith<_$ConversationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
