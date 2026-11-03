import 'package:web/web.dart' as web;

bool openExternalLink(String url) {
  web.window.location.href = url;
  return true;
}

void removeQueryParameter(String name) {
  final uri = Uri.parse(web.window.location.href);
  if (!uri.queryParameters.containsKey(name)) return;
  final params = Map.of(uri.queryParameters)..remove(name);
  final cleaned = uri.replace(queryParameters: params.isEmpty ? null : params);
  var href = cleaned.toString();
  if (params.isEmpty) href = href.replaceFirst('?', '');
  web.window.history.replaceState(null, '', href);
}
