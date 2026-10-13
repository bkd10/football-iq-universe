import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/pepite_of_the_day.dart';

part 'pepite_of_the_day_model.g.dart';

/// Reflète directement les colonnes renvoyées par la fonction SQL
/// `get_pepite_of_the_day()` (voir migration 20260101000010).
@JsonSerializable(fieldRename: FieldRename.snake)
class PepiteOfTheDayModel {
  const PepiteOfTheDayModel({
    required this.videoId,
    required this.videoUrl,
    required this.caption,
    required this.category,
    required this.viewsCount,
    required this.userId,
    required this.username,
    required this.stars,
    required this.followersCount,
    required this.worldRank,
    this.thumbnailUrl,
    this.displayName,
    this.avatarUrl,
    this.country,
    this.city,
    this.playerPosition,
  });

  factory PepiteOfTheDayModel.fromJson(Map<String, dynamic> json) =>
      _$PepiteOfTheDayModelFromJson(json);

  final String videoId;
  final String videoUrl;
  final String caption;
  final String category;
  final int viewsCount;
  final String userId;
  final String username;
  final int stars;
  final int followersCount;
  final int worldRank;
  final String? thumbnailUrl;
  final String? displayName;
  final String? avatarUrl;
  final String? country;
  final String? city;
  final String? playerPosition;

  PepiteOfTheDay toEntity() {
    return PepiteOfTheDay(
      videoId: videoId,
      videoUrl: videoUrl,
      caption: caption,
      category: category,
      viewsCount: viewsCount,
      userId: userId,
      username: username,
      stars: stars,
      followersCount: followersCount,
      worldRank: worldRank,
      thumbnailUrl: thumbnailUrl,
      displayName: displayName,
      avatarUrl: avatarUrl,
      country: country,
      city: city,
      playerPosition: playerPosition,
    );
  }
}
