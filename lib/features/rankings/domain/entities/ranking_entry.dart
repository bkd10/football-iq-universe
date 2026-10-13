import 'package:freezed_annotation/freezed_annotation.dart';

part 'ranking_entry.freezed.dart';

/// Une ligne de classement — voir PARTIE 8.6. `score` change de
/// signification selon la catégorie (iq_technique, iq_creativity,
/// iq_popularity, iq_consistency ou stars pour "IQ Football").
@freezed
class RankingEntry with _$RankingEntry {
  const factory RankingEntry({
    required String userId,
    required String username,
    required int score,
    required int rank,
    String? displayName,
    String? avatarUrl,
    @Default('rookie') String level,
    String? country,
    String? city,
  }) = _RankingEntry;
}
