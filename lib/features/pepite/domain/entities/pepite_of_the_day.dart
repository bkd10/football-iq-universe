import 'package:freezed_annotation/freezed_annotation.dart';

part 'pepite_of_the_day.freezed.dart';

/// La Pépite du Jour — voir PARTIE 8.9 : un talent mis en avant à
/// l'ouverture de l'app, choisi parmi les vidéos récentes à fort
/// `talent_score` venant de profils encore peu suivis. "Ici, un inconnu
/// peut devenir une star."
@freezed
class PepiteOfTheDay with _$PepiteOfTheDay {
  const factory PepiteOfTheDay({
    required String videoId,
    required String videoUrl,
    required String caption,
    required String category,
    required int viewsCount,
    required String userId,
    required String username,
    required int stars,
    required int followersCount,
    required int worldRank,
    String? thumbnailUrl,
    String? displayName,
    String? avatarUrl,
    String? country,
    String? city,
    String? playerPosition,
  }) = _PepiteOfTheDay;
}
