import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/challenge.dart';
import '../entities/challenge_participation.dart';

abstract class ChallengeRepository {
  /// Liste des défis, filtrable par type (`null` = tous). Les défis actifs
  /// (`status IN ('active','voting')`) en premier, triés par date de fin.
  Future<Either<Failure, List<Challenge>>> getChallenges({String? type});

  Future<Either<Failure, Challenge?>> getChallengeById(String challengeId);

  Future<Either<Failure, List<ChallengeParticipation>>> getParticipations(
    String challengeId,
  );

  /// Débite `entry_cost` (RPC `join_challenge`) et inscrit `videoId` comme
  /// participation, atomiquement.
  Future<Either<Failure, void>> joinChallenge({
    required String challengeId,
    required String videoId,
  });

  /// Vote pour un participant (RPC `vote_for_participant` — un seul vote
  /// par défi et par utilisateur, voir UNIQUE(challenge_id, voter_id)).
  Future<Either<Failure, void>> voteForParticipant({
    required String challengeId,
    required String participantUserId,
  });

  /// Débite `create_challenge_cost` (RPC `create_challenge`) et crée le
  /// défi, atomiquement.
  Future<Either<Failure, Challenge>> createChallenge({
    required String title,
    required String description,
    required String type,
    String? category,
    required DateTime endDate,
    int prizePool = 0,
    int? maxParticipants,
    String? recordUnit,
    String? prizeDescription,
  });
}
