import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../auth/domain/entities/profile.dart';
import '../../../videos/domain/entities/video.dart';

part 'search_results.freezed.dart';

/// Résultat combiné de l'écran "Search" (PARTIE 9.2, écran 34) : joueurs
/// (par username) et Moves (par nom) — les deux façons de "trouver" un
/// talent ou un geste sur la plateforme.
@freezed
class SearchResults with _$SearchResults {
  const factory SearchResults({
    @Default([]) List<Profile> players,
    @Default([]) List<Video> moves,
  }) = _SearchResults;
}
