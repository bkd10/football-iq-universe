import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'brand_account_screen.dart';
import 'brand_challenges_screen.dart';

/// Coquille de navigation marque — même principe que `ScoutHomeScreen` :
/// un `Scaffold` + `IndexedStack` autonome plutôt qu'une branche du
/// `StatefulShellRoute` joueur, pour ne pas restructurer l'arborescence de
/// routes existante pour un troisième rôle qui n'a que 2 onglets.
class BrandHomeScreen extends StatefulWidget {
  const BrandHomeScreen({super.key});

  @override
  State<BrandHomeScreen> createState() => _BrandHomeScreenState();
}

class _BrandHomeScreenState extends State<BrandHomeScreen> {
  int _index = 0;

  static const _screens = [
    BrandChallengesScreen(),
    BrandAccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (index) => setState(() => _index = index),
        selectedItemColor: AppColors.primary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events_outlined),
            activeIcon: Icon(Icons.emoji_events),
            label: 'Mes défis',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Compte',
          ),
        ],
      ),
    );
  }
}
