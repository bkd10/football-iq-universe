/// Validateurs de formulaires réutilisables (login, register, edit profile).
///
/// Chaque méthode retourne `null` si la valeur est valide, sinon un message
/// d'erreur prêt à être affiché par un `TextFormField.validator`.
class Validators {
  const Validators._();

  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  // Uniquement lettres, chiffres et underscore, 3 à 20 caractères — cohérent
  // avec la contrainte `username_length` côté base de données.
  static final RegExp _usernameRegex = RegExp(r'^[a-zA-Z0-9_]{3,20}$');

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'L\'email est requis.';
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Format d\'email invalide.';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis.';
    }
    if (value.length < 8) {
      return 'Le mot de passe doit contenir au moins 8 caractères.';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value != original) {
      return 'Les mots de passe ne correspondent pas.';
    }
    return null;
  }

  static String? username(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le pseudo est requis.';
    }
    if (!_usernameRegex.hasMatch(value.trim())) {
      return '3 à 20 caractères : lettres, chiffres, underscore.';
    }
    return null;
  }

  static String? required(String? value, {String field = 'Ce champ'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field est requis.';
    }
    return null;
  }
}
