import 'package:flutter/material.dart';

/// Contraint l'app à une largeur "mobile" (feed vidéo plein écran, boutons
/// pleine largeur...) même quand elle tourne dans un navigateur de bureau
/// bien plus large. Sans ça, le feed vidéo (pensé pour un écran de
/// téléphone) s'étirerait sur toute la largeur d'une fenêtre desktop —
/// une vidéo verticale à 1920px de large, illisible et déformée.
///
/// En dessous de [_maxContentWidth], ne fait rigoureusement rien (passe
/// [child] tel quel) : sur mobile réel, où l'app doit justement occuper
/// tout l'écran, ce widget est un no-op complet. Posé une seule fois dans
/// `MaterialApp.router(builder: ...)`, donc actif sur TOUT écran sans
/// modifier un seul écran individuellement.
class ResponsiveAppFrame extends StatelessWidget {
  const ResponsiveAppFrame({required this.child, super.key});

  final Widget child;

  static const double _maxContentWidth = 480;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width <= _maxContentWidth) return child;

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: SizedBox(
          width: _maxContentWidth,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              size: Size(_maxContentWidth, MediaQuery.sizeOf(context).height),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
