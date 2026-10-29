import 'package:flutter/material.dart';
import '../components/app_scaffold.dart';
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
  final Set<int> _curtindo = {};

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
  Widget build(BuildContext context) => AppScaffold(
    indice: 0,
    appBar: AppBar(title: const Text('Avaliações e comentários')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1160),
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
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF54263D), AppTheme.secondary],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final texto = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Como foi sua visita?',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Compartilhe sua experiência e ajude outras pessoas a escolher.',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  );
                  final botao = FilledButton.icon(
                    onPressed: _carregando ? null : _comentar,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Deixar um comentário'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                  );
                  return constraints.maxWidth >= 700
                      ? Row(
                          children: [
                            Expanded(child: texto),
                            const SizedBox(width: 24),
                            botao,
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [texto, const SizedBox(height: 20), botao],
                        );
                },
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Comentários da comunidade',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
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

  Future<void> _comentar() async {
    final publicou = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ComentarioDialog(api: widget.api, id: widget.id),
    );
    if (publicou != true || !mounted) return;
    setState(() {
      _avaliacoes.clear();
      _pagina = 1;
      _temMais = true;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Comentário publicado!')));
    await _carregar();
  }

  Widget _cartao(Map<String, dynamic> avaliacao) {
    final nome = '${avaliacao['nome'] ?? 'Usuário'}'.trim();
    final nota = double.tryParse('${avaliacao['nota']}');
    final comentario = '${avaliacao['comentario'] ?? ''}'.trim();
    final data = DateTime.tryParse('${avaliacao['created_at']}')?.toLocal();
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withValues(alpha: .08)),
      ),
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
            if (comentario.isNotEmpty &&
                avaliacao['id_classificacao'] is num) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed:
                    avaliacao['proprio'] == true ||
                        avaliacao['curtido'] == true ||
                        _curtindo.contains(
                          (avaliacao['id_classificacao'] as num).toInt(),
                        )
                    ? null
                    : () => _curtir(avaliacao),
                icon: Icon(
                  avaliacao['curtido'] == true
                      ? Icons.favorite
                      : Icons.favorite_outline,
                ),
                label: Text(
                  '${avaliacao['curtido'] == true ? 'Curtido' : 'Curtir'} · ${avaliacao['total_curtidas'] ?? 0}',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _curtir(Map<String, dynamic> comentario) async {
    final id = (comentario['id_classificacao'] as num).toInt();
    if (_curtindo.contains(id)) return;
    setState(() => _curtindo.add(id));
    try {
      final resultado = await widget.api.curtirComentario(widget.id, id);
      if (mounted) setState(() => comentario.addAll(resultado));
    } catch (erro) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$erro')));
      }
    } finally {
      if (mounted) setState(() => _curtindo.remove(id));
    }
  }
}

class _ComentarioDialog extends StatefulWidget {
  const _ComentarioDialog({required this.api, required this.id});
  final ApiService api;
  final int id;
  @override
  State<_ComentarioDialog> createState() => _ComentarioDialogState();
}

class _ComentarioDialogState extends State<_ComentarioDialog> {
  final _texto = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _enviando = false;
  String? _erro;

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  Future<void> _publicar() async {
    if (_enviando || !_form.currentState!.validate()) return;
    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      await widget.api.publicarComentario(widget.id, _texto.text);
      if (mounted) Navigator.pop(context, true);
    } catch (erro) {
      if (mounted) {
        setState(() {
          _erro = '$erro';
          _enviando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_enviando,
    child: AlertDialog(
      title: const Text('Deixar um comentário'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Conte o que achou da comida, do atendimento ou do ambiente.',
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _texto,
                  enabled: !_enviando,
                  autofocus: true,
                  minLines: 4,
                  maxLines: 7,
                  maxLength: 2000,
                  decoration: const InputDecoration(
                    labelText: 'Seu comentário',
                    alignLabelWithHint: true,
                  ),
                  validator: (valor) => valor == null || valor.trim().isEmpty
                      ? 'Escreva um comentário antes de publicar.'
                      : null,
                ),
                if (_erro != null)
                  Text(_erro!, style: const TextStyle(color: AppTheme.accent)),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _enviando ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _enviando ? null : _publicar,
          child: Text(_enviando ? 'Publicando…' : 'Publicar comentário'),
        ),
      ],
    ),
  );
}
