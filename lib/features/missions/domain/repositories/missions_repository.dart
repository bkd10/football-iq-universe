import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/daily_mission.dart';

abstract class MissionsRepository {
  Future<Either<Failure, DailyMission>> getTodayMission();

  /// Incrémente le compteur "vidéos regardées" du jour, en appelant la RPC
  /// `increment_videos_watched` (attribue le bonus de palier côté serveur).
  Future<Either<Failure, void>> incrementVideosWatched();
}
