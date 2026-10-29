import 'package:go_router/go_router.dart';
import '../models/floter_models.dart';
import '../pages/floter_page.dart';
import '../pages/floter_resultados_page.dart';
import '../pages/login_page.dart';
import '../pages/rating_history_page.dart';
import '../pages/rating_page.dart';
import '../pages/register_page.dart';
import '../pages/sugestoes_page.dart';
import '../pages/user_page.dart';
import '../pages/estabelecimento_page.dart';
import '../components/estado_conteudo.dart';
import '../services/sessao.dart';
import 'package:flutter/material.dart';

class AppRouter {
  static const home = '/home';
  static const login = '/login';
  static const register = '/register';
  static const sugestoes = '/sugestoes';
  static const user = '/user';
  static const rating = '/rating';
  static const ratingHistory = '/rating-history';
  static const floter = '/floter';
  static const floterResultados = '/floter/resultados';
  static final router = criarRoteador();
  static GoRouter criarRoteador({Sessao? sessao, String? localInicial}) {
    final autenticacao = sessao ?? Sessao.instancia;
    return GoRouter(
      initialLocation:
          localInicial ?? (autenticacao.autenticada ? sugestoes : login),
      refreshListenable: autenticacao,
      redirect: (context, state) {
        final publica =
            state.matchedLocation == login || state.matchedLocation == register;
        return !autenticacao.autenticada && !publica ? login : null;
      },
      errorBuilder: (context, state) => Scaffold(
        body: EstadoConteudo(
          titulo: 'Página não encontrada',
          descricao: 'Volte para continuar navegando.',
          acao: () => context.go(sugestoes),
          textoAcao: 'Voltar',
        ),
      ),
      routes: [
        GoRoute(path: home, redirect: (_, _) => sugestoes),
        GoRoute(path: login, builder: (_, _) => const LoginPage()),
        GoRoute(path: register, builder: (_, _) => const RegisterPage()),
        GoRoute(path: sugestoes, builder: (_, _) => const SugestoesPage()),
        GoRoute(path: user, builder: (_, _) => const UserPage()),
        GoRoute(path: rating, builder: (_, _) => const RatingPage()),
        GoRoute(
          path: ratingHistory,
          builder: (_, _) => const RatingHistoryPage(),
        ),
        GoRoute(path: floter, builder: (_, _) => const FloterPage()),
        GoRoute(
          path: floterResultados,
          redirect: (_, state) =>
              state.extra is PreferenciasFloter ? null : floter,
          builder: (_, state) => FloterResultadosPage(
            preferencias: state.extra! as PreferenciasFloter,
          ),
        ),
        GoRoute(
          path: '/estabelecimentos/:id',
          builder: (_, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '');
            return id == null || id <= 0
                ? const Scaffold(
                    body: EstadoConteudo(
                      titulo: 'Local inválido',
                      descricao: 'Escolha outro estabelecimento.',
                    ),
                  )
                : EstabelecimentoPage(id: id);
          },
        ),
      ],
    );
  }
}
