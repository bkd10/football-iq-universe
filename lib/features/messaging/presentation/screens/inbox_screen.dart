import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/loaders/app_loader.dart';
import '../../domain/entities/conversation.dart';
import '../providers/messaging_providers.dart';

/// Boîte de réception — commune au joueur et au recruteur (PARTIE 8.4/8.5) :
/// chaque [Conversation] sait déjà qui est "l'autre partie" quel que soit
/// le rôle de l'utilisateur courant (voir `ConversationModel.fromRow`).
class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(conversationsControllerProvider.notifier).refresh(),
        child: conversationsAsync.when(
          loading: () => const AppFullScreenLoader(),
          error: (error, _) => Center(
            child: Text(error is Failure ? error.message : 'Erreur de chargement.'),
          ),
          data: (conversations) {
            if (conversations.isEmpty) {
              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      'Aucune conversation pour l\'instant.',
                      textAlign: TextAlign.center,
                      style: context.textTheme.bodyLarge,
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              itemCount: conversations.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) =>
                  _ConversationTile(conversation: conversations[index]),
            );
          },
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    final subtitle = switch (conversation.status) {
      'pending_guardian_approval' => 'En attente d\'approbation du tuteur',
      'declined' => 'Contact refusé',
      _ => 'Discussion active',
    };
    final subtitleColor = switch (conversation.status) {
      'pending_guardian_approval' => AppColors.warning,
      'declined' => AppColors.error,
      _ => AppColors.textSecondary,
    };

    return ListTile(
      onTap: () => context.push(RouteNames.conversationPath(conversation.id)),
      leading: CircleAvatar(
        backgroundColor: AppColors.surfaceLight,
        backgroundImage: conversation.otherAvatarUrl != null
            ? NetworkImage(conversation.otherAvatarUrl!)
            : null,
        child: conversation.otherAvatarUrl == null
            ? const Icon(Icons.person_outline)
            : null,
      ),
      title: Text(
        conversation.otherDisplayName?.isNotEmpty == true
            ? conversation.otherDisplayName!
            : '@${conversation.otherUsername ?? 'inconnu'}',
        style: TextStyle(
          fontWeight: conversation.hasUnread ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
      subtitle: Text(subtitle, style: TextStyle(color: subtitleColor)),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            Formatters.relativeTime(
              conversation.lastMessageAt ?? conversation.requestedAt,
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (conversation.hasUnread) ...[
            const SizedBox(height: 4),
            const CircleAvatar(radius: 4, backgroundColor: AppColors.primary),
          ],
        ],
      ),
    );
  }
}
