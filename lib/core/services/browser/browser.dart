import 'browser_io.dart' if (dart.library.js_interop) 'browser_web.dart' as impl;

/// Ouvre un lien hors de l'appli (ex. `otpauth://` vers l'appli
/// d'authentification). Renvoie `false` si ce n'est pas possible ici.
bool openExternalLink(String url) => impl.openExternalLink(url);

/// Retire un paramètre de l'adresse affichée (web), sans recharger la page.
void removeQueryParameter(String name) => impl.removeQueryParameter(name);
