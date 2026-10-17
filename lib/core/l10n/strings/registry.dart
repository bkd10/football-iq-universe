// Toutes les tables de traduction de l'appli, une par partie de l'appli.
// Chaque fichier expose `const <nom>Translations = {'en': {'texte fr': 'text'}}`.

import 'auth.dart';
import 'auth_errors.dart';
import 'challenges.dart';
import 'common_words.dart';
import 'core.dart';
import 'economy.dart';
import 'lang_ar.dart';
import 'lang_de.dart';
import 'lang_es.dart';
import 'lang_it.dart';
import 'lang_pt.dart';
import 'lang_ru.dart';
import 'lang_sv.dart';
import 'lang_tr.dart';
import 'profile.dart';
import 'server.dart';
import 'social.dart';
import 'videos.dart';

/// Modèle pour traduire un texte serveur qui contient des valeurs : `$1`,
/// `$2`... dans [replacement] reprennent les groupes de [regex].
class ServerPattern {
  ServerPattern(String pattern, this.replacement) : regex = RegExp('^$pattern\$');

  final RegExp regex;
  final String replacement;
}

const List<Map<String, Map<String, String>>> _allTables = [
  coreTranslations,
  commonWordsTranslations,
  authTranslations,
  authErrorsTranslations,
  challengesTranslations,
  economyTranslations,
  profileTranslations,
  socialTranslations,
  videosTranslations,
  serverTranslations,
  arTranslations,
  deTranslations,
  esTranslations,
  itTranslations,
  ptTranslations,
  ruTranslations,
  svTranslations,
  trTranslations,
];

const Map<String, List<List<String>>> _allPatterns = {
  ...serverTranslationPatterns,
  'ar': arServerPatterns,
  'de': deServerPatterns,
  'es': esServerPatterns,
  'it': itServerPatterns,
  'pt': ptServerPatterns,
  'ru': ruServerPatterns,
  'sv': svServerPatterns,
  'tr': trServerPatterns,
};

Map<String, String> translationTable(String language) {
  final table = <String, String>{};
  for (final t in _allTables) {
    table.addAll(t[language] ?? const {});
  }
  return table;
}

List<ServerPattern> serverPatterns(String language) => [
      for (final p in _allPatterns[language] ?? const <List<String>>[])
        ServerPattern(p[0], p[1]),
    ];
