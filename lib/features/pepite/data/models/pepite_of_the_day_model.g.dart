// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pepite_of_the_day_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PepiteOfTheDayModel _$PepiteOfTheDayModelFromJson(Map<String, dynamic> json) =>
    PepiteOfTheDayModel(
      videoId: json['video_id'] as String,
      videoUrl: json['video_url'] as String,
      caption: json['caption'] as String,
      category: json['category'] as String,
      viewsCount: (json['views_count'] as num).toInt(),
      userId: json['user_id'] as String,
      username: json['username'] as String,
      stars: (json['stars'] as num).toInt(),
      followersCount: (json['followers_count'] as num).toInt(),
      worldRank: (json['world_rank'] as num).toInt(),
      thumbnailUrl: json['thumbnail_url'] as String?,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      country: json['country'] as String?,
      city: json['city'] as String?,
      playerPosition: json['player_position'] as String?,
    );

Map<String, dynamic> _$PepiteOfTheDayModelToJson(
        PepiteOfTheDayModel instance) =>
    <String, dynamic>{
      'video_id': instance.videoId,
      'video_url': instance.videoUrl,
      'caption': instance.caption,
      'category': instance.category,
      'views_count': instance.viewsCount,
      'user_id': instance.userId,
      'username': instance.username,
      'stars': instance.stars,
      'followers_count': instance.followersCount,
      'world_rank': instance.worldRank,
      'thumbnail_url': instance.thumbnailUrl,
      'display_name': instance.displayName,
      'avatar_url': instance.avatarUrl,
      'country': instance.country,
      'city': instance.city,
      'player_position': instance.playerPosition,
    };
