/// Petites transformations de texte utilisées dans les écrans de contenu
/// (catégories, niveaux, hashtags) — évite de dupliquer la logique.
extension StringExtensions on String {
  String get capitalize =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  /// "rising_star" -> "Rising Star"
  String get fromSnakeCaseToTitle =>
      split('_').map((word) => word.capitalize).join(' ');

  bool get isValidUrl => Uri.tryParse(this)?.hasAbsolutePath ?? false;
}
