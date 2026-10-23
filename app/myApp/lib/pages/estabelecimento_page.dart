import 'package:flutter/material.dart';
import '../components/estado_conteudo.dart';
import '../services/api.dart';
import '../theme/app_theme.dart';
import 'avaliacoes_page.dart';

class EstabelecimentoPage extends StatefulWidget {
  const EstabelecimentoPage({required this.id, this.api, super.key});
  final int id;
  final ApiService? api;
  @override
  State<EstabelecimentoPage> createState() => _EstabelecimentoPageState();
}

class _EstabelecimentoPageState extends State<EstabelecimentoPage> {
  late final ApiService _api = widget.api ?? ApiService();
  late Future<Map<String, dynamic>> _consulta;
  bool _enviando = false;
  bool _alterou = false;
  bool _registrouVisita = false;
  @override
  void initState() {
    super.initState();
    _consulta = _buscar();
  }

  Future<Map<String, dynamic>> _buscar() async {
    final estabelecimento = await _api.getEstabelecimento(widget.id);
    if (!_registrouVisita && mounted) {
      _registrouVisita = true;
      // Falha de telemetria nao impede a exibicao dos detalhes.
      try {
        await _api.createInteracao(
          idEstabelecimento: widget.id,
          tipoEvento: 'view',
          origem: 'app-flutter-detalhes',
        );
      } catch (_) {
        _registrouVisita = false;
      }
    }
    return estabelecimento;
  }

  Future<void> _interagir(String tipo, {double? nota}) async {
    if (_enviando) return;
    setState(() => _enviando = true);
    try {
      await _api.createInteracao(
        idEstabelecimento: widget.id,
        tipoEvento: tipo,
        valor: nota,
        origem: 'app-flutter-detalhes',
      );
      _alterou = true;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sua interação foi registrada.')),
      );
    } catch (erro) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$erro')));
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _avaliar() async {
    final nota = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Como foi sua experiência?'),
        children: List.generate(
          5,
          (indice) => SimpleDialogOption(
            onPressed: () => Navigator.pop(context, indice + 1),
            child: Semantics(
              label: 'Nota ${indice + 1} de 5',
              button: true,
              child: Row(
                children: [
                  Text('${indice + 1}'),
                  const SizedBox(width: 12),
                  ...List.generate(
                    indice + 1,
                    (_) => const Icon(Icons.star, color: Colors.amber),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (nota != null && mounted) {
      await _interagir('rating', nota: nota.toDouble());
    }
  }

  @override
  Widget build(BuildContext context) => PopScope<Object?>(
    canPop: true,
    child: Scaffold(
      appBar: AppBar(title: const Text('Estabelecimento')),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _consulta,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return EstadoConteudo(
                titulo: 'Não foi possível abrir o local',
                descricao: '${snapshot.error}',
                acao: () => setState(() => _consulta = _buscar()),
              );
            }
            final local = snapshot.data!;
            final ativo = local['ativo'] != false;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: AppTheme.inputFill,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.restaurant,
                        size: 76,
                        color: AppTheme.accent,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '${local['nome']}',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('${local['tipo']} · ${local['faixa_preco']}'),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => AvaliacoesPage(
                            id: widget.id,
                            nome: '${local['nome']}',
                            api: _api,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.reviews_outlined),
                      label: const Text('Ver avaliações e comentários'),
                    ),
                    const SizedBox(height: 12),
                    _informacao(
                      Icons.star,
                      'Avaliação pública',
                      '${local['avaliacao'] ?? 'Não informada'}',
                    ),
                    _informacao(
                      Icons.schedule,
                      'Horário informado',
                      '${local['abre']} às ${local['fecha']}',
                    ),
                    _informacao(
                      Icons.chair,
                      'Ambiente',
                      '${local['ambiente']}',
                    ),
                    _informacao(
                      Icons.people_outline,
                      'Público',
                      '${local['publico']}',
                    ),
                    _informacao(
                      Icons.place_outlined,
                      'Localização',
                      [
                        local['bairro'],
                        local['cidade'],
                      ].where((v) => v != null && '$v'.isNotEmpty).join(', '),
                    ),
                    if (local['tags'] is List)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: (local['tags'] as List)
                              .map((tag) => Chip(label: Text('$tag')))
                              .toList(),
                        ),
                      ),
                    const SizedBox(height: 20),
                    if (!ativo)
                      const Text('Este estabelecimento está indisponível.')
                    else ...[
                      const Text('Ajude a personalizar suas recomendações'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _enviando
                                ? null
                                : () => _interagir('like'),
                            icon: const Icon(Icons.thumb_up_outlined),
                            label: const Text('Gostei'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _enviando
                                ? null
                                : () => _interagir('dislike'),
                            icon: const Icon(Icons.thumb_down_outlined),
                            label: const Text('Não gostei'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _enviando
                                ? null
                                : () => _interagir('favorite'),
                            icon: const Icon(Icons.favorite_outline),
                            label: const Text('Favoritar'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _enviando
                                ? null
                                : () => _interagir('visitado'),
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Já visitei'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: _enviando ? null : _avaliar,
                        icon: const Icon(Icons.star_outline),
                        label: const Text('Avaliar experiência'),
                      ),
                      if (_enviando)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      if (_alterou)
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Text(
                            'As recomendações serão atualizadas com suas interações.',
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
  Widget _informacao(IconData icone, String titulo, String valor) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icone, color: AppTheme.accent),
    title: Text(titulo),
    subtitle: Text(valor.isEmpty ? 'Não informado' : valor),
  );
}
