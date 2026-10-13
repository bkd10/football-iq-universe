import 'package:freezed_annotation/freezed_annotation.dart';

part 'scout_subscription.freezed.dart';

/// Abonnement recruteur — voir `scout_subscriptions`
/// (`20260101000000_initial_schema.sql`), jamais écrit directement par le
/// client : uniquement via `start_scout_trial` pour l'instant (aucun
/// paiement réel branché — voir `20260101000013_scouting_messaging.sql`).
@freezed
class ScoutSubscription with _$ScoutSubscription {
  const factory ScoutSubscription({
    required String plan,
    required String status,
    DateTime? expiresAt,
  }) = _ScoutSubscription;

  const ScoutSubscription._();

  bool get isActive =>
      status == 'active' && (expiresAt == null || expiresAt!.isAfter(DateTime.now()));
}
