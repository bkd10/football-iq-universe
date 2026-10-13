import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/economy_constants.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/services/video_source/picked_video.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/utils/extensions/string_extensions.dart';
import '../../../../core/widgets/buttons/app_primary_button.dart';
import '../../../economy/presentation/providers/economy_providers.dart';
import '../providers/video_providers.dart';

/// Enregistrement/import (15-60s), caption, catégorie et option "Créer un
/// Move" — voir PARTIE 8.2 et 9.2 (écrans Camera/Edit Video/Create Move).
///
/// Si [originalMoveId] est renseigné (venant du bouton "Essayer ce Move"
/// de la fiche d'un Move), l'écran bascule en mode reproduction : l'option
/// "Créer un Move" est masquée et la vidéo publiée est liée au Move
/// d'origine, créditant son inventeur.
class CreateScreen extends ConsumerStatefulWidget {
  const CreateScreen({this.originalMoveId, super.key});

  final String? originalMoveId;

  @override
  ConsumerState<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends ConsumerState<CreateScreen> {
  final _captionController = TextEditingController();
  final _moveNameController = TextEditingController();

  PickedVideo? _pickedVideo;
  VideoPlayerController? _previewController;
  String _category = AppConstants.videoCategories.first;
  bool _isMove = false;
  bool _isUploading = false;
  String? _statusMessage;

  @override
  void dispose() {
    _captionController.dispose();
    _moveNameController.dispose();
    _previewController?.dispose();
    super.dispose();
  }

  Future<void> _pick(bool fromCamera) async {
    final videoSource = ref.read(videoSourceServiceProvider);
    final picked = fromCamera
        ? await videoSource.pickFromCamera()
        : await videoSource.pickFromGallery();
    if (picked == null || !mounted) return;

    final controller = videoSource.createPreviewController(picked);
    try {
      await controller.initialize();
    } catch (_) {
      await controller.dispose();
      if (mounted) {
        context.showSnackBar('Impossible de lire cette vidéo.', isError: true);
      }
      return;
    }

    final duration = controller.value.duration;
    if (duration.inSeconds < AppConstants.minVideoDurationSeconds) {
      await controller.dispose();
      if (mounted) {
        context.showSnackBar(
          'La vidéo doit durer au moins ${AppConstants.minVideoDurationSeconds}s.',
          isError: true,
        );
      }
      return;
    }

    setState(() {
      _pickedVideo = picked;
      _previewController = controller..setLooping(true)..play();
    });
  }

  void _reset() {
    _previewController?.dispose();
    setState(() {
      _pickedVideo = null;
      _previewController = null;
      _captionController.clear();
      _moveNameController.clear();
      _isMove = false;
      _category = AppConstants.videoCategories.first;
    });
  }

  Future<void> _publish() async {
    final picked = _pickedVideo;
    if (picked == null || _isUploading) return;

    if (_isMove && _moveNameController.text.trim().isEmpty) {
      context.showSnackBar('Donne un nom à ton Move.', isError: true);
      return;
    }

    setState(() {
      _isUploading = true;
      _statusMessage = 'Préparation de la vidéo...';
    });

    final durationSeconds = _previewController?.value.duration.inSeconds;
    final prepared =
        await ref.read(videoSourceServiceProvider).prepareForUpload(picked);

    if (!mounted) return;
    setState(() => _statusMessage = 'Publication en cours...');

    final result = await ref.read(uploadVideoUseCaseProvider)(
      videoFile: prepared.file,
      caption: _captionController.text.trim(),
      category: _category,
      durationSeconds: durationSeconds,
      isMove: _isMove,
      moveName: _isMove ? _moveNameController.text.trim() : null,
      originalMoveId: widget.originalMoveId,
      thumbnailFile: prepared.thumbnail,
    );

    if (!mounted) return;
    setState(() {
      _isUploading = false;
      _statusMessage = null;
    });

    result.fold(
      (failure) => context.showSnackBar(failure.message, isError: true),
      (video) {
        ref.read(feedControllerProvider.notifier).refresh();
        ref.read(economyControllerProvider.notifier).awardCoins(
              EconomyReason.postVideo,
              referenceId: video.id,
            );
        context.showSnackBar('Vidéo publiée !');
        _reset();
        context.go(RouteNames.feed);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créer')),
      body: SafeArea(
        child: _pickedVideo == null ? _buildPicker(context) : _buildForm(context),
      ),
    );
  }

  Widget _buildPicker(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_outlined, size: 64, color: AppColors.primary),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Filme ton geste (${AppConstants.minVideoDurationSeconds}-'
              '${AppConstants.maxVideoDurationSeconds}s)',
              style: context.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppPrimaryButton(
              label: 'Filmer',
              icon: Icons.videocam,
              onPressed: () => _pick(true),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: () => _pick(false),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Choisir dans la galerie'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final controller = _previewController;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (controller != null && controller.value.isInitialized)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: GestureDetector(
                  onTap: () => setState(() {
                    controller.value.isPlaying ? controller.pause() : controller.play();
                  }),
                  child: VideoPlayer(controller),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          TextButton.icon(
            onPressed: _isUploading ? null : _reset,
            icon: const Icon(Icons.refresh),
            label: const Text('Changer de vidéo'),
          ),
          if (widget.originalMoveId != null) ...[
            _ReproducingMoveBanner(moveId: widget.originalMoveId!),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _captionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Caption',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Catégorie'),
            items: AppConstants.videoCategories
                .map((c) => DropdownMenuItem(value: c, child: Text(c.capitalize)))
                .toList(),
            onChanged: _isUploading
                ? null
                : (value) {
                    if (value != null) setState(() => _category = value);
                  },
          ),
          if (widget.originalMoveId == null) ...[
            const SizedBox(height: AppSpacing.md),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Créer un Move'),
              subtitle: const Text(
                'Nomme ce geste — les reproductions te créditeront à vie.',
              ),
              value: _isMove,
              activeThumbColor: AppColors.primary,
              onChanged: _isUploading ? null : (value) => setState(() => _isMove = value),
            ),
          ],
          if (_isMove) ...[
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _moveNameController,
              decoration: const InputDecoration(labelText: 'Nom du Move'),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          if (_statusMessage != null) ...[
            Text(
              _statusMessage!,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          AppPrimaryButton(
            label: 'Publier',
            isLoading: _isUploading,
            onPressed: _isUploading ? null : _publish,
          ),
        ],
      ),
    );
  }
}

class _ReproducingMoveBanner extends ConsumerWidget {
  const _ReproducingMoveBanner({required this.moveId});

  final String moveId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moveAsync = ref.watch(videoByIdProvider(moveId));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.repeat, color: AppColors.primary, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: moveAsync.when(
              loading: () => const Text('Chargement du Move...'),
              error: (_, __) => const Text('Tu reproduis un Move.'),
              data: (move) => Text(
                move != null
                    ? 'Tu reproduis "${move.moveName}" de @${move.creator?.username ?? 'inconnu'}'
                    : 'Ce Move est introuvable.',
                style: const TextStyle(color: AppColors.primary, fontSize: 12.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
