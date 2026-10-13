import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_notification.freezed.dart';

/// Une notification — voir PARTIE 3.2 (table `notifications`) et 9.2
/// (écran 31). `type` pilote l'icône et la navigation au tap :
/// new_follower, like, comment, challenge_ended, challenge_won,
/// badge_earned, move_reproduced, scout_interest.
@freezed
class AppNotification with _$AppNotification {
  const factory AppNotification({
    required String id,
    required String type,
    required String title,
    required DateTime createdAt,
    @Default(false) bool isRead,
    String? body,
    String? actorId,
    String? actorUsername,
    String? actorAvatarUrl,
    String? referenceType,
    String? referenceId,
  }) = _AppNotification;
}
