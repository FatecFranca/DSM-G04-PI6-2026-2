import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../components/estado_conteudo.dart';
import '../models/floter_models.dart';
import '../services/floter_service.dart';

class FloterResultadosPage extends StatefulWidget {
  const FloterResultadosPage({required this.preferencias, super.key});
  final PreferenciasFloter preferencias;
  @override
  State<FloterResultadosPage> createState() => _FloterResultadosPageState();
}

class _FloterResultadosPageState extends State<FloterResultadosPage> {
  final _servico = FloterService();
  late Future<List<SugestaoFloter>> _consulta;
  @override
  void initState() {
    super.initState();
    _consulta = _servico.analisarPreferencias(widget.preferencias);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Sugestões do Floter'),
      leading: IconButton(
        tooltip: 'Voltar para descobrir',
        onPressed: () => context.go('/sugestoes'),
        icon: const Icon(Icons.arrow_back),
      ),
    ),
    body: SafeArea(
      child: FutureBuilder<List<SugestaoFloter>>(
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
                () => _consulta = _servico.analisarPreferencias(
                  widget.preferencias,
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
              const SizedBox(height: 12),
              const Text(
                'Com base nas preferências salvas e nas suas interações. Confirme opções alimentares diretamente com o estabelecimento.',
              ),
              const SizedBox(height: 20),
              ...locais.map(
                (local) => Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: const Icon(Icons.restaurant),
                    title: Text(local.nome),
                    subtitle: Text('${local.tipo} · ${local.faixaPreco}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(
                      '/estabelecimentos/${local.idEstabelecimento}',
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
