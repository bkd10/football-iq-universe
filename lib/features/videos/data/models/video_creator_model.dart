import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/video_creator.dart';

part 'video_creator_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class VideoCreatorModel {
  const VideoCreatorModel({
    required this.id,
    required this.username,
    this.displayName,
    this.avatarUrl,
    this.level = 'rookie',
    this.isVerified = false,
    this.country,
    this.position,
    this.preferredFoot,
    this.stars = 0,
    this.videosCount = 0,
    this.likesReceivedCount = 0,
    this.movesCreatedCount = 0,
    this.challengesWonCount = 0,
  });

  factory VideoCreatorModel.fromJson(Map<String, dynamic> json) =>
      _$VideoCreatorModelFromJson(json);

  Map<String, dynamic> toJson() => _$VideoCreatorModelToJson(this);

  final String id;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final String level;
  final bool isVerified;
  final String? country;
  final String? position;
  final String? preferredFoot;
  final int stars;
  final int videosCount;
  final int likesReceivedCount;
  final int movesCreatedCount;
  final int challengesWonCount;

  VideoCreator toEntity() {
    return VideoCreator(
      id: id,
      username: username,
      displayName: displayName,
      avatarUrl: avatarUrl,
      level: level,
      isVerified: isVerified,
      country: country,
      position: position,
      preferredFoot: preferredFoot,
      stars: stars,
      videosCount: videosCount,
      likesReceivedCount: likesReceivedCount,
      movesCreatedCount: movesCreatedCount,
      challengesWonCount: challengesWonCount,
    );
  }
}
