import 'package:json_annotation/json_annotation.dart';

import '../../../videos/data/models/video_creator_model.dart';
import '../../domain/entities/challenge_participation.dart';

part 'challenge_participation_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class ChallengeParticipationModel {
  const ChallengeParticipationModel({
    required this.id,
    required this.challengeId,
    required this.userId,
    required this.videoId,
    required this.createdAt,
    this.votesCount = 0,
    this.score,
    this.rank,
    this.participant,
    this.video,
  });

  factory ChallengeParticipationModel.fromJson(Map<String, dynamic> json) =>
      _$ChallengeParticipationModelFromJson(json);

  Map<String, dynamic> toJson() => _$ChallengeParticipationModelToJson(this);

  final String id;
  final String challengeId;
  final String userId;
  final String videoId;
  final DateTime createdAt;
  final int votesCount;
  final double? score;
  final int? rank;
  final VideoCreatorModel? participant;
  @JsonKey(name: 'video')
  final VideoRefModel? video;

  ChallengeParticipation toEntity({bool hasVoted = false}) {
    return ChallengeParticipation(
      id: id,
      challengeId: challengeId,
      userId: userId,
      videoId: videoId,
      createdAt: createdAt,
      votesCount: votesCount,
      score: score,
      rank: rank,
      hasVoted: hasVoted,
      participant: participant?.toEntity(),
      videoUrl: video?.videoUrl,
      videoThumbnailUrl: video?.thumbnailUrl,
    );
  }
}

/// Sous-ensemble de `videos` embarqué pour l'aperçu de la participation
/// (miniature + lecture), sans dupliquer tout `VideoModel`.
@JsonSerializable(fieldRename: FieldRename.snake)
class VideoRefModel {
  const VideoRefModel({required this.videoUrl, this.thumbnailUrl});

  factory VideoRefModel.fromJson(Map<String, dynamic> json) =>
      _$VideoRefModelFromJson(json);

  Map<String, dynamic> toJson() => _$VideoRefModelToJson(this);

  final String videoUrl;
  final String? thumbnailUrl;
}
