import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/supabase_provider.dart';
import '../../data/datasources/messaging_remote_datasource.dart';
import '../../data/repositories/messaging_repository_impl.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/messaging_repository.dart';
import '../../domain/usecases/approve_guardian_contact.dart';
import '../../domain/usecases/decline_guardian_contact.dart';
import '../../domain/usecases/get_conversations.dart';
import '../../domain/usecases/get_guardian_approval_token.dart';
import '../../domain/usecases/get_messages.dart';
import '../../domain/usecases/mark_conversation_read.dart';
import '../../domain/usecases/request_scout_contact.dart';
import '../../domain/usecases/send_message.dart';

final messagingRemoteDataSourceProvider =
    Provider<MessagingRemoteDataSource>((ref) {
  return MessagingRemoteDataSource(ref.watch(supabaseClientProvider));
});

final messagingRepositoryProvider = Provider<MessagingRepository>((ref) {
  return MessagingRepositoryImpl(ref.watch(messagingRemoteDataSourceProvider));
});

final getConversationsUseCaseProvider = Provider(
  (ref) => GetConversations(ref.watch(messagingRepositoryProvider)),
);
final getMessagesUseCaseProvider = Provider(
  (ref) => GetMessages(ref.watch(messagingRepositoryProvider)),
);
final sendMessageUseCaseProvider = Provider(
  (ref) => SendMessage(ref.watch(messagingRepositoryProvider)),
);
final markConversationReadUseCaseProvider = Provider(
  (ref) => MarkConversationRead(ref.watch(messagingRepositoryProvider)),
);
final getGuardianApprovalTokenUseCaseProvider = Provider(
  (ref) => GetGuardianApprovalToken(ref.watch(messagingRepositoryProvider)),
);
final requestScoutContactUseCaseProvider = Provider(
  (ref) => RequestScoutContact(ref.watch(messagingRepositoryProvider)),
);
final approveGuardianContactUseCaseProvider = Provider(
  (ref) => ApproveGuardianContact(ref.watch(messagingRepositoryProvider)),
);
final declineGuardianContactUseCaseProvider = Provider(
  (ref) => DeclineGuardianContact(ref.watch(messagingRepositoryProvider)),
);

/// Boîte de réception (joueur ou recruteur, l'écran s'adapte à l'appelant).
class ConversationsController extends AsyncNotifier<List<Conversation>> {
  @override
  Future<List<Conversation>> build() async {
    final result = await ref.read(getConversationsUseCaseProvider)();
    return result.fold((failure) => throw failure, (list) => list);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await ref.read(getConversationsUseCaseProvider)();
      return result.fold((failure) => throw failure, (list) => list);
    });
  }
}

final conversationsControllerProvider =
    AsyncNotifierProvider<ConversationsController, List<Conversation>>(
  ConversationsController.new,
);

/// Fil de messages d'une conversation. Pas de Realtime Supabase branché
/// (portée volontairement réduite pour ce MVP) : [refresh] est appelé par
/// `ConversationScreen` via un polling léger tant que l'écran est ouvert.
class MessagesController extends FamilyAsyncNotifier<List<Message>, String> {
  @override
  Future<List<Message>> build(String conversationId) async {
    final result = await ref.read(getMessagesUseCaseProvider)(conversationId);
    return result.fold((failure) => throw failure, (list) => list);
  }

  Future<void> refresh() async {
    final result = await ref.read(getMessagesUseCaseProvider)(arg);
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (list) => AsyncData(list),
    );
  }

  Future<bool> send(String body) async {
    final result = await ref.read(sendMessageUseCaseProvider)(
      conversationId: arg,
      body: body,
    );
    return result.fold(
      (failure) => false,
      (_) => true,
    );
  }
}

final messagesControllerProvider = AsyncNotifierProvider.family<
    MessagesController, List<Message>, String>(MessagesController.new);

/// Actions ponctuelles (demande de contact, approbation/refus tuteur) —
/// séparées du fil de messages, avec leur propre `AsyncValue` de
/// chargement/erreur affichable directement par l'UI.
class MessagingActionsController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<String?> requestScoutContact(String playerId) async {
    state = const AsyncLoading();
    final result = await ref.read(requestScoutContactUseCaseProvider)(playerId);
    return result.fold(
      (failure) {
        state = AsyncError(failure, StackTrace.current);
        return null;
      },
      (status) {
        state = const AsyncData(null);
        ref.invalidate(conversationsControllerProvider);
        return status;
      },
    );
  }

  Future<String?> getGuardianApprovalToken(String conversationId) async {
    final result = await ref
        .read(getGuardianApprovalTokenUseCaseProvider)(conversationId);
    return result.fold((failure) => null, (token) => token);
  }

  Future<bool> approveGuardianContact(String token) async {
    state = const AsyncLoading();
    final result = await ref.read(approveGuardianContactUseCaseProvider)(token);
    return result.fold(
      (failure) {
        state = AsyncError(failure, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncData(null);
        return true;
      },
    );
  }

  Future<bool> declineGuardianContact(String token) async {
    state = const AsyncLoading();
    final result = await ref.read(declineGuardianContactUseCaseProvider)(token);
    return result.fold(
      (failure) {
        state = AsyncError(failure, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncData(null);
        return true;
      },
    );
  }

  Future<bool> markConversationRead(String conversationId) async {
    final result =
        await ref.read(markConversationReadUseCaseProvider)(conversationId);
    return result.fold((failure) => false, (_) => true);
  }
}

final messagingActionsControllerProvider =
    AsyncNotifierProvider<MessagingActionsController, void>(
  MessagingActionsController.new,
);
