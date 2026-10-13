import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/scout_player_result.dart';

part 'scout_player_result_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ScoutPlayerResultModel {
  const ScoutPlayerResultModel({
    required this.id,
    required this.username,
    this.displayName,
    this.avatarUrl,
    this.country,
    this.city,
    this.position,
    required this.isMinor,
    this.stars = 0,
    this.level = 'rookie',
    this.followersCount = 0,
  });

  factory ScoutPlayerResultModel.fromJson(Map<String, dynamic> json) =>
      _$ScoutPlayerResultModelFromJson(json);

  final String id;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final String? country;
  final String? city;
  final String? position;
  final bool isMinor;
  final int stars;
  final String level;
  final int followersCount;

  ScoutPlayerResult toEntity() {
    return ScoutPlayerResult(
      id: id,
      username: username,
      displayName: displayName,
      avatarUrl: avatarUrl,
      country: country,
      city: city,
      position: position,
      isMinor: isMinor,
      stars: stars,
      level: level,
      followersCount: followersCount,
    );
  }
}
