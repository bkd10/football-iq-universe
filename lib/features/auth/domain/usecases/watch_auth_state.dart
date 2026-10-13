import '../entities/profile.dart';
import '../repositories/auth_repository.dart';

/// Flux réactif de l'état d'authentification — alimente le redirect
/// GoRouter et le splash screen.
class WatchAuthState {
  const WatchAuthState(this._repository);

  final AuthRepository _repository;

  Stream<Profile?> call() => _repository.watchAuthState();
}
