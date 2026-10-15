import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_mission.freezed.dart';

/// Missions du jour. Ce qui rapporte des Ballons : publier une vidéo, et
/// regarder [fullWatchTarget] vidéos en entier dans la journée.
@freezed
class DailyMission with _$DailyMission {
  const factory DailyMission({
    required DateTime missionDate,
    @Default(false) bool loginCompleted,
    @Default(false) bool videoPosted,
    @Default(false) bool challengeParticipated,
    @Default(0) int videosWatched,
    @Default(0) int coinsEarned,
    @Default(0) int fullVideosWatched,
    @Default(false) bool fullWatchRewarded,
  }) = _DailyMission;

  const DailyMission._();

  /// Miroir d'affichage de `app_config.economy` (valeurs réelles côté serveur).
  static const int fullWatchTarget = 20;
  static const int fullWatchReward = 30;

  int get completedCount => (videoPosted ? 1 : 0) + (fullWatchRewarded ? 1 : 0);

  static const int totalMissions = 2;
}
