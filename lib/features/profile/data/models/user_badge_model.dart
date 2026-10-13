import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/user_badge.dart';

part 'user_badge_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class BadgeInfoModel {
  const BadgeInfoModel({
    required this.code,
    required this.name,
    this.description,
    this.iconUrl,
    this.category = 'achievement',
    this.rarity = 'common',
  });

  factory BadgeInfoModel.fromJson(Map<String, dynamic> json) =>
      _$BadgeInfoModelFromJson(json);

  Map<String, dynamic> toJson() => _$BadgeInfoModelToJson(this);

  final String code;
  final String name;
  final String? description;
  final String? iconUrl;
  final String category;
  final String rarity;
}

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class UserBadgeModel {
  const UserBadgeModel({required this.earnedAt, required this.badge});

  factory UserBadgeModel.fromJson(Map<String, dynamic> json) =>
      _$UserBadgeModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserBadgeModelToJson(this);

  final DateTime earnedAt;
  final BadgeInfoModel badge;

  UserBadge toEntity() {
    return UserBadge(
      code: badge.code,
      name: badge.name,
      earnedAt: earnedAt,
      description: badge.description,
      iconUrl: badge.iconUrl,
      category: badge.category,
      rarity: badge.rarity,
    );
  }
}
