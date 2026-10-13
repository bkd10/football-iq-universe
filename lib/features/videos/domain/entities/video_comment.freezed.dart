// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'video_comment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$VideoComment {
  String get id => throw _privateConstructorUsedError;
  String get videoId => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  String? get parentId => throw _privateConstructorUsedError;
  int get likesCount => throw _privateConstructorUsedError;
  VideoCreator? get author => throw _privateConstructorUsedError;

  /// Create a copy of VideoComment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VideoCommentCopyWith<VideoComment> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VideoCommentCopyWith<$Res> {
  factory $VideoCommentCopyWith(
          VideoComment value, $Res Function(VideoComment) then) =
      _$VideoCommentCopyWithImpl<$Res, VideoComment>;
  @useResult
  $Res call(
      {String id,
      String videoId,
      String userId,
      String content,
      DateTime createdAt,
      String? parentId,
      int likesCount,
      VideoCreator? author});

  $VideoCreatorCopyWith<$Res>? get author;
}

/// @nodoc
class _$VideoCommentCopyWithImpl<$Res, $Val extends VideoComment>
    implements $VideoCommentCopyWith<$Res> {
  _$VideoCommentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VideoComment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? videoId = null,
    Object? userId = null,
    Object? content = null,
    Object? createdAt = null,
    Object? parentId = freezed,
    Object? likesCount = null,
    Object? author = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      videoId: null == videoId
          ? _value.videoId
          : videoId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      parentId: freezed == parentId
          ? _value.parentId
          : parentId // ignore: cast_nullable_to_non_nullable
              as String?,
      likesCount: null == likesCount
          ? _value.likesCount
          : likesCount // ignore: cast_nullable_to_non_nullable
              as int,
      author: freezed == author
          ? _value.author
          : author // ignore: cast_nullable_to_non_nullable
              as VideoCreator?,
    ) as $Val);
  }

  /// Create a copy of VideoComment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $VideoCreatorCopyWith<$Res>? get author {
    if (_value.author == null) {
      return null;
    }

    return $VideoCreatorCopyWith<$Res>(_value.author!, (value) {
      return _then(_value.copyWith(author: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$VideoCommentImplCopyWith<$Res>
    implements $VideoCommentCopyWith<$Res> {
  factory _$$VideoCommentImplCopyWith(
          _$VideoCommentImpl value, $Res Function(_$VideoCommentImpl) then) =
      __$$VideoCommentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String videoId,
      String userId,
      String content,
      DateTime createdAt,
      String? parentId,
      int likesCount,
      VideoCreator? author});

  @override
  $VideoCreatorCopyWith<$Res>? get author;
}

/// @nodoc
class __$$VideoCommentImplCopyWithImpl<$Res>
    extends _$VideoCommentCopyWithImpl<$Res, _$VideoCommentImpl>
    implements _$$VideoCommentImplCopyWith<$Res> {
  __$$VideoCommentImplCopyWithImpl(
      _$VideoCommentImpl _value, $Res Function(_$VideoCommentImpl) _then)
      : super(_value, _then);

  /// Create a copy of VideoComment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? videoId = null,
    Object? userId = null,
    Object? content = null,
    Object? createdAt = null,
    Object? parentId = freezed,
    Object? likesCount = null,
    Object? author = freezed,
  }) {
    return _then(_$VideoCommentImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      videoId: null == videoId
          ? _value.videoId
          : videoId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      parentId: freezed == parentId
          ? _value.parentId
          : parentId // ignore: cast_nullable_to_non_nullable
              as String?,
      likesCount: null == likesCount
          ? _value.likesCount
          : likesCount // ignore: cast_nullable_to_non_nullable
              as int,
      author: freezed == author
          ? _value.author
          : author // ignore: cast_nullable_to_non_nullable
              as VideoCreator?,
    ));
  }
}

/// @nodoc

class _$VideoCommentImpl implements _VideoComment {
  const _$VideoCommentImpl(
      {required this.id,
      required this.videoId,
      required this.userId,
      required this.content,
      required this.createdAt,
      this.parentId,
      this.likesCount = 0,
      this.author});

  @override
  final String id;
  @override
  final String videoId;
  @override
  final String userId;
  @override
  final String content;
  @override
  final DateTime createdAt;
  @override
  final String? parentId;
  @override
  @JsonKey()
  final int likesCount;
  @override
  final VideoCreator? author;

  @override
  String toString() {
    return 'VideoComment(id: $id, videoId: $videoId, userId: $userId, content: $content, createdAt: $createdAt, parentId: $parentId, likesCount: $likesCount, author: $author)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VideoCommentImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.videoId, videoId) || other.videoId == videoId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.parentId, parentId) ||
                other.parentId == parentId) &&
            (identical(other.likesCount, likesCount) ||
                other.likesCount == likesCount) &&
            (identical(other.author, author) || other.author == author));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, videoId, userId, content,
      createdAt, parentId, likesCount, author);

  /// Create a copy of VideoComment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VideoCommentImplCopyWith<_$VideoCommentImpl> get copyWith =>
      __$$VideoCommentImplCopyWithImpl<_$VideoCommentImpl>(this, _$identity);
}

abstract class _VideoComment implements VideoComment {
  const factory _VideoComment(
      {required final String id,
      required final String videoId,
      required final String userId,
      required final String content,
      required final DateTime createdAt,
      final String? parentId,
      final int likesCount,
      final VideoCreator? author}) = _$VideoCommentImpl;

  @override
  String get id;
  @override
  String get videoId;
  @override
  String get userId;
  @override
  String get content;
  @override
  DateTime get createdAt;
  @override
  String? get parentId;
  @override
  int get likesCount;
  @override
  VideoCreator? get author;

  /// Create a copy of VideoComment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VideoCommentImplCopyWith<_$VideoCommentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
