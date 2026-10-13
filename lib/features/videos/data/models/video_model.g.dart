// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VideoModel _$VideoModelFromJson(Map<String, dynamic> json) => VideoModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      videoUrl: json['video_url'] as String,
      caption: json['caption'] as String,
      category: json['category'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      thumbnailUrl: json['thumbnail_url'] as String?,
      durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
      isMove: json['is_move'] as bool? ?? false,
      moveName: json['move_name'] as String?,
      moveSlug: json['move_slug'] as String?,
      originalMoveId: json['original_move_id'] as String?,
      viewsCount: (json['views_count'] as num?)?.toInt() ?? 0,
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      masterclassCount: (json['masterclass_count'] as num?)?.toInt() ?? 0,
      commentsCount: (json['comments_count'] as num?)?.toInt() ?? 0,
      sharesCount: (json['shares_count'] as num?)?.toInt() ?? 0,
      reproductionsCount: (json['reproductions_count'] as num?)?.toInt() ?? 0,
      talentScore: (json['talent_score'] as num?)?.toDouble() ?? 0,
      qualityRatio: (json['quality_ratio'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'active',
      isBoosted: json['is_boosted'] as bool? ?? false,
      creator: json['creator'] == null
          ? null
          : VideoCreatorModel.fromJson(json['creator'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$VideoModelToJson(VideoModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'video_url': instance.videoUrl,
      'caption': instance.caption,
      'category': instance.category,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'thumbnail_url': instance.thumbnailUrl,
      'duration_seconds': instance.durationSeconds,
      'is_move': instance.isMove,
      'move_name': instance.moveName,
      'move_slug': instance.moveSlug,
      'original_move_id': instance.originalMoveId,
      'views_count': instance.viewsCount,
      'likes_count': instance.likesCount,
      'masterclass_count': instance.masterclassCount,
      'comments_count': instance.commentsCount,
      'shares_count': instance.sharesCount,
      'reproductions_count': instance.reproductionsCount,
      'talent_score': instance.talentScore,
      'quality_ratio': instance.qualityRatio,
      'status': instance.status,
      'is_boosted': instance.isBoosted,
      'creator': instance.creator?.toJson(),
    };
