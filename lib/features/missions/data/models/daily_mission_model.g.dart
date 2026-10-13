// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_mission_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DailyMissionModel _$DailyMissionModelFromJson(Map<String, dynamic> json) =>
    DailyMissionModel(
      missionDate: DateTime.parse(json['mission_date'] as String),
      loginCompleted: json['login_completed'] as bool? ?? false,
      videoPosted: json['video_posted'] as bool? ?? false,
      challengeParticipated: json['challenge_participated'] as bool? ?? false,
      videosWatched: (json['videos_watched'] as num?)?.toInt() ?? 0,
      coinsEarned: (json['coins_earned'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$DailyMissionModelToJson(DailyMissionModel instance) =>
    <String, dynamic>{
      'mission_date': instance.missionDate.toIso8601String(),
      'login_completed': instance.loginCompleted,
      'video_posted': instance.videoPosted,
      'challenge_participated': instance.challengeParticipated,
      'videos_watched': instance.videosWatched,
      'coins_earned': instance.coinsEarned,
    };
