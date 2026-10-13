import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/daily_mission.dart';

part 'daily_mission_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class DailyMissionModel {
  const DailyMissionModel({
    required this.missionDate,
    this.loginCompleted = false,
    this.videoPosted = false,
    this.challengeParticipated = false,
    this.videosWatched = 0,
    this.coinsEarned = 0,
  });

  factory DailyMissionModel.fromJson(Map<String, dynamic> json) =>
      _$DailyMissionModelFromJson(json);

  Map<String, dynamic> toJson() => _$DailyMissionModelToJson(this);

  final DateTime missionDate;
  final bool loginCompleted;
  final bool videoPosted;
  final bool challengeParticipated;
  final int videosWatched;
  final int coinsEarned;

  DailyMission toEntity() {
    return DailyMission(
      missionDate: missionDate,
      loginCompleted: loginCompleted,
      videoPosted: videoPosted,
      challengeParticipated: challengeParticipated,
      videosWatched: videosWatched,
      coinsEarned: coinsEarned,
    );
  }
}
