// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_comment_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VideoCommentModel _$VideoCommentModelFromJson(Map<String, dynamic> json) =>
    VideoCommentModel(
      id: json['id'] as String,
      videoId: json['video_id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      parentId: json['parent_id'] as String?,
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      author: json['author'] == null
          ? null
          : VideoCreatorModel.fromJson(json['author'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$VideoCommentModelToJson(VideoCommentModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'video_id': instance.videoId,
      'user_id': instance.userId,
      'content': instance.content,
      'created_at': instance.createdAt.toIso8601String(),
      'parent_id': instance.parentId,
      'likes_count': instance.likesCount,
      'author': instance.author?.toJson(),
    };
