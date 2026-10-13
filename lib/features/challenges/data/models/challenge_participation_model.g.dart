// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'challenge_participation_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChallengeParticipationModel _$ChallengeParticipationModelFromJson(
        Map<String, dynamic> json) =>
    ChallengeParticipationModel(
      id: json['id'] as String,
      challengeId: json['challenge_id'] as String,
      userId: json['user_id'] as String,
      videoId: json['video_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      votesCount: (json['votes_count'] as num?)?.toInt() ?? 0,
      score: (json['score'] as num?)?.toDouble(),
      rank: (json['rank'] as num?)?.toInt(),
      participant: json['participant'] == null
          ? null
          : VideoCreatorModel.fromJson(
              json['participant'] as Map<String, dynamic>),
      video: json['video'] == null
          ? null
          : VideoRefModel.fromJson(json['video'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ChallengeParticipationModelToJson(
        ChallengeParticipationModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'challenge_id': instance.challengeId,
      'user_id': instance.userId,
      'video_id': instance.videoId,
      'created_at': instance.createdAt.toIso8601String(),
      'votes_count': instance.votesCount,
      'score': instance.score,
      'rank': instance.rank,
      'participant': instance.participant?.toJson(),
      'video': instance.video?.toJson(),
    };

VideoRefModel _$VideoRefModelFromJson(Map<String, dynamic> json) =>
    VideoRefModel(
      videoUrl: json['video_url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
    );

Map<String, dynamic> _$VideoRefModelToJson(VideoRefModel instance) =>
    <String, dynamic>{
      'video_url': instance.videoUrl,
      'thumbnail_url': instance.thumbnailUrl,
    };
