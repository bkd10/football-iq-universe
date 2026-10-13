import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_mission.freezed.dart';

/// Carrière quotidienne du jour — voir PARTIE 8.5. `videosWatched` est
/// plafonné à 3 pour l'affichage de la progression (le palier est atteint
/// une fois, le compteur serveur peut continuer au-delà sans effet UI).
@freezed
class DailyMission with _$DailyMission {
  const factory DailyMission({
    required DateTime missionDate,
    @Default(false) bool loginCompleted,
    @Default(false) bool videoPosted,
    @Default(false) bool challengeParticipated,
    @Default(0) int videosWatched,
    @Default(0) int coinsEarned,
  }) = _DailyMission;

  const DailyMission._();

  static const int videosWatchedTarget = 3;

  int get completedCount =>
      (loginCompleted ? 1 : 0) +
      (videoPosted ? 1 : 0) +
      (challengeParticipated ? 1 : 0) +
      (videosWatched >= videosWatchedTarget ? 1 : 0);

  static const int totalMissions = 4;
}
