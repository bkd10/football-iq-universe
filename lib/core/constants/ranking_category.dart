/// Les 5 catégories de classement — voir PARTIE 8.6. Centralisées ici pour
/// être partagées entre le datasource (mapping vers la colonne SQL) et la
/// présentation (libellés/onglets).
class RankingCategory {
  const RankingCategory._();

  static const String technique = 'technique';
  static const String creativity = 'creativity';
  static const String popularity = 'popularity';
  static const String consistency = 'consistency';
  static const String footballIq = 'football_iq';

  static const List<String> all = [
    footballIq,
    technique,
    creativity,
    popularity,
    consistency,
  ];

  static const Map<String, String> labels = {
    footballIq: 'IQ Football',
    technique: 'Technique',
    creativity: 'Créativité',
    popularity: 'Popularité',
    consistency: 'Régularité',
  };

  /// Colonne `profiles` triée pour chaque catégorie.
  static const Map<String, String> columns = {
    footballIq: 'stars',
    technique: 'iq_technique',
    creativity: 'iq_creativity',
    popularity: 'iq_popularity',
    consistency: 'iq_consistency',
  };
}
