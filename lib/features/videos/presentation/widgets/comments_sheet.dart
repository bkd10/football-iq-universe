import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/loaders/app_loader.dart';
import '../providers/video_providers.dart';

/// Bottom sheet des commentaires d'une vidéo — voir PARTIE 9.2 (écran
/// "Comments"). Ouverte depuis le rail d'icônes du feed.
class CommentsSheet extends ConsumerStatefulWidget {
  const CommentsSheet({required this.videoId, super.key});

  final String videoId;

  static Future<void> show(BuildContext context, String videoId) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (context) => CommentsSheet(videoId: videoId),
    );
  }

  @override
  ConsumerState<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<CommentsSheet> {
  final _controller = TextEditingController();
  bool _isPosting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    final content = _controller.text.trim();
    if (content.isEmpty || _isPosting) return;

    setState(() => _isPosting = true);
    final result = await ref.read(addCommentUseCaseProvider)(
      videoId: widget.videoId,
      content: content,
    );
    if (!mounted) return;
    setState(() => _isPosting = false);

    result.fold(
      (failure) => context.showSnackBar(failure.message, isError: true),
      (_) {
        _controller.clear();
        ref.invalidate(videoCommentsProvider(widget.videoId));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(videoCommentsProvider(widget.videoId));

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.75,
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Commentaires', style: context.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              const Divider(height: 1),
              Expanded(
                child: commentsAsync.when(
                  loading: () => const Center(child: AppLoader()),
                  error: (error, _) => Center(
                    child: Text(
                      error is Failure ? error.message : 'Erreur de chargement.',
                      style: context.textTheme.bodyMedium,
                    ),
                  ),
                  data: (comments) {
                    if (comments.isEmpty) {
                      return Center(
                        child: Text(
                          'Aucun commentaire pour l\'instant.',
                          style: context.textTheme.bodyMedium,
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      itemCount: comments.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.surfaceLight,
                              child: Text(
                                (comment.author?.username.isNotEmpty ?? false)
                                    ? comment.author!.username[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '@${comment.author?.username ?? 'inconnu'}',
                                        style: context.textTheme.bodyMedium
                                            ?.copyWith(fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Text(
                                        Formatters.relativeTime(comment.createdAt),
                                        style: context.textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    comment.content,
                                    style: context.textTheme.bodyLarge,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'Ajouter un commentaire...',
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _post(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    IconButton(
                      onPressed: _isPosting ? null : _post,
                      icon: _isPosting
                          ? const AppLoader(size: 20)
                          : const Icon(Icons.send, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
