import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/scout_player_result.dart';
import '../entities/scout_subscription.dart';

abstract class ScoutingRepository {
  Future<Either<Failure, List<ScoutPlayerResult>>> searchPlayers({
    String? query,
    String? position,
    String? country,
  });

  Future<Either<Failure, void>> startTrial();

  Future<Either<Failure, ScoutSubscription?>> getMySubscription();
}
