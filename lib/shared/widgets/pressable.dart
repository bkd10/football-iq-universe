import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';

/// Remplace `GestureDetector(onTap: ...)` pour tout ce qui se touche :
/// en plus du doigt, l'élément est atteignable au clavier (Tab), s'active
/// avec Entrée ou Espace, montre un contour quand il a le focus et est
/// annoncé comme bouton par les lecteurs d'écran.
class Pressable extends StatefulWidget {
  const Pressable({
    required this.child,
    this.onTap,
    this.behavior,
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final HitTestBehavior? behavior;

  /// Texte lu par le lecteur d'écran quand l'élément n'a pas de texte
  /// visible (image, icône seule).
  final String? semanticLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      onTap: widget.onTap,
      child: FocusableActionDetector(
        enabled: enabled,
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap?.call();
              return null;
            },
          ),
        },
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: widget.behavior,
          excludeFromSemantics: true,
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              border: _focused ? Border.all(color: AppColors.primary, width: 2) : null,
              borderRadius: BorderRadius.circular(6),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
