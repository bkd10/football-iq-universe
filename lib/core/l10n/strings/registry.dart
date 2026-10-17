// Toutes les tables de traduction de l'appli, une par partie de l'appli.
// Chaque fichier expose `const <nom>Translations = {'en': {'texte fr': 'text'}}`.

/// Modèle pour traduire un texte serveur qui contient des valeurs : `$1`,
/// `$2`... dans [replacement] reprennent les groupes de [regex].
class ServerPattern {
  ServerPattern(String pattern, this.replacement) : regex = RegExp('^$pattern\$');

  final RegExp regex;
  final String replacement;
}

const List<Map<String, Map<String, String>>> _allTables = [];

const Map<String, List<List<String>>> _allPatterns = {};

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
