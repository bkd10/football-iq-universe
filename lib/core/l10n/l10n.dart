import 'dart:ui' show Locale, PlatformDispatcher;

import 'strings/registry.dart';

/// Langue de l'appli : celle du téléphone. Le français est la langue source
/// (les textes sont écrits en français dans le code) ; toute autre langue
/// du téléphone sans traduction passe en anglais.
///
/// Ajouter une langue : ajouter son code à [supportedLanguages] et une
/// table pour ce code dans chaque fichier de `strings/`.
class L10n {
  L10n._();

  static const sourceLanguage = 'fr';
  static const fallbackLanguage = 'en';
  static const supportedLanguages = ['fr', 'en', 'es', 'pt', 'de', 'it', 'ar', 'ru', 'sv', 'tr'];

  static String _language = sourceLanguage;
  static String get language => _language;
  static Locale get locale => Locale(_language);
  static List<Locale> get supportedLocales =>
      supportedLanguages.map(Locale.new).toList();

  static Map<String, String> _table = const {};
  static List<ServerPattern> _patterns = const [];

  /// Choisit la langue d'après les langues préférées du téléphone.
  static void init([List<Locale>? deviceLocales]) {
    final locales = deviceLocales ?? PlatformDispatcher.instance.locales;
    var language = fallbackLanguage;
    for (final locale in locales) {
      if (supportedLanguages.contains(locale.languageCode)) {
        language = locale.languageCode;
        break;
      }
    }
    setLanguage(language);
  }

  static void setLanguage(String language) {
    _language = language;
    _table = language == sourceLanguage ? const {} : translationTable(language);
    _patterns = language == sourceLanguage ? const [] : serverPatterns(language);
  }

  static String translate(String text) {
    if (_language == sourceLanguage) return text;
    return _table[text] ?? text;
  }

  /// Textes venant du serveur (messages d'erreur, notifications) : traduction
  /// exacte, sinon par modèle (textes contenant un pseudo, un nombre...).
  static String translateServer(String text) {
    if (_language == sourceLanguage) return text;
    final exact = _table[text];
    if (exact != null) return exact;
    for (final pattern in _patterns) {
      final match = pattern.regex.firstMatch(text);
      if (match != null) {
        var result = pattern.replacement;
        for (var i = 1; i <= match.groupCount; i++) {
          result = result.replaceAll('\$$i', match.group(i) ?? '');
        }
        return result;
      }
    }
    return text;
  }
}

extension Tr on String {
  /// Texte affiché à l'écran, traduit dans la langue du téléphone.
  String get tr => L10n.translate(this);

  /// Comme [tr], pour un texte avec des valeurs : `'Tu as {n} Ballons'
  /// .trArgs({'n': coins})`.
  String trArgs(Map<String, Object?> args) {
    var result = L10n.translate(this);
    args.forEach((key, value) => result = result.replaceAll('{$key}', '$value'));
    return result;
  }

  /// Texte venant du serveur (erreur, notification).
  String get trServer => L10n.translateServer(this);
}
