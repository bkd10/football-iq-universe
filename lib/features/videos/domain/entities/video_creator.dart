import 'package:freezed_annotation/freezed_annotation.dart';

part 'video_creator.freezed.dart';

/// Sous-ensemble du profil du créateur embarqué dans une réponse `videos`
/// (jointure Supabase `profiles`) — évite un aller-retour réseau séparé
/// pour afficher username/avatar/niveau dans le feed.
@freezed
class VideoCreator with _$VideoCreator {
  const factory VideoCreator({
    required String id,
    required String username,
    String? displayName,
    String? avatarUrl,
    @Default('rookie') String level,
    @Default(false) bool isVerified,
    String? country,
    String? position,
    String? preferredFoot,
    @Default(0) int stars,
    @Default(0) int videosCount,
    @Default(0) int likesReceivedCount,
    @Default(0) int movesCreatedCount,
    @Default(0) int challengesWonCount,

    /// Forme sur les 30 derniers jours (-6 à +10), calculée côté serveur.
    @Default(0) int formScore,
  }) = _VideoCreator;
}
