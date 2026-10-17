import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../messaging/presentation/screens/inbox_screen.dart';
import 'scout_account_screen.dart';
import 'scout_search_screen.dart';

/// Coquille de navigation du recruteur — volontairement un `Scaffold` +
/// `IndexedStack` autonome plutôt qu'un `StatefulShellRoute` GoRouter
/// (comme `MainShell` pour le joueur) : ça évite de restructurer
/// l'arborescence de routes existante (fragile à modifier sans appareil
/// réel pour vérifier chaque branche) pour un second rôle qui n'a que 3
/// onglets, entièrement indépendants du shell joueur.
class ScoutHomeScreen extends StatefulWidget {
  const ScoutHomeScreen({super.key});

  @override
  State<ScoutHomeScreen> createState() => _ScoutHomeScreenState();
}

class _ScoutHomeScreenState extends State<ScoutHomeScreen> {
  int _index = 0;

  static const _screens = [
    ScoutSearchScreen(),
    InboxScreen(),
    ScoutAccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (index) => setState(() => _index = index),
        selectedItemColor: AppColors.primary,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.search_outlined),
            activeIcon: const Icon(Icons.search),
            label: 'Rechercher'.tr,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.mail_outline),
            activeIcon: const Icon(Icons.mail),
            label: 'Messages'.tr,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: 'Compte'.tr,
          ),
        ],
      ),
    );
  }
}
