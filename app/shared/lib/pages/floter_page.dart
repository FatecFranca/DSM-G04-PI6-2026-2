import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../components/app_bottom_nav.dart';
import '../components/app_scaffold.dart';
import '../components/estado_conteudo.dart';
import '../services/api.dart';

/// Coleta as respostas definidas no artefato de mineração e envia ao recomendador.
class FloterPage extends StatefulWidget {
  const FloterPage({this.api, super.key});
  final ApiService? api;
  @override
  State<FloterPage> createState() => _FloterPageState();
}

class _FloterPageState extends State<FloterPage> {
  late final ApiService _api = widget.api ?? ApiService();
  late Future<List<Map<String, dynamic>>> _carregamento = _api
      .getQuestionarioRecomendacao();
  final Map<String, dynamic> _respostas = {};

  @override
  Widget build(BuildContext context) => AppScaffold(
    indice: 2,
    bottomNavigationBar: const AppBottomNav(indice: 2),
    appBar: AppBar(title: const Text('Descobrir')),
    body: SafeArea(
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _carregamento,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return EstadoConteudo(
              titulo: 'Não foi possível carregar as preferências',
              descricao: '${snapshot.error}',
              acao: () => setState(
                () => _carregamento = _api.getQuestionarioRecomendacao(),
              ),
            );
          }
          final perguntas = snapshot.data ?? [];
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    'Encontre um lugar para você',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Escolha o que importa. A ordem das sugestões considera o modelo de recomendações baseado nos estabelecimentos cadastrados.',
                  ),
                  const SizedBox(height: 20),
                  for (final pergunta in perguntas) _pergunta(pergunta),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => context.push(
                      '/floter/resultados',
                      extra: Map<String, dynamic>.from(_respostas),
                    ),
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Ver recomendações'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );

  Widget _pergunta(Map<String, dynamic> pergunta) {
    final grupo = '${pergunta['id']}';
    final multipla = pergunta['tipo_resposta'] == 'multipla';
    final selecionados = multipla
        ? List<String>.from(_respostas[grupo] as List? ?? const [])
        : <String>[if (_respostas[grupo] != null) '${_respostas[grupo]}'];
    final opcoes = (pergunta['opcoes'] as List? ?? const []).whereType<Map>();
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${pergunta['pergunta']}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final opcao in opcoes)
                  ChoiceChip(
                    label: Text('${opcao['rotulo']}'),
                    selected: selecionados.contains('${opcao['valor']}'),
                    onSelected: (selecionado) => setState(() {
                      final valor = '${opcao['valor']}';
                      if (multipla) {
                        final atual = [...selecionados];
                        if (selecionado) {
                          atual.add(valor);
                        } else {
                          atual.remove(valor);
                        }
                        if (atual.isEmpty) {
                          _respostas.remove(grupo);
                        } else {
                          _respostas[grupo] = atual;
                        }
                      } else if (selecionado) {
                        _respostas[grupo] = valor;
                      }
                    }),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
