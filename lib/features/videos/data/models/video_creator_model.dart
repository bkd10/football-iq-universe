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

  VideoCreator toEntity() {
    return VideoCreator(
      id: id,
      username: username,
      displayName: displayName,
      avatarUrl: avatarUrl,
      level: level,
      isVerified: isVerified,
    );
  }
}
