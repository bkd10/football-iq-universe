import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../videos/domain/entities/video_creator.dart';

part 'challenge_participation.freezed.dart';

/// Une participation à un défi — voir PARTIE 8.3 (écran "Challenge
/// Voting"). `hasVoted` reflète si l'utilisateur courant a déjà voté pour
/// CE participant (calculé côté repository, comme les likes du feed).
@freezed
class ChallengeParticipation with _$ChallengeParticipation {
  const factory ChallengeParticipation({
    required String id,
    required String challengeId,
    required String userId,
    required String videoId,
    required DateTime createdAt,
    @Default(0) int votesCount,
    double? score,
    int? rank,
    @Default(false) bool hasVoted,
    VideoCreator? participant,
    String? videoUrl,
    String? videoThumbnailUrl,
  }) = _ChallengeParticipation;
}
