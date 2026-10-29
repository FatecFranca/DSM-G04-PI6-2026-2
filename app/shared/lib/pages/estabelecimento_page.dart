import '../components/app_scaffold.dart';
import 'package:flutter/material.dart';
import '../components/estado_conteudo.dart';
import '../components/notificacoes_button.dart';
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
  String? _opiniao;
  bool _favorito = false;
  bool _visitado = false;
  double? _nota;
  bool _alterou = false;
  bool _registrouVisita = false;
  @override
  void initState() {
    super.initState();
    _consulta = _buscar();
  }

  Future<Map<String, dynamic>> _buscar() async {
    final estabelecimento = await _api.getEstabelecimento(widget.id);
    final interacoes = await _api.listMinhasInteracoes(widget.id);
    _opiniao = null;
    _favorito = false;
    _visitado = false;
    _nota = null;
    var opiniaoCarregada = false;
    for (final item in interacoes) {
      final tipo = item['tipo_evento'];
      if (!opiniaoCarregada &&
          (tipo == 'like' || tipo == 'dislike' || tipo == 'neutral')) {
        _opiniao = tipo == 'neutral' ? null : tipo as String;
        opiniaoCarregada = true;
      }
      if (tipo == 'favorite') _favorito = true;
      if (tipo == 'visitado') _visitado = true;
      if (tipo == 'rating' && item['valor'] != null) {
        _nota ??= double.tryParse('${item['valor']}');
      }
    }
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
    if ((tipo == 'favorite' && _favorito) ||
        (tipo == 'visitado' && _visitado) ||
        (tipo == 'rating' && nota == _nota)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Essa opção já está selecionada.')),
      );
      return;
    }
    final opiniaoAnterior = _opiniao;
    final ehOpiniao = tipo == 'like' || tipo == 'dislike';
    final evento = ehOpiniao && tipo == _opiniao ? 'neutral' : tipo;
    setState(() {
      _enviando = true;
      if (ehOpiniao) _opiniao = evento == 'neutral' ? null : evento;
    });
    try {
      await _api.createInteracao(
        idEstabelecimento: widget.id,
        tipoEvento: evento,
        valor: nota,
        origem: 'app-flutter-detalhes',
      );
      _alterou = true;
      if (!mounted) return;
      setState(() {
        if (ehOpiniao) _opiniao = evento == 'neutral' ? null : evento;
        if (tipo == 'favorite') _favorito = true;
        if (tipo == 'visitado') _visitado = true;
        if (tipo == 'rating') _nota = nota;
        if (tipo == 'rating') _consulta = _buscar();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sua interação foi registrada.')),
      );
    } catch (erro) {
      if (mounted) {
        setState(() => _opiniao = opiniaoAnterior);
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
                  if (_nota == indice + 1)
                    const Icon(Icons.check_circle, color: Colors.amber),
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
    child: AppScaffold(
      indice: 0,
      appBar: AppBar(
        title: const Text('Estabelecimento'),
        actions: [NotificacoesButton(api: _api)],
      ),
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
            final totalAvaliacoes =
                (local['total_avaliacoes'] as num?)?.toInt() ?? 0;
            final media =
                num.tryParse('${local['avaliacao']}')?.toStringAsFixed(1) ??
                'Não informada';
            final ativo = local['ativo'] != false;
            return LayoutBuilder(
              builder: (context, constraints) {
                final amplo = constraints.maxWidth >= 900;
                final detalhes = _painel('Sobre o estabelecimento', [
                  _informacao(
                    Icons.star,
                    'Avaliação pública',
                    totalAvaliacoes > 0
                        ? '$media · $totalAvaliacoes ${totalAvaliacoes == 1 ? 'avaliação' : 'avaliações'}'
                        : media,
                  ),
                  _informacao(
                    Icons.schedule,
                    'Horário informado',
                    '${local['abre']} às ${local['fecha']}',
                  ),
                  _informacao(
                    Icons.chair,
                    'Ambiente',
                    '${local['ambiente'] ?? ''}',
                  ),
                  _informacao(
                    Icons.people_outline,
                    'Público',
                    '${local['publico'] ?? ''}',
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
                ]);
                final experiencia = _painel('Sua experiência', [
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
                          style: _estiloSelecao(_opiniao == 'like'),
                          onPressed: _enviando
                              ? null
                              : () => _interagir('like'),
                          icon: Icon(
                            _opiniao == 'like'
                                ? Icons.thumb_up
                                : Icons.thumb_up_outlined,
                          ),
                          label: const Text('Gostei'),
                        ),
                        OutlinedButton.icon(
                          style: _estiloSelecao(_opiniao == 'dislike'),
                          onPressed: _enviando
                              ? null
                              : () => _interagir('dislike'),
                          icon: Icon(
                            _opiniao == 'dislike'
                                ? Icons.thumb_down
                                : Icons.thumb_down_outlined,
                          ),
                          label: const Text('Não gostei'),
                        ),
                        OutlinedButton.icon(
                          style: _estiloSelecao(
                            _favorito,
                            cor: Colors.pinkAccent,
                          ),
                          onPressed: _enviando
                              ? null
                              : () => _interagir('favorite'),
                          icon: const Icon(Icons.favorite_outline),
                          label: const Text('Favoritar'),
                        ),
                        OutlinedButton.icon(
                          style: _estiloSelecao(
                            _visitado,
                            cor: Colors.greenAccent,
                          ),
                          onPressed: _enviando
                              ? null
                              : () => _interagir('visitado'),
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Já visitei'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _opiniao == null
                          ? 'Nenhuma opinião selecionada.'
                          : 'Sua escolha: ${_opiniao == 'like' ? 'Gostei' : 'Não gostei'}. Toque novamente para desmarcar.',
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: _enviando ? null : _avaliar,
                      icon: const Icon(Icons.star_outline),
                      label: Text(
                        _nota == null
                            ? 'Avaliar experiência'
                            : 'Sua nota: ${_nota!.toStringAsFixed(0)}/5 · Alterar avaliação',
                      ),
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
                  const SizedBox(height: 16),
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
                ]);
                return SingleChildScrollView(
                  padding: EdgeInsets.all(amplo ? 32 : 20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1240),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _apresentacao(local, media, totalAvaliacoes, amplo),
                          const SizedBox(height: 24),
                          if (amplo)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 3, child: detalhes),
                                const SizedBox(width: 24),
                                Expanded(flex: 2, child: experiencia),
                              ],
                            )
                          else ...[
                            detalhes,
                            const SizedBox(height: 20),
                            experiencia,
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    ),
  );

  Widget _painel(String titulo, List<Widget> children) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: AppTheme.secondary,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withValues(alpha: .07)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          titulo,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    ),
  );
  Widget _apresentacao(
    Map<String, dynamic> local,
    String media,
    int total,
    bool amplo,
  ) => Container(
    padding: EdgeInsets.all(amplo ? 36 : 24),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF54263D), Color(0xFF232139), Color(0xFF142F3C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: AppTheme.accent.withValues(alpha: .2)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CONHEÇA O LOCAL',
                style: TextStyle(
                  color: AppTheme.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${local['nome'] ?? 'Estabelecimento'}',
                style: TextStyle(
                  fontSize: amplo ? 36 : 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final valor in [local['tipo'], local['faixa_preco']])
                    if (valor != null && '$valor'.trim().isNotEmpty)
                      _selo('$valor'),
                  if (total > 0)
                    _selo(
                      '$media / 5 · $total ${total == 1 ? 'avaliação' : 'avaliações'}',
                      icone: Icons.star_rounded,
                    ),
                ],
              ),
            ],
          ),
        ),
        if (amplo) ...[
          const SizedBox(width: 32),
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .04),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(
              Icons.restaurant_menu,
              size: 72,
              color: AppTheme.accent,
            ),
          ),
        ],
      ],
    ),
  );
  Widget _selo(String texto, {IconData? icone}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icone != null) ...[
          Icon(icone, size: 18, color: Colors.amber),
          const SizedBox(width: 6),
        ],
        Flexible(child: Text(texto)),
      ],
    ),
  );
  ButtonStyle _estiloSelecao(bool selecionado, {Color cor = Colors.amber}) =>
      OutlinedButton.styleFrom(
        backgroundColor: selecionado ? cor : Colors.transparent,
        disabledBackgroundColor: selecionado ? cor : Colors.transparent,
        foregroundColor: selecionado ? Colors.black : AppTheme.accent,
        disabledForegroundColor: selecionado
            ? Colors.black
            : AppTheme.textSecondary,
        side: BorderSide(
          color: selecionado ? cor : AppTheme.textPrimary,
          width: selecionado ? 2 : 1,
        ),
        textStyle: TextStyle(
          fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
        ),
      );

  Widget _informacao(IconData icone, String titulo, String valor) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icone, color: AppTheme.accent),
    title: Text(titulo),
    subtitle: Text(valor.isEmpty ? 'Não informado' : valor),
  );
}
