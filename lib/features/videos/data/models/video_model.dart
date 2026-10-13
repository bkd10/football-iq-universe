import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/video.dart';
import 'video_creator_model.dart';

part 'video_model.g.dart';

/// Représentation JSON de la table `videos`, avec le profil du créateur
/// embarqué via la jointure Supabase `creator:profiles(...)` (voir
/// `VideoRemoteDataSource._feedSelect`).
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class VideoModel {
  const VideoModel({
    required this.id,
    required this.userId,
    required this.videoUrl,
    required this.caption,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
    this.thumbnailUrl,
    this.durationSeconds,
    this.isMove = false,
    this.moveName,
    this.moveSlug,
    this.originalMoveId,
    this.viewsCount = 0,
    this.likesCount = 0,
    this.masterclassCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.reproductionsCount = 0,
    this.talentScore = 0,
    this.qualityRatio = 0,
    this.status = 'active',
    this.isBoosted = false,
    this.creator,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) =>
      _$VideoModelFromJson(json);

  Map<String, dynamic> toJson() => _$VideoModelToJson(this);

  final String id;
  final String userId;
  final String videoUrl;
  final String caption;
  final String category;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? thumbnailUrl;
  final int? durationSeconds;
  final bool isMove;
  final String? moveName;
  final String? moveSlug;
  final String? originalMoveId;
  final int viewsCount;
  final int likesCount;
  final int masterclassCount;
  final int commentsCount;
  final int sharesCount;
  final int reproductionsCount;
  final double talentScore;
  final double qualityRatio;
  final String status;
  final bool isBoosted;
  final VideoCreatorModel? creator;

  Video toEntity({bool hasLiked = false, bool hasMasterclassed = false}) {
    return Video(
      id: id,
      userId: userId,
      videoUrl: videoUrl,
      caption: caption,
      category: category,
      createdAt: createdAt,
      updatedAt: updatedAt,
      thumbnailUrl: thumbnailUrl,
      durationSeconds: durationSeconds,
      isMove: isMove,
      moveName: moveName,
      moveSlug: moveSlug,
      originalMoveId: originalMoveId,
      viewsCount: viewsCount,
      likesCount: likesCount,
      masterclassCount: masterclassCount,
      commentsCount: commentsCount,
      sharesCount: sharesCount,
      reproductionsCount: reproductionsCount,
      talentScore: talentScore,
      qualityRatio: qualityRatio,
      status: status,
      isBoosted: isBoosted,
      hasLiked: hasLiked,
      hasMasterclassed: hasMasterclassed,
      creator: creator?.toEntity(),
    );
  }
}
