import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Coquille de navigation principale — 5 onglets, voir PARTIE 9.1 :
/// Feed / Défis / Créer (bouton central proéminent) / Classements / Profil.
///
/// Basé sur `StatefulShellRoute.indexedStack` : chaque onglet conserve son
/// état de scroll/navigation propre quand on bascule entre eux.
class MainShell extends StatelessWidget {
  const MainShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: _onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: _navBackground,
        selectedItemColor: _lime,
        unselectedItemColor: Colors.white54,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events_outlined),
            activeIcon: Icon(Icons.emoji_events),
            label: 'Défis',
          ),
          BottomNavigationBarItem(
            icon: _CreateTabIcon(),
            activeIcon: _CreateTabIcon(),
            label: 'Créer',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard_outlined),
            activeIcon: Icon(Icons.leaderboard),
            label: 'Classement',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

const _navBackground = Color(0xFF0A1C12);
const _lime = Color(0xFFD8F34A);

/// Bouton central proéminent pour l'onglet "Créer".
class _CreateTabIcon extends StatelessWidget {
  const _CreateTabIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: const BoxDecoration(
        color: _lime,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.add, color: _navBackground, size: 20),
    );
  }
}
