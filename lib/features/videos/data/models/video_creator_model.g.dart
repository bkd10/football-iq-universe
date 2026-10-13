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
    );

Map<String, dynamic> _$VideoCreatorModelToJson(VideoCreatorModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'display_name': instance.displayName,
      'avatar_url': instance.avatarUrl,
      'level': instance.level,
      'is_verified': instance.isVerified,
    };
