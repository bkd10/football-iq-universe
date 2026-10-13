import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';

/// Contrat du domaine pour le graphe social (follows) — volontairement
/// minimal : suivre/ne plus suivre, et savoir si l'utilisateur courant
/// suit déjà un profil donné.
abstract class SocialRepository {
  Future<Either<Failure, bool>> isFollowing(String userId);

  Future<Either<Failure, void>> toggleFollow({
    required String userId,
    required bool currentlyFollowing,
  });
}
