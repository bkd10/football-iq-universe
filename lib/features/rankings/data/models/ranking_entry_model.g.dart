// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ranking_entry_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RankingEntryModel _$RankingEntryModelFromJson(Map<String, dynamic> json) =>
    RankingEntryModel(
      id: json['id'] as String,
      username: json['username'] as String,
      score: (json['score'] as num).toInt(),
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      level: json['level'] as String? ?? 'rookie',
      country: json['country'] as String?,
      city: json['city'] as String?,
    );

Map<String, dynamic> _$RankingEntryModelToJson(RankingEntryModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'score': instance.score,
      'display_name': instance.displayName,
      'avatar_url': instance.avatarUrl,
      'level': instance.level,
      'country': instance.country,
      'city': instance.city,
    };
