import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../videos/domain/entities/video_creator.dart';

/// Habillage « carte joueur » du feed : couleur de la carte selon le niveau
/// du joueur, note globale, poste et drapeau.
class PlayerCardStyle {
  const PlayerCardStyle._({
    required this.gradient,
    required this.ink,
    required this.inkSoft,
    required this.panel,
    required this.onPanel,
    required this.label,
  });

  factory PlayerCardStyle.forLevel(String level) {
    switch (level) {
      case 'legend':
        return const PlayerCardStyle._(
          gradient: [Color(0xFF1B1B2F), Color(0xFF3A2E6E), Color(0xFF0E7C86)],
          ink: Color(0xFFF4F1FF),
          inkSoft: Color(0xFFB9B3E0),
          panel: Color(0xFF0D0B1F),
          onPanel: Color(0xFF7FE3FF),
          label: 'Légende',
        );
      case 'prodigy':
        return const PlayerCardStyle._(
          gradient: [Color(0xFFF2D27A), Color(0xFFD4A63A), Color(0xFFA9791C)],
          ink: Color(0xFF2A1E05),
          inkSoft: Color(0xFF5E4A1C),
          panel: Color(0xFF2A1E05),
          onPanel: Color(0xFFF2D27A),
          label: 'Prodige',
        );
      case 'rising_star':
        return const PlayerCardStyle._(
          gradient: [Color(0xFFEDEFF1), Color(0xFFBFC6CC), Color(0xFF8D979F)],
          ink: Color(0xFF1C2329),
          inkSoft: Color(0xFF4A555E),
          panel: Color(0xFF1C2329),
          onPanel: Color(0xFFEDEFF1),
          label: 'Espoir',
        );
      default:
        return const PlayerCardStyle._(
          gradient: [Color(0xFFE0A872), Color(0xFFB97A43), Color(0xFF8A5528)],
          ink: Color(0xFF2B1608),
          inkSoft: Color(0xFF5C3A1E),
          panel: Color(0xFF2B1608),
          onPanel: Color(0xFFE0A872),
          label: 'Rookie',
        );
    }
  }

  final List<Color> gradient;

  /// Texte posé directement sur la carte.
  final Color ink;
  final Color inkSoft;

  /// Fond des pastilles (note, boutons) sur la carte.
  final Color panel;

  /// Texte et chiffres posés sur [panel].
  final Color onPanel;
  final String label;
}

/// Note globale affichée sur la carte (45 à 99), calculée à partir de ce
/// que le joueur a réellement accompli : vidéos publiées, Respect reçus,
/// Stars, défis gagnés, Moves inventés. Le talent compte, pas les abonnés.
int playerRating(VideoCreator? creator) {
  if (creator == null) return 45;
  final videos = math.min(creator.videosCount * 2, 16);
  final respect = math.min((math.log(1 + creator.likesReceivedCount) / math.ln2 * 4).round(), 24);
  final stars = math.min(creator.stars, 10);
  final wins = math.min(creator.challengesWonCount * 3, 12);
  final moves = math.min(creator.movesCreatedCount * 2, 8);
  return (45 + videos + respect + stars + wins + moves).clamp(45, 99);
}

String positionShort(String? position) {
  switch (position) {
    case 'attaquant':
      return 'ATT';
    case 'milieu':
      return 'MIL';
    case 'defenseur':
      return 'DÉF';
    case 'gardien':
      return 'GB';
    default:
      return 'JOU';
  }
}

String? footLabel(String? foot) {
  switch (foot) {
    case 'droit':
      return 'pied droit';
    case 'gauche':
      return 'pied gauche';
    case 'les_deux':
      return 'deux pieds';
    default:
      return null;
  }
}

/// Drapeau emoji à partir d'un code pays ISO à 2 lettres (« FR » → 🇫🇷).
String? countryFlag(String? country) {
  if (country == null || country.length != 2) return null;
  final upper = country.toUpperCase();
  if (!RegExp(r'^[A-Z]{2}$').hasMatch(upper)) return null;
  return String.fromCharCodes(upper.codeUnits.map((c) => 0x1F1E6 + c - 0x41));
}
