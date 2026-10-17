import '../l10n/l10n.dart';

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

  static Map<String, String> get labels => {
        footballIq: 'IQ Football'.tr,
        technique: 'Technique'.tr,
        creativity: 'Créativité'.tr,
        popularity: 'Popularité'.tr,
        consistency: 'Régularité'.tr,
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
