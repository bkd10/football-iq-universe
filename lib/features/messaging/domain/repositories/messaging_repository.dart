import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/conversation.dart';
import '../entities/message.dart';

/// Contrat du domaine pour la messagerie joueur ↔ recruteur — voir
/// PARTIE 8.4/8.5. Toute la logique anti-triche/médiation-mineur vit côté
/// serveur (fonctions SECURITY DEFINER, voir
/// `20260101000013_scouting_messaging.sql`) : ce repository ne fait que
/// relayer les appels et traduire les erreurs.
abstract class MessagingRepository {
  Future<Either<Failure, List<Conversation>>> getConversations();

  Future<Either<Failure, List<Message>>> getMessages(String conversationId);

  Future<Either<Failure, void>> markConversationRead(String conversationId);

  /// Réservé au joueur concerné — voir `get_guardian_approval_token` côté
  /// serveur, qui vérifie `auth.uid() = player_id`.
  Future<Either<Failure, String>> getGuardianApprovalToken(String conversationId);

  Future<Either<Failure, void>> sendMessage({
    required String conversationId,
    required String body,
  });

  /// Un recruteur demande à contacter un joueur. Retourne le statut de la
  /// conversation créée (`active` ou `pending_guardian_approval`).
  Future<Either<Failure, String>> requestScoutContact(String playerId);

  Future<Either<Failure, void>> approveGuardianContact(String token);

  Future<Either<Failure, void>> declineGuardianContact(String token);
}
