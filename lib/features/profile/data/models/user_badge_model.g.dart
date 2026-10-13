// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_badge_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BadgeInfoModel _$BadgeInfoModelFromJson(Map<String, dynamic> json) =>
    BadgeInfoModel(
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      iconUrl: json['icon_url'] as String?,
      category: json['category'] as String? ?? 'achievement',
      rarity: json['rarity'] as String? ?? 'common',
    );

Map<String, dynamic> _$BadgeInfoModelToJson(BadgeInfoModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'description': instance.description,
      'icon_url': instance.iconUrl,
      'category': instance.category,
      'rarity': instance.rarity,
    };

UserBadgeModel _$UserBadgeModelFromJson(Map<String, dynamic> json) =>
    UserBadgeModel(
      earnedAt: DateTime.parse(json['earned_at'] as String),
      badge: BadgeInfoModel.fromJson(json['badge'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserBadgeModelToJson(UserBadgeModel instance) =>
    <String, dynamic>{
      'earned_at': instance.earnedAt.toIso8601String(),
      'badge': instance.badge.toJson(),
    };
