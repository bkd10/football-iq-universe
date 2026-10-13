import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_badge.freezed.dart';

/// Un badge obtenu par un joueur — voir PARTIE 8.7/9.2 (écran "My Badges").
@freezed
class UserBadge with _$UserBadge {
  const factory UserBadge({
    required String code,
    required String name,
    required DateTime earnedAt,
    String? description,
    String? iconUrl,
    @Default('achievement') String category,
    @Default('common') String rarity,
  }) = _UserBadge;
}
