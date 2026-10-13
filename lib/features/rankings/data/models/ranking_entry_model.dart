import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/ranking_entry.dart';

part 'ranking_entry_model.g.dart';

/// `score` est toujours le nom de la colonne côté JSON grâce à l'alias
/// PostgREST `score:<colonne>` construit par `RankingRemoteDataSource` —
/// le modèle n'a donc pas besoin de connaître la catégorie interrogée.
@JsonSerializable(fieldRename: FieldRename.snake)
class RankingEntryModel {
  const RankingEntryModel({
    required this.id,
    required this.username,
    required this.score,
    this.displayName,
    this.avatarUrl,
    this.level = 'rookie',
    this.country,
    this.city,
  });

  factory RankingEntryModel.fromJson(Map<String, dynamic> json) =>
      _$RankingEntryModelFromJson(json);

  Map<String, dynamic> toJson() => _$RankingEntryModelToJson(this);

  final String id;
  final String username;
  final int score;
  final String? displayName;
  final String? avatarUrl;
  final String level;
  final String? country;
  final String? city;

  RankingEntry toEntity(int rank) {
    return RankingEntry(
      userId: id,
      username: username,
      score: score,
      rank: rank,
      displayName: displayName,
      avatarUrl: avatarUrl,
      level: level,
      country: country,
      city: city,
    );
  }
}
