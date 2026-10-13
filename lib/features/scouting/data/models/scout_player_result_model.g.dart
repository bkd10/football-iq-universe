// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scout_player_result_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScoutPlayerResultModel _$ScoutPlayerResultModelFromJson(
        Map<String, dynamic> json) =>
    ScoutPlayerResultModel(
      id: json['id'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      country: json['country'] as String?,
      city: json['city'] as String?,
      position: json['position'] as String?,
      isMinor: json['is_minor'] as bool,
      stars: (json['stars'] as num?)?.toInt() ?? 0,
      level: json['level'] as String? ?? 'rookie',
      followersCount: (json['followers_count'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$ScoutPlayerResultModelToJson(
        ScoutPlayerResultModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'display_name': instance.displayName,
      'avatar_url': instance.avatarUrl,
      'country': instance.country,
      'city': instance.city,
      'position': instance.position,
      'is_minor': instance.isMinor,
      'stars': instance.stars,
      'level': instance.level,
      'followers_count': instance.followersCount,
    };
