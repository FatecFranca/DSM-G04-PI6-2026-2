import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_bottom_nav.dart';
import '../theme/app_theme.dart';

/// A navegação principal ocupa a lateral na web e a base no celular.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.indice,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.sidebarContent,
    super.key,
  });

  final int indice;
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? sidebarContent;

  static bool usaMenuLateral(BuildContext context) =>
      kIsWeb && MediaQuery.sizeOf(context).width >= 1000;

  @override
  Widget build(BuildContext context) {
    final desktop = usaMenuLateral(context);
    return Scaffold(
      appBar: desktop ? null : appBar,
      bottomNavigationBar: desktop ? null : bottomNavigationBar,
      body: desktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 280,
                  child: Material(
                    color: AppTheme.secondary,
                    child: SafeArea(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Tooltip(
                            message: 'Ir para a página inicial',
                            child: InkWell(
                              onTap: () => context.go('/home'),
                              borderRadius: BorderRadius.circular(12),
                              child: const Padding(
                                padding: EdgeInsets.fromLTRB(12, 12, 12, 28),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.restaurant_menu,
                                      color: AppTheme.accent,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'BoraLá',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          for (var i = 0; i < AppBottomNav.rotas.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: ListTile(
                                leading: Icon(_icones[i]),
                                title: Text(_rotulos[i]),
                                selected: indice == i,
                                selectedColor: AppTheme.accent,
                                selectedTileColor: AppTheme.accent.withValues(
                                  alpha: .12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                onTap: () {
                                  if (indice != i) {
                                    context.go(AppBottomNav.rotas[i]);
                                  }
                                },
                              ),
                            ),
                          if (sidebarContent != null) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Divider(height: 1),
                            ),
                            sidebarContent!,
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: Column(
                    children: [
                      ?appBar,
                      Expanded(child: body),
                    ],
                  ),
                ),
              ],
            )
          : body,
    );
  }

  static const _rotulos = [
    'Descobrir',
    'Avaliar',
    'Preferências',
    'Histórico',
    'Perfil',
  ];
  static const _icones = [
    Icons.explore_outlined,
    Icons.star_outline,
    Icons.tune,
    Icons.history,
    Icons.person_outline,
  ];
}
