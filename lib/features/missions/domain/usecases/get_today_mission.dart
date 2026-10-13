import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/daily_mission.dart';
import '../repositories/missions_repository.dart';

class GetTodayMission {
  const GetTodayMission(this._repository);

  final MissionsRepository _repository;

  Future<Either<Failure, DailyMission>> call() => _repository.getTodayMission();
}
