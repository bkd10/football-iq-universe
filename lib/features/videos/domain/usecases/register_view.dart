import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/video_repository.dart';

/// N'est appelé qu'après [AppConstants.minWatchTimeForView] de visionnage
/// réel (anti-triche) — voir PARTIE 5.4.
class RegisterView {
  const RegisterView(this._repository);

  final VideoRepository _repository;

  Future<Either<Failure, void>> call(String videoId) {
    return _repository.registerView(videoId);
  }
}
