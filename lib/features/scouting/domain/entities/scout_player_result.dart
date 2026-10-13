import 'package:freezed_annotation/freezed_annotation.dart';

part 'scout_player_result.freezed.dart';

/// Résultat de recherche joueur pour un recruteur (PARTIE 8.4/8.5). Ne
/// contient jamais la date de naissance exacte (seulement [isMinor]) —
/// cohérent avec l'absence de géolocalisation précise déjà en place pour le
/// Football Passport public (protection des mineurs).
@freezed
class ScoutPlayerResult with _$ScoutPlayerResult {
  const factory ScoutPlayerResult({
    required String id,
    required String username,
    String? displayName,
    String? avatarUrl,
    String? country,
    String? city,
    String? position,
    required bool isMinor,
    @Default(0) int stars,
    @Default('rookie') String level,
    @Default(0) int followersCount,
  }) = _ScoutPlayerResult;
}
