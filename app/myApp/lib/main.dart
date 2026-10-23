import 'package:flutter/material.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'services/sessao.dart';

/// Ponto inicial do programa: cria e exibe o widget raiz do aplicativo.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Sessao.instancia.inicializar();
  // runApp entrega ao Flutter o widget que sera a raiz de toda a interface.
  runApp(const MyApp());
}

// StatelessWidget e usado porque configuracoes globais nao mudam dentro deste widget.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  /// Cria o aplicativo Material, aplica o tema global e conecta o roteador.
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Floter',
      debugShowCheckedModeBanner: false,
      // Tema e rotas ficam em arquivos separados para facilitar manutencao.
      theme: AppTheme.dark,
      routerConfig: AppRouter.router,
    );
  }
}
