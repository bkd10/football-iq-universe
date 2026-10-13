import 'package:freezed_annotation/freezed_annotation.dart';

import 'video_creator.dart';

part 'video.freezed.dart';

/// Une vidéo postée par un joueur — voir PARTIE 8.1/8.2 de la
/// spécification. Peut être un Move original (`isMove`) ou la reproduction
/// d'un Move existant (`originalMoveId` renseigné).
@freezed
class Video with _$Video {
  const factory Video({
    required String id,
    required String userId,
    required String videoUrl,
    required String caption,
    required String category,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? thumbnailUrl,
    int? durationSeconds,
    @Default(false) bool isMove,
    String? moveName,
    String? moveSlug,
    String? originalMoveId,
    @Default(0) int viewsCount,
    @Default(0) int likesCount,
    @Default(0) int masterclassCount,
    @Default(0) int commentsCount,
    @Default(0) int sharesCount,
    @Default(0) int reproductionsCount,
    @Default(0) double talentScore,
    @Default(0) double qualityRatio,
    @Default('active') String status,
    @Default(false) bool isBoosted,
    @Default(false) bool hasLiked,
    @Default(false) bool hasMasterclassed,
    VideoCreator? creator,
  }) = _Video;
}
