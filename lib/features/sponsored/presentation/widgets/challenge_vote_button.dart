import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/pressable.dart';
import '../../../challenges/presentation/providers/challenge_providers.dart';
import '../../domain/sponsored_models.dart';
import '../providers/sponsored_providers.dart';

/// Bouton « Voter » d'une vidéo qui participe à un défi, avec le nom du
/// défi et son nombre de votes. Rien du tout pour une vidéo hors défi.
/// Utilisé dans le fil, la page vidéo (ouverte depuis un profil) et les
/// vignettes des profils ([compact]).
class ChallengeVoteButton extends ConsumerStatefulWidget {
  const ChallengeVoteButton({required this.videoId, this.compact = false, super.key});

  final String videoId;
  final bool compact;

  @override
  ConsumerState<ChallengeVoteButton> createState() => _ChallengeVoteButtonState();
}

class _ChallengeVoteButtonState extends ConsumerState<ChallengeVoteButton> {
  bool _sending = false;

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(videoChallengeEntriesProvider(widget.videoId)).valueOrNull;
    if (entries == null || entries.isEmpty) return const SizedBox.shrink();

    final now = DateTime.now();
    final localVotes = ref.watch(localVotesProvider);
    final withLocal = [
      for (final e in entries)
        localVotes[e.challengeId] != null && e.myVoteParticipantId == null
            ? e.withMyVote(localVotes[e.challengeId]!)
            : e,
    ];
    final entry = pickEntry(withLocal, now)!;
    final signedIn = ref.watch(voteSignedInProvider);
    final state = entry.stateAt(now, signedIn: signedIn);

    return widget.compact ? _compact(entry, state) : _large(context, entry, state);
  }

  String _stateText(VideoChallengeEntry e, VoteButtonState s) => switch (s) {
        VoteButtonState.open => 'Voter'.tr,
        VoteButtonState.votedHere => 'Ton vote ✓'.tr,
        VoteButtonState.votedElsewhere => 'Déjà voté dans ce défi'.tr,
        VoteButtonState.ownVideo => 'Ta vidéo'.tr,
        VoteButtonState.notStarted =>
          'Votes dès le {date}'.trArgs({'date': Formatters.shortDate(e.startDate)}),
        VoteButtonState.ended => 'Votes terminés'.tr,
        VoteButtonState.waitingOpponent => 'En attente de l\'adversaire'.tr,
        VoteButtonState.battlePlayer => 'Tu joues cette Battle'.tr,
        VoteButtonState.signIn => 'Connecte-toi pour voter'.tr,
      };

  Widget _compact(VideoChallengeEntry e, VoteButtonState s) {
    final open = s == VoteButtonState.open;
    final voted = s == VoteButtonState.votedHere;
    return Pressable(
      semanticLabel: '{action} — {challenge}, {n} votes'
          .trArgs({'action': _stateText(e, s), 'challenge': e.challengeTitle, 'n': e.votesCount}),
      onTap: open ? () => _vote(e) : () => context.push(RouteNames.challengeDetailPath(e.challengeId)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: open ? AppColors.gold : Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              voted ? Icons.how_to_vote : Icons.how_to_vote_outlined,
              size: 12,
              color: open ? Colors.black : Colors.white,
            ),
            const SizedBox(width: 3),
            Text(
              open ? 'Voter'.tr : '${e.votesCount}',
              style: TextStyle(
                color: open ? Colors.black : Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _large(BuildContext context, VideoChallengeEntry e, VoteButtonState s) {
    final open = s == VoteButtonState.open;
    final voted = s == VoteButtonState.votedHere;
    final label = _stateText(e, s);
    return Semantics(
      container: true,
      label: '{challenge}, {n} votes'.trArgs({'challenge': e.challengeTitle, 'n': e.votesCount}),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsetsDirectional.fromSTEB(10, 6, 6, 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: open ? AppColors.gold : Colors.white24, width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Pressable(
                onTap: () => context.push(RouteNames.challengeDetailPath(e.challengeId)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (e.isSponsored) ...[
                          const _SponsoredMini(),
                          const SizedBox(width: 4),
                        ],
                        Flexible(
                          child: Text(
                            e.challengeTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '{n} votes'.trArgs({'n': e.votesCount}),
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Pressable(
              semanticLabel: label,
              onTap: open && !_sending ? () => _vote(e) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: open
                      ? AppColors.gold
                      : voted
                          ? AppColors.primary
                          : Colors.white12,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_sending)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    else
                      Icon(
                        voted ? Icons.how_to_vote : Icons.how_to_vote_outlined,
                        size: 16,
                        color: open || voted ? Colors.black : Colors.white70,
                      ),
                    const SizedBox(width: 5),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 150),
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: open || voted ? Colors.black : Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _vote(VideoChallengeEntry e) async {
    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await ref
          .read(sponsoredDataSourceProvider)
          .vote(challengeId: e.challengeId, participantId: e.participantId);
      ref.read(localVotesProvider.notifier).update((m) => {...m, e.challengeId: e.participantId});
      ref.invalidate(participationsProvider(e.challengeId));
      messenger?.showSnackBar(SnackBar(content: Text('Vote enregistré 🗳️'.tr)));
    } catch (err) {
      messenger?.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(err is Failure ? err.message : 'Vote impossible.'.tr),
        ),
      );
      // L'état a pu changer (défi terminé, déjà voté ailleurs) : on relit.
      ref.invalidate(videoChallengeEntriesProvider(widget.videoId));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}

class _SponsoredMini extends StatelessWidget {
  const _SponsoredMini();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
      child: Text(
        'Sponsorisé'.tr,
        style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w800),
      ),
    );
  }
}
