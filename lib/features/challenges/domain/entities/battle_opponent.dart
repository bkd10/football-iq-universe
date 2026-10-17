/// Joueur proposé comme adversaire de Battle : quelqu'un que l'on suit ou
/// qui nous suit (RPC `battle_opponent_suggestions`).
class BattleOpponent {
  const BattleOpponent({
    required this.id,
    required this.username,
    this.displayName,
    this.avatarUrl,
    this.iFollow = false,
    this.followsMe = false,
  });

  factory BattleOpponent.fromJson(Map<String, dynamic> json) => BattleOpponent(
        id: json['id'] as String,
        username: json['username'] as String,
        displayName: json['display_name'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        iFollow: json['i_follow'] as bool? ?? false,
        followsMe: json['follows_me'] as bool? ?? false,
      );

  final String id;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final bool iFollow;
  final bool followsMe;

  String get relationLabel {
    if (iFollow && followsMe) return 'Vous vous suivez';
    if (followsMe) return 'Te suit';
    return 'Tu le suis';
  }
}
