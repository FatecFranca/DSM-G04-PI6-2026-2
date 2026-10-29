import '../components/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../components/app_bottom_nav.dart';
import '../components/estado_conteudo.dart';
import '../services/api.dart';

class RatingHistoryPage extends StatefulWidget {
  const RatingHistoryPage({this.api, super.key});
  final ApiService? api;
  @override
  State<RatingHistoryPage> createState() => _RatingHistoryPageState();
}

class _RatingHistoryPageState extends State<RatingHistoryPage> {
  late final ApiService _api = widget.api ?? ApiService();
  late Future<List<Map<String, dynamic>>> _consulta;
  @override
  void initState() {
    super.initState();
    _consulta = _api.listMinhasAvaliacoes();
  }

  Future<void> _atualizar() async {
    final consulta = _api.listMinhasAvaliacoes();
    setState(() => _consulta = consulta);
    try {
      await consulta;
    } catch (_) {
      /* O FutureBuilder apresenta o erro. */
    }
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
    indice: 3,
    appBar: AppBar(
      title: const Text('Minhas avaliações'),
      actions: [
        IconButton(
          tooltip: 'Atualizar histórico',
          onPressed: _atualizar,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    bottomNavigationBar: const AppBottomNav(indice: 3),
    body: SafeArea(
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _consulta,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return EstadoConteudo(
              titulo: 'Não foi possível carregar o histórico',
              descricao: '${snapshot.error}',
              acao: _atualizar,
            );
          }
          final itens = snapshot.data ?? [];
          return RefreshIndicator(
            onRefresh: _atualizar,
            child: itens.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      EstadoConteudo(
                        titulo: 'Você ainda não avaliou um local',
                        descricao: 'Suas experiências aparecerão aqui.',
                        icone: Icons.star_outline,
                        acao: () => context.go('/rating'),
                        textoAcao: 'Fazer primeira avaliação',
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: itens.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, indice) {
                      final item = itens[indice];
                      final local = Map<String, dynamic>.from(
                        item['estabelecimento'] as Map? ?? {},
                      );
                      final data = DateTime.tryParse(
                        '${item['created_at']}',
                      )?.toLocal();
                      final nota =
                          num.tryParse(
                            '${item['valor']}',
                          )?.toStringAsFixed(0) ??
                          '-';
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          onTap: item['id_estabelecimento'] == null
                              ? null
                              : () => context.push(
                                  '/estabelecimentos/${item['id_estabelecimento']}',
                                ),
                          title: Text('${local['nome'] ?? 'Estabelecimento'}'),
                          subtitle: Text(
                            [
                              if (local['tipo'] != null) '${local['tipo']}',
                              if (data != null)
                                '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}',
                            ].join(' · '),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, color: Colors.amber),
                              Text('$nota/5'),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          );
        },
      ),
    ),
  );
}
