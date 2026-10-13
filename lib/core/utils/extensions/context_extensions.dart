import 'package:flutter/material.dart';

/// Raccourcis DRY pour accéder au thème et à la taille d'écran depuis un
/// `BuildContext`, évite de répéter `Theme.of(context)` partout.
extension ContextExtensions on BuildContext {
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;
  EdgeInsets get viewPadding => MediaQuery.viewPaddingOf(this);

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError
              ? Theme.of(this).colorScheme.error
              : Theme.of(this).colorScheme.surface,
        ),
      );
  }
}
