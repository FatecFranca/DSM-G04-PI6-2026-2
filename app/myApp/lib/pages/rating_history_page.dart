import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';

class RatingHistoryPage extends StatelessWidget {
  const RatingHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de Avaliações')),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppTheme.accent.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.history_rounded,
                  color: AppTheme.accent,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Histórico de Avaliações',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Em breve...',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, 2),
    );
  }

  Widget _buildBottomNav(BuildContext context, int currentIndex) {
    return NavigationBar(
      backgroundColor: AppTheme.secondary,
      indicatorColor: AppTheme.accent.withOpacity(0.2),
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            context.go(AppRouter.sugestoes);
            break;
          case 1:
            context.go(AppRouter.rating);
            break;
          case 2:
            context.go(AppRouter.ratingHistory);
            break;
          case 3:
            context.go(AppRouter.user);
            break;
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.lightbulb_outline),
          selectedIcon: Icon(Icons.lightbulb_rounded, color: AppTheme.accent),
          label: 'Sugestões',
        ),
        NavigationDestination(
          icon: Icon(Icons.star_outline_rounded),
          selectedIcon: Icon(Icons.star_rounded, color: AppTheme.accent),
          label: 'Avaliar',
        ),
        NavigationDestination(
          icon: Icon(Icons.history_outlined),
          selectedIcon: Icon(Icons.history_rounded, color: AppTheme.accent),
          label: 'Histórico',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded, color: AppTheme.accent),
          label: 'Perfil',
        ),
      ],
    );
  }
}
