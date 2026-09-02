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

class AppRouter {
  static const String login = '/login';
  static const String register = '/register';
  static const String sugestoes = '/sugestoes';
  static const String user = '/user';
  static const String rating = '/rating';
  static const String ratingHistory = '/rating-history';
  static const String floter = '/floter';
  static const String floterResultados = '/floter/resultados';

  static final GoRouter router = GoRouter(
    initialLocation: login,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: register,
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: sugestoes,
        name: 'sugestoes',
        builder: (context, state) => const SugestoesPage(),
      ),
      GoRoute(
        path: user,
        name: 'user',
        builder: (context, state) => const UserPage(),
      ),
      GoRoute(
        path: rating,
        name: 'rating',
        builder: (context, state) => const RatingPage(),
      ),
      GoRoute(
        path: floter,
        name: 'floter',
        builder: (context, state) => const FloterPage(),
      ),
      GoRoute(
        path: floterResultados,
        name: 'floter-resultados',
        redirect: (context, state) => state.extra is PreferenciasFloter ? null : floter,
        builder: (context, state) => FloterResultadosPage(preferencias: state.extra! as PreferenciasFloter),
      ),
      GoRoute(
        path: ratingHistory,
        name: 'rating-history',
        builder: (context, state) => const RatingHistoryPage(),
      ),
    ],
  );
}
