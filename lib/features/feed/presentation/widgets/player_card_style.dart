import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../videos/domain/entities/video_creator.dart';

/// Habillage « carte joueur » du feed. La couleur de la carte se gagne par
/// paliers de points de Respect reçus, comme les disques d'or : Bronze,
/// Argent, Or, Platine, Diamant. Un Respect vaut 1 point, une Masterclass 3.
class PlayerCardStyle {
  const PlayerCardStyle._({
    required this.gradient,
    required this.ink,
    required this.inkSoft,
    required this.panel,
    required this.onPanel,
    required this.label,
    required this.minPoints,
  });

  /// Les paliers, du plus bas au plus haut.
  static const tiers = [
    PlayerCardStyle._(
      gradient: [Color(0xFFE0A872), Color(0xFFB97A43), Color(0xFF8A5528)],
      ink: Color(0xFF2B1608),
      inkSoft: Color(0xFF5C3A1E),
      panel: Color(0xFF2B1608),
      onPanel: Color(0xFFE0A872),
      label: 'Bronze',
      minPoints: 0,
    ),
    PlayerCardStyle._(
      gradient: [Color(0xFFEDEFF1), Color(0xFFBFC6CC), Color(0xFF8D979F)],
      ink: Color(0xFF1C2329),
      inkSoft: Color(0xFF4A555E),
      panel: Color(0xFF1C2329),
      onPanel: Color(0xFFEDEFF1),
      label: 'Argent',
      minPoints: 500,
    ),
    PlayerCardStyle._(
      gradient: [Color(0xFFF2D27A), Color(0xFFD4A63A), Color(0xFFA9791C)],
      ink: Color(0xFF2A1E05),
      inkSoft: Color(0xFF5E4A1C),
      panel: Color(0xFF2A1E05),
      onPanel: Color(0xFFF2D27A),
      label: 'Or',
      minPoints: 5000,
    ),
    PlayerCardStyle._(
      gradient: [Color(0xFF1B1B2F), Color(0xFF3A2E6E), Color(0xFF0E7C86)],
      ink: Color(0xFFF4F1FF),
      inkSoft: Color(0xFFB9B3E0),
      panel: Color(0xFF0D0B1F),
      onPanel: Color(0xFF7FE3FF),
      label: 'Platine',
      minPoints: 50000,
    ),
    PlayerCardStyle._(
      gradient: [Color(0xFFF7FDFF), Color(0xFFB5E9F7), Color(0xFF6FC3E0)],
      ink: Color(0xFF07263A),
      inkSoft: Color(0xFF2F5C75),
      panel: Color(0xFF07263A),
      onPanel: Color(0xFFCFF4FF),
      label: 'Diamant',
      minPoints: 500000,
    ),
  ];

  factory PlayerCardStyle.forPoints(int points) =>
      tiers.lastWhere((tier) => points >= tier.minPoints);

  final List<Color> gradient;

  /// Texte posé directement sur la carte.
  final Color ink;
  final Color inkSoft;

  /// Fond des pastilles (note, boutons) sur la carte.
  final Color panel;

  /// Texte et chiffres posés sur [panel].
  final Color onPanel;
  final String label;

  /// Points de Respect à partir desquels on obtient cette carte.
  final int minPoints;
}

/// Note globale affichée sur la carte (40 à 99) = carrière + forme.
///
/// La carrière (45 à 89) ne baisse jamais : vidéos publiées, Respect reçus
/// (échelle logarithmique jusqu'au palier Diamant), Stars, défis gagnés,
/// Moves inventés. Le talent compte, pas les abonnés.
///
/// La forme (-6 à +10) suit les 30 derniers jours : Respect récents,
/// Battles gagnées ou perdues, inactivité. C'est elle qui fait baisser la
/// note d'un joueur qui ne joue plus ou perd ses Battles. Calculée par le
/// serveur (`profiles.form_score`).
int playerRating(VideoCreator? creator) {
  if (creator == null) return 45;
  return (careerRating(creator) + creator.formScore).clamp(40, 99);
}

int careerRating(VideoCreator creator) {
  final respect = math.min((_log10(1 + creator.likesReceivedCount) * 4).round(), 22);
  final videos = math.min(creator.videosCount, 6);
  final stars = math.min(_log10(1 + creator.stars).round(), 3);
  final wins = math.min(creator.challengesWonCount * 2, 10);
  final moves = math.min(creator.movesCreatedCount, 3);
  return 45 + respect + videos + stars + wins + moves;
}

double _log10(num x) => math.log(x) / math.ln10;

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
