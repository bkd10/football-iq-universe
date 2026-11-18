import 'package:url_launcher/url_launcher.dart';

/// Android / iOS : ouvre le lien dans l'appli adaptée (navigateur, e-mail,
/// appli d'authentification). L'ouverture est asynchrone : on renvoie
/// `false` seulement si l'adresse est invalide.
bool openExternalLink(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  launchUrl(uri, mode: LaunchMode.externalApplication).catchError((_) => false);
  return true;
}

void removeQueryParameter(String name) {}
