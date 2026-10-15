// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_creator_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VideoCreatorModel _$VideoCreatorModelFromJson(Map<String, dynamic> json) =>
    VideoCreatorModel(
      id: json['id'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      level: json['level'] as String? ?? 'rookie',
      isVerified: json['is_verified'] as bool? ?? false,
      country: json['country'] as String?,
      position: json['position'] as String?,
      preferredFoot: json['preferred_foot'] as String?,
      stars: (json['stars'] as num?)?.toInt() ?? 0,
      videosCount: (json['videos_count'] as num?)?.toInt() ?? 0,
      likesReceivedCount: (json['likes_received_count'] as num?)?.toInt() ?? 0,
      movesCreatedCount: (json['moves_created_count'] as num?)?.toInt() ?? 0,
      challengesWonCount: (json['challenges_won_count'] as num?)?.toInt() ?? 0,
      formScore: (json['form_score'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$VideoCreatorModelToJson(VideoCreatorModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'display_name': instance.displayName,
      'avatar_url': instance.avatarUrl,
      'level': instance.level,
      'is_verified': instance.isVerified,
      'country': instance.country,
      'position': instance.position,
      'preferred_foot': instance.preferredFoot,
      'stars': instance.stars,
      'videos_count': instance.videosCount,
      'likes_received_count': instance.likesReceivedCount,
      'moves_created_count': instance.movesCreatedCount,
      'challenges_won_count': instance.challengesWonCount,
      'form_score': instance.formScore,
    };
