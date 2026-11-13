import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../components/estado_conteudo.dart';
import '../services/api.dart';

class FloterResultadosPage extends StatefulWidget {
  const FloterResultadosPage({required this.respostas, super.key});
  final Map<String, dynamic> respostas;
  @override
  State<FloterResultadosPage> createState() => _FloterResultadosPageState();
}

class _FloterResultadosPageState extends State<FloterResultadosPage> {
  final _api = ApiService();
  late Future<List<Map<String, dynamic>>> _consulta = _api.recomendar(
    respostas: widget.respostas,
    k: 20,
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Sugestões do BoraLá'),
      leading: IconButton(
        tooltip: 'Voltar para descobrir',
        onPressed: () => context.go('/floter'),
        icon: const Icon(Icons.arrow_back),
      ),
    ),
    body: SafeArea(
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _consulta,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return EstadoConteudo(
              titulo: 'Não foi possível buscar sugestões',
              descricao: '${snapshot.error}',
              acao: () => setState(
                () => _consulta = _api.recomendar(
                  respostas: widget.respostas,
                  k: 20,
                ),
              ),
            );
          }
          final locais = snapshot.data ?? [];
          if (locais.isEmpty) {
            return EstadoConteudo(
              titulo: 'Nenhum local disponível',
              descricao: 'Tente outras preferências.',
              acao: () => context.go('/floter'),
              textoAcao: 'Ajustar preferências',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Encontramos ${locais.length} locais para você',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'A compatibilidade e a qualidade dos locais são calculadas pelo modelo de mineração.',
              ),
              const SizedBox(height: 16),
              ...locais.map(
                (local) => Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: const Icon(Icons.restaurant),
                    title: Text('${local['nome']}'),
                    subtitle: Text(
                      '${local['tipo']} · ${local['faixa_preco']} · Compatibilidade ${local['compatibilidade'] ?? '—'}%\n${(local['motivos'] as List? ?? const []).join(' · ')}',
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(
                      '/estabelecimentos/${local['id_estabelecimento']}',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => context.go('/sugestoes'),
                child: const Text('Explorar todos os locais'),
              ),
            ],
          );
        },
      ),
    ),
  );
}
