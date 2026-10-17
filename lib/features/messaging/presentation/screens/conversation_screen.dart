import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/loaders/app_loader.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../providers/messaging_providers.dart';

/// Fil de discussion joueur ↔ recruteur — voir PARTIE 8.4/8.5.
///
/// Aucune conversation `pending_guardian_approval`/`declined` n'accepte de
/// message (imposé côté serveur par `send_message`) : cet écran se contente
/// de refléter cet état, jamais de le contourner.
class ConversationScreen extends ConsumerStatefulWidget {
  const ConversationScreen({required this.conversationId, super.key});

  final String conversationId;

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _pollTimer;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    ref
        .read(messagingActionsControllerProvider.notifier)
        .markConversationRead(widget.conversationId);
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      ref
          .read(messagesControllerProvider(widget.conversationId).notifier)
          .refresh();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isSending) return;
    setState(() => _isSending = true);
    final success = await ref
        .read(messagesControllerProvider(widget.conversationId).notifier)
        .send(text);
    if (!mounted) return;
    setState(() => _isSending = false);
    if (success) {
      _inputController.clear();
      await ref
          .read(messagesControllerProvider(widget.conversationId).notifier)
          .refresh();
    } else {
      context.showSnackBar('Échec de l\'envoi.'.tr, isError: true);
    }
  }

  Future<void> _shareGuardianLink() async {
    final token = await ref
        .read(messagingActionsControllerProvider.notifier)
        .getGuardianApprovalToken(widget.conversationId);
    if (!mounted) return;
    if (token == null) {
      context.showSnackBar('Impossible de générer le lien.'.tr, isError: true);
      return;
    }
    final myUsername =
        ref.read(currentProfileProvider).valueOrNull?.username ?? 'ce joueur'.tr;
    final text = ('Un recruteur vérifié souhaite contacter {username} sur '
            'Football IQ Universe. Pour approuver ou refuser ce contact, ouvre '
            'l\'app, va dans Réglages > "J\'ai un code tuteur" et saisis ce '
            'code : {token}')
        .trArgs({'username': myUsername, 'token': token});
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    context.showSnackBar('Message copié — colle-le dans SMS/WhatsApp pour ton tuteur.'.tr);
  }

  @override
  Widget build(BuildContext context) {
    final myId = ref.watch(authStateProvider).valueOrNull?.id;
    final conversations =
        ref.watch(conversationsControllerProvider).valueOrNull ?? const [];
    Conversation? conversation;
    for (final c in conversations) {
      if (c.id == widget.conversationId) {
        conversation = c;
        break;
      }
    }
    final isMePlayer = conversation != null && conversation.playerId == myId;
    final messagesAsync =
        ref.watch(messagesControllerProvider(widget.conversationId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          conversation?.otherDisplayName?.isNotEmpty == true
              ? conversation!.otherDisplayName!
              : conversation != null
                  ? '@${conversation.otherUsername ?? 'inconnu'.tr}'
                  : 'Conversation',
        ),
      ),
      body: Column(
        children: [
          if (conversation != null && conversation.isPendingGuardianApproval)
            _StatusBanner(
              color: AppColors.warning,
              icon: Icons.hourglass_top,
              text: isMePlayer
                  ? 'En attente d\'approbation d\'un tuteur avant de pouvoir échanger.'.tr
                  : 'En attente d\'approbation du tuteur du joueur.'.tr,
              actionLabel: isMePlayer ? 'Copier le lien pour ton tuteur'.tr : null,
              onAction: isMePlayer ? _shareGuardianLink : null,
            ),
          if (conversation != null && conversation.isDeclined)
            _StatusBanner(
              color: AppColors.error,
              icon: Icons.block,
              text: 'Ce contact a été refusé.'.tr,
            ),
          Expanded(
            child: messagesAsync.when(
              loading: () => const AppFullScreenLoader(),
              error: (error, _) => Center(
                child: Text(error is Failure ? error.message : 'Erreur de chargement.'.tr),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Aucun message pour l\'instant.'.tr,
                      style: context.textTheme.bodyMedium,
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[messages.length - 1 - index];
                    return _MessageBubble(message: message, isMine: message.senderId == myId);
                  },
                );
              },
            ),
          ),
          if (conversation == null || conversation.isActive)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputController,
                        decoration: InputDecoration(hintText: 'Message...'.tr),
                        maxLines: 4,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    IconButton(
                      icon: _isSending
                          ? const AppLoader(size: 20)
                          : const Icon(Icons.send, color: AppColors.primary),
                      onPressed: _isSending ? null : _send,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.color,
    required this.icon,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  final Color color;
  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      color: color.withValues(alpha: 0.12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(text, style: TextStyle(color: color)),
              ),
            ],
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMine});

  final Message message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.75),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMine ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.body,
              style: TextStyle(color: isMine ? AppColors.background : AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              Formatters.relativeTime(message.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: isMine
                    ? AppColors.background.withValues(alpha: 0.6)
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
