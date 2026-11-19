import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/pressable.dart';
import '../../../safety/presentation/providers/safety_providers.dart';
import '../../domain/sponsored_models.dart';

/// Carte d'un défi sponsorisé glissée dans le fil, comme une publicité
/// native : étiquette « Sponsorisé » toujours visible (obligatoire, mineurs
/// compris), logo et nom du sponsor, compte à rebours (ou date fixe si le
/// joueur a coupé les comptes à rebours, par défaut chez les moins de
/// 18 ans), participants, boutons Participer et Voir les vidéos.
///
/// [fullPage] : une page entière du fil vertical ; sinon, bandeau (Tendances).
class SponsoredChallengeCard extends ConsumerWidget {
  const SponsoredChallengeCard({required this.challenge, this.fullPage = true, super.key});

  final SponsoredFeedChallenge challenge;
  final bool fullPage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countdowns = ref.watch(mySafetyNowProvider).showCountdowns;
    final now = DateTime.now();
    final started = challenge.hasStartedAt(now);
    final time = Formatters.challengeTime(
      hasStarted: started,
      startDate: challenge.startDate,
      endDate: challenge.endDate,
      countdowns: countdowns,
      startPrefix: 'Votes dans {time}',
    );
    void open() => context.push(RouteNames.challengeDetailPath(challenge.id));

    final content = Column(
      mainAxisSize: fullPage ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SponsoredLabel(),
            const Spacer(),
            Icon(countdowns ? Icons.timer_outlined : Icons.event, color: _lime, size: 16),
            const SizedBox(width: 4),
            Text(time, style: const TextStyle(color: _lime, fontWeight: FontWeight.w700, fontSize: 13)),
          ],
        ),
        SizedBox(height: fullPage ? 24 : 12),
        Row(
          children: [
            _Logo(url: challenge.sponsorLogoUrl, name: challenge.sponsorName, size: fullPage ? 64 : 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Proposé par {sponsor}'.trArgs({'sponsor': challenge.sponsorName}),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    challenge.title.toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.barlowCondensed(
                      color: Colors.white,
                      fontSize: fullPage ? 34 : 24,
                      height: 1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (challenge.description.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            challenge.description,
            maxLines: fullPage ? 6 : 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.35),
          ),
        ],
        if (fullPage) const Spacer() else const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Pill(
              icon: Icons.groups_2_outlined,
              text: '{n} participants'.trArgs({'n': challenge.participantsCount}),
            ),
            _Pill(icon: Icons.star_rounded, text: '+{n} Stars au gagnant'.trArgs({'n': challenge.rewardStars})),
            _Pill(
              icon: Icons.sports_soccer,
              text: challenge.entryCost > 0
                  ? 'Entrée : {n} Ballons'.trArgs({'n': challenge.entryCost})
                  : 'Gratuit, sans achat'.tr,
            ),
            if (challenge.prizeDescription != null && challenge.prizeDescription!.isNotEmpty)
              _Pill(icon: Icons.card_giftcard, text: challenge.prizeDescription!),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _CardButton(
                label: challenge.hasJoined ? 'Tu participes ✓'.tr : 'Participer'.tr,
                filled: !challenge.hasJoined,
                onTap: open,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: _CardButton(label: 'Voir les vidéos'.tr, filled: false, onTap: open)),
          ],
        ),
      ],
    );

    final card = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B1F3A), Color(0xFF3A1C5C), Color(0xFF0D2418)],
        ),
        border: Border.all(color: Colors.white24),
      ),
      child: Padding(padding: const EdgeInsets.all(18), child: content),
    );

    return Semantics(
      container: true,
      label: 'Sponsorisé : {title}, proposé par {sponsor}'
          .trArgs({'title': challenge.title, 'sponsor': challenge.sponsorName}),
      child: fullPage
          ? Padding(padding: const EdgeInsets.fromLTRB(12, 4, 12, 12), child: card)
          : card,
    );
  }
}

/// Étiquette « Sponsorisé », toujours lisible (blanc sur noir, en gras).
class SponsoredLabel extends StatelessWidget {
  const SponsoredLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.campaign_outlined, size: 14, color: Colors.black),
          const SizedBox(width: 4),
          Text(
            'Sponsorisé'.tr,
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.url, required this.name, required this.size});

  final String? url;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = Center(
      child: Text(
        name.isEmpty ? '?' : name.characters.first.toUpperCase(),
        style: TextStyle(color: Colors.black, fontSize: size * 0.45, fontWeight: FontWeight.w900),
      ),
    );
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(size / 4)),
      child: url == null
          ? fallback
          : CachedNetworkImage(
              imageUrl: url!,
              fit: BoxFit.contain,
              errorWidget: (context, url, error) => fallback,
            ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardButton extends StatelessWidget {
  const _CardButton({required this.label, required this.filled, required this.onTap});

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? _lime : Colors.transparent,
          border: Border.all(color: filled ? _lime : Colors.white70, width: 1.5),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: filled ? Colors.black : Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

const _lime = Color(0xFFD8F34A);
