import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/app_router.dart';
import '../services/api.dart';
import '../theme/app_theme.dart';

class RatingHistoryPage extends StatefulWidget {
  const RatingHistoryPage({super.key});

  @override
  State<RatingHistoryPage> createState() => _RatingHistoryPageState();
}

class _RatingHistoryPageState extends State<RatingHistoryPage> {
  final _api = ApiService();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.listMinhasAvaliacoes();
  }

  Future<void> _refresh() async {
    setState(() => _future = _api.listMinhasAvaliacoes());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de Avaliações')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
          }
          if (snapshot.hasError) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Não foi possível carregar o histórico.\n${snapshot.error}', textAlign: TextAlign.center),
            ));
          }
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return const Center(child: Text('Você ainda não avaliou nenhum restaurante.'));
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                final place = Map<String, dynamic>.from(item['estabelecimento'] as Map);
                final nota = (num.tryParse('${item['valor']}') ?? 0).round();
                final data = DateTime.tryParse('${item['created_at']}')?.toLocal();
                return Card(
                  child: ListTile(
                    title: Text('${place['nome']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text([
                      place['tipo'], place['bairro'],
                      if (data != null) '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}',
                    ].where((v) => v != null && '$v'.isNotEmpty).join(' • ')),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.star_rounded, color: Colors.amber),
                      Text('$nota/5'),
                    ]),
                  ),
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 3,
        onDestinationSelected: (index) {
          final routes = [AppRouter.sugestoes, AppRouter.rating, AppRouter.floter, AppRouter.ratingHistory, AppRouter.user];
          context.go(routes[index]);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.lightbulb_outline), label: 'Sugestões'),
          NavigationDestination(icon: Icon(Icons.star_outline), label: 'Avaliar'),
          NavigationDestination(icon: Icon(Icons.tune), label: 'Preferências'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Histórico'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
      ),
    );
  }
}
