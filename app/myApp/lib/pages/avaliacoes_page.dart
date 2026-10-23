import 'package:flutter/material.dart';
import '../components/estado_conteudo.dart';
import '../services/api.dart';
import '../theme/app_theme.dart';

class AvaliacoesPage extends StatefulWidget {
  const AvaliacoesPage({
    required this.id,
    required this.nome,
    required this.api,
    super.key,
  });
  final int id;
  final String nome;
  final ApiService api;

  @override
  State<AvaliacoesPage> createState() => _AvaliacoesPageState();
}

class _AvaliacoesPageState extends State<AvaliacoesPage> {
  final List<Map<String, dynamic>> _avaliacoes = [];
  int _pagina = 1;
  bool _carregando = false;
  bool _temMais = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    if (_carregando) return;
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final dados = await widget.api.getAvaliacoesEstabelecimento(
        widget.id,
        pagina: _pagina,
      );
      final lista = (dados['avaliacoes'] as List)
          .map((v) => Map<String, dynamic>.from(v as Map))
          .toList();
      if (!mounted) return;
      setState(() {
        _avaliacoes.addAll(lista);
        _temMais = dados['temMais'] == true;
        _pagina++;
      });
    } catch (erro) {
      if (mounted) setState(() => _erro = '$erro');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Avaliações e comentários')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(widget.nome, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text(
              'Experiências da comunidade · Mais recentes primeiro',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            for (final avaliacao in _avaliacoes) _cartao(avaliacao),
            if (_carregando)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (_erro != null)
              EstadoConteudo(
                titulo: 'Não foi possível carregar as avaliações',
                descricao: _erro!,
                acao: _carregar,
              ),
            if (!_carregando && _erro == null && _avaliacoes.isEmpty)
              const EstadoConteudo(
                titulo: 'Ainda não há avaliações',
                descricao:
                    'As notas e os comentários publicados pelos usuários aparecerão aqui.',
                icone: Icons.chat_bubble_outline,
              ),
            if (!_carregando &&
                _erro == null &&
                _temMais &&
                _avaliacoes.isNotEmpty)
              OutlinedButton(
                onPressed: _carregar,
                child: const Text('Carregar mais avaliações'),
              ),
          ],
        ),
      ),
    ),
  );

  Widget _cartao(Map<String, dynamic> avaliacao) {
    final nome = '${avaliacao['nome'] ?? 'Usuário'}'.trim();
    final nota = double.tryParse('${avaliacao['nota']}');
    final comentario = '${avaliacao['comentario'] ?? ''}'.trim();
    final data = DateTime.tryParse('${avaliacao['created_at']}')?.toLocal();
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.person_outline)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    nome.isEmpty ? 'Usuário' : nome,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (nota != null) ...[
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                  const SizedBox(width: 4),
                  Text('${nota.toStringAsFixed(1)} / 5'),
                ],
              ],
            ),
            if (data != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              comentario.isEmpty ? 'Avaliação sem comentário.' : comentario,
              style: TextStyle(
                height: 1.5,
                color: comentario.isEmpty ? AppTheme.textSecondary : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
