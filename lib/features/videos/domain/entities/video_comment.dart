import 'package:freezed_annotation/freezed_annotation.dart';

import 'video_creator.dart';

part 'video_comment.freezed.dart';

@freezed
class VideoComment with _$VideoComment {
  const factory VideoComment({
    required String id,
    required String videoId,
    required String userId,
    required String content,
    required DateTime createdAt,
    String? parentId,
    @Default(0) int likesCount,
    VideoCreator? author,
  }) = _VideoComment;
}
