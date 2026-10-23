import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({required this.indice, super.key});
  final int indice;
  static const rotas = [
    '/sugestoes',
    '/rating',
    '/floter',
    '/rating-history',
    '/user',
  ];
  @override
  Widget build(BuildContext context) => NavigationBar(
    selectedIndex: indice,
    backgroundColor: AppTheme.secondary,
    indicatorColor: AppTheme.accent.withValues(alpha: .2),
    labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
    onDestinationSelected: (valor) {
      if (valor != indice) context.go(rotas[valor]);
    },
    destinations: const [
      NavigationDestination(
        icon: Icon(Icons.explore_outlined),
        selectedIcon: Icon(Icons.explore),
        label: 'Descobrir',
      ),
      NavigationDestination(
        icon: Icon(Icons.star_outline),
        selectedIcon: Icon(Icons.star),
        label: 'Avaliar',
      ),
      NavigationDestination(icon: Icon(Icons.tune), label: 'Preferências'),
      NavigationDestination(icon: Icon(Icons.history), label: 'Histórico'),
      NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'Perfil',
      ),
    ],
  );
}
