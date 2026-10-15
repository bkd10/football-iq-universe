import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'player_card_style.dart';

const _sheetBg = Color(0xFF0D2418);
const _lime = Color(0xFFD8F34A);

/// Légende du feed : les onglets, la barre du bas, les couleurs des cartes
/// et les boutons. S'ouvre toute seule la première fois, puis via le « ? ».
class FeedGuideSheet extends StatelessWidget {
  const FeedGuideSheet({super.key});

  static const _seenKey = 'has_seen_feed_guide';

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: _sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const FeedGuideSheet(),
    );
  }

  /// Ouvre la légende si le joueur ne l'a jamais vue sur cet appareil.
  static Future<void> showOnce(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_seenKey) ?? false) return;
    await prefs.setBool(_seenKey, true);
    if (!context.mounted) return;
    await show(context);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'COMMENT ÇA MARCHE',
            style: GoogleFonts.barlowCondensed(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Text(
            'Ici, le talent parle plus que les followers.',
            style: TextStyle(color: _lime, fontWeight: FontWeight.w600),
          ),
          const _Section('Les onglets du feed'),
          const _Line(
            icon: '🔓',
            title: 'Ouverture',
            text: 'Les talents à découvrir, choisis pour leur niveau et pas pour leurs abonnés.',
          ),
          const _Line(
            icon: '🔥',
            title: 'Tendances',
            text: 'Les Moves du moment : les gestes que tout le monde essaie de reproduire.',
          ),
          const _Line(
            icon: '👕',
            title: 'Vestiaire (bientôt)',
            text: 'Les vidéos des joueurs que tu suis.',
          ),
          const _Section('En bas de l’écran'),
          const _Line(
            icon: '🏠',
            title: 'Feed',
            text: 'Les cartes des joueurs, à faire défiler vers le haut.',
          ),
          const _Line(
            icon: '🏆',
            title: 'Défis',
            text: 'Rejoins un défi avec ta vidéo et remporte la cagnotte.',
          ),
          const _Line(
            icon: '➕',
            title: 'Créer',
            text: 'Filme ou publie ta vidéo (5 à 60 secondes).',
          ),
          const _Line(icon: '📊', title: 'Classement', text: 'Les meilleurs joueurs du moment.'),
          const _Line(icon: '👤', title: 'Profil', text: 'Ta carte, tes stats et tes badges.'),
          const _Section('Les couleurs des cartes'),
          const Text(
            'Ta carte change de couleur avec les points de Respect que tu reçois, '
            'comme un disque d’or.',
            style: TextStyle(color: Colors.white70, height: 1.35),
          ),
          const SizedBox(height: 12),
          for (final tier in PlayerCardStyle.tiers) _TierRow(tier),
          const _Section('Les boutons'),
          const _Line(
            icon: '👏',
            title: 'Respect',
            text: 'Tu aimes le geste : +1 point pour le joueur. '
                'Astuce : tape deux fois sur la vidéo.',
          ),
          const _Line(
            icon: '⭐',
            title: 'Masterclass',
            text: 'Le geste est exceptionnel : +3 points. '
                'C’est l’un ou l’autre, Respect ou Masterclass.',
          ),
          const _Line(icon: '💬', title: 'Avis', text: 'Laisse un commentaire au joueur.'),
          const _Line(icon: '↗', title: 'Partager', text: 'Envoie la vidéo à tes potes.'),
          const _Section('Les défis'),
          const _Line(
            icon: '🎯',
            title: 'Challenge',
            text: 'Un geste imposé. Tu rejoins avec une de tes vidéos (20 Ballons).',
          ),
          const _Line(
            icon: '⚔️',
            title: 'Battle',
            text: 'Même principe, en plus relevé (50 Ballons pour entrer).',
          ),
          const _Line(
            icon: '🌍',
            title: 'Monde',
            text: 'Les défis officiels Football IQ, gratuits.',
          ),
          const _Line(
            icon: '🏆',
            title: 'Gagner',
            text: 'Les joueurs votent. À la fin, celui qui a le plus de votes '
                'remporte toute la cagnotte et +100 Stars.',
          ),
          const _Section('Gagner des Ballons'),
          const _Line(icon: '🎁', title: 'Bienvenue', text: '500 Ballons à l’inscription.'),
          const _Line(
            icon: '📅',
            title: 'Chaque jour',
            text: '+20 en te connectant. Bonus de +50 à 7 jours d’affilée, +200 à 30 jours.',
          ),
          const _Line(
            icon: '🎬',
            title: 'Publier',
            text: '+5 par vidéo publiée (3 fois par jour maximum).',
          ),
          const _Line(
              icon: '👀',
              title: 'Regarder',
              text: '+5 quand tu regardes 3 vidéos dans la journée.',),
          const _Line(
            icon: '🔁',
            title: 'Ton Move reproduit',
            text: '+1 chaque fois qu’un joueur reproduit un Move que tu as inventé.',
          ),
          const _Line(
            icon: '🏆',
            title: 'Gagner un défi',
            text: 'Toute la cagnotte du défi est pour toi.',
          ),
          const _Section('La note sur 99'),
          const Text(
            'Elle monte avec ce que le joueur accomplit : vidéos publiées, '
            'points de Respect, Stars, défis gagnés et Moves inventés. '
            'Son nombre d’abonnés ne compte pas.',
            style: TextStyle(color: Colors.white70, height: 1.35),
          ),
          const SizedBox(height: 24),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _lime,
              foregroundColor: _sheetBg,
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('C’est parti !'),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.barlowCondensed(
          color: _lime,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.title, required this.text});

  final String icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 30,
            child: Text(icon, style: const TextStyle(fontSize: 18, color: Colors.white)),
          ),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$title  ',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: text),
                ],
              ),
              style: const TextStyle(color: Colors.white70, height: 1.35, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _TierRow extends StatelessWidget {
  const _TierRow(this.tier);

  final PlayerCardStyle tier;

  @override
  Widget build(BuildContext context) {
    final threshold = tier.minPoints == 0 ? 'Au départ' : 'Dès ${_format(tier.minPoints)} points';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: tier.gradient),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            'CARTE ${tier.label.toUpperCase()}',
            style: GoogleFonts.barlowCondensed(
              color: tier.ink,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          Text(
            threshold,
            style: TextStyle(color: tier.ink, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  static String _format(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}
