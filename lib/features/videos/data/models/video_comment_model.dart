import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/video_comment.dart';
import 'video_creator_model.dart';

part 'video_comment_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class VideoCommentModel {
  const VideoCommentModel({
    required this.id,
    required this.videoId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.parentId,
    this.likesCount = 0,
    this.author,
  });

  factory VideoCommentModel.fromJson(Map<String, dynamic> json) =>
      _$VideoCommentModelFromJson(json);

  Map<String, dynamic> toJson() => _$VideoCommentModelToJson(this);

  final String id;
  final String videoId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final String? parentId;
  final int likesCount;
  final VideoCreatorModel? author;

  VideoComment toEntity() {
    return VideoComment(
      id: id,
      videoId: videoId,
      userId: userId,
      content: content,
      createdAt: createdAt,
      parentId: parentId,
      likesCount: likesCount,
      author: author?.toEntity(),
    );
  }
}
