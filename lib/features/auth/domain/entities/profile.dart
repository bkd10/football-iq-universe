import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile.freezed.dart';

/// Le profil joueur — cœur du Football Passport (PARTIE 8.4).
///
/// `coins` (Ballons) et `stars` (Football IQ) ne sont jamais modifiés
/// directement depuis le client : ils reflètent l'état côté serveur,
/// mis à jour uniquement par les Edge Functions (`award-coins`,
/// `spend-coins`, `award-stars`).
@freezed
class Profile with _$Profile {
  const factory Profile({
    required String id,
    required String username,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? displayName,
    String? avatarUrl,
    @Default('') String bio,
    String? country,
    String? city,
    DateTime? birthDate,
    String? position,
    @Default('droit') String preferredFoot,
    int? heightCm,
    int? weightKg,
    @Default('player') String role,
    String? guardianName,
    String? guardianEmail,
    @Default(false) bool isVerified,
    String? verificationType,
    @Default(500) int coins,
    @Default(0) int stars,
    @Default('rookie') String level,
    @Default(0) int iqTechnique,
    @Default(0) int iqCreativity,
    @Default(0) int iqPopularity,
    @Default(0) int iqConsistency,
    @Default(0) int iqTactical,
    @Default(0) int streakDays,
    DateTime? lastLoginDate,
    @Default(0) int followersCount,
    @Default(0) int followingCount,
    @Default(0) int videosCount,
    @Default(0) int movesCreatedCount,
    @Default(0) int likesReceivedCount,
    @Default(0) int challengesWonCount,
  }) = _Profile;

  const Profile._();

  /// Affichage indicatif du Football IQ global (la pondération faisant foi
  /// est calculée côté Edge Function `award-stars` — voir PARTIE 6.1).
  int get footballIqTotal =>
      iqTechnique + iqCreativity + iqPopularity + iqConsistency + iqTactical;

  /// Prochain palier de Stars pour changer de niveau, ou `null` si Legend
  /// (niveau maximum — voir PARTIE 6.2).
  int? get nextLevelThreshold => switch (level) {
        'rookie' => 500,
        'rising_star' => 5000,
        'prodigy' => 25000,
        _ => null,
      };

  /// Date de naissance inconnue traitée comme mineure par prudence — miroir
  /// client de la même règle appliquée côté serveur dans
  /// `request_scout_contact`/`scout_search_players`.
  bool get isMinor {
    if (birthDate == null) return true;
    final eighteenYearsAgo =
        DateTime(DateTime.now().year - 18, DateTime.now().month, DateTime.now().day);
    return birthDate!.isAfter(eighteenYearsAgo);
  }
}
