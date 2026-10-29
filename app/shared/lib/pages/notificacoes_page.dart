import 'package:flutter/material.dart';
import '../components/estado_conteudo.dart';
import '../services/api.dart';
import '../theme/app_theme.dart';
import 'estabelecimento_page.dart';

class NotificacoesPage extends StatefulWidget {
  const NotificacoesPage({required this.api, super.key});
  final ApiService api;

  @override
  State<NotificacoesPage> createState() => _NotificacoesPageState();
}

class _NotificacoesPageState extends State<NotificacoesPage> {
  final List<Map<String, dynamic>> _itens = [];
  final Set<int> _abrindo = {};
  bool _carregando = true;
  bool _temMais = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar({bool mais = false}) async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final dados = await widget.api.listNotificacoes(
        antes: mais && _itens.isNotEmpty
            ? (_itens.last['id_notificacao'] as num).toInt()
            : null,
      );
      final itens = (dados['notificacoes'] as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      if (!mounted) return;
      setState(() {
        if (!mais) _itens.clear();
        _itens.addAll(itens);
        _temMais = dados['temMais'] == true;
      });
    } catch (erro) {
      if (mounted) setState(() => _erro = '$erro');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _abrir(Map<String, dynamic> item) async {
    final id = (item['id_notificacao'] as num).toInt();
    if (!_abrindo.add(id)) return;
    try {
      await widget.api.marcarNotificacaoLida(id);
      if (!mounted) return;
      setState(() => item['lida_em'] = DateTime.now().toIso8601String());
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => EstabelecimentoPage(
            id: (item['id_estabelecimento'] as num).toInt(),
            api: widget.api,
          ),
        ),
      );
    } catch (erro) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$erro')));
      }
    } finally {
      _abrindo.remove(id);
    }
  }

  String _data(Object? valor) {
    final data = DateTime.tryParse('$valor')?.toLocal();
    if (data == null) return '';
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(data.day)}/${dois(data.month)}/${data.year} às ${dois(data.hour)}:${dois(data.minute)}';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Notificações'),
      actions: [
        IconButton(
          tooltip: 'Atualizar notificações',
          onPressed: _carregando ? null : _carregar,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: _carregando && _itens.isEmpty
            ? const CircularProgressIndicator()
            : _erro != null && _itens.isEmpty
            ? EstadoConteudo(
                titulo: 'Não foi possível carregar as notificações',
                descricao: _erro!,
                acao: _carregar,
              )
            : RefreshIndicator(
                onRefresh: _carregar,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (_itens.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Text(
                          'Nenhuma notificação por enquanto. Favorite restaurantes para receber avisos quando eles atualizarem suas informações.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    for (final item in _itens)
                      Card(
                        color: item['lida_em'] == null
                            ? AppTheme.inputFill
                            : null,
                        child: ListTile(
                          leading: Icon(
                            item['lida_em'] == null
                                ? Icons.notifications_active
                                : Icons.notifications_none,
                            color: item['lida_em'] == null
                                ? Colors.amber
                                : AppTheme.textSecondary,
                          ),
                          title: Text(
                            '${item['titulo']}',
                            style: TextStyle(
                              fontWeight: item['lida_em'] == null
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            '${item['mensagem']}\n${_data(item['criado_em'])}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _abrir(item),
                        ),
                      ),
                    if (_erro != null) Text(_erro!),
                    if (_carregando)
                      const Center(child: CircularProgressIndicator()),
                    if (_temMais)
                      TextButton(
                        onPressed: _carregando
                            ? null
                            : () => _carregar(mais: true),
                        child: const Text('Carregar mais'),
                      ),
                  ],
                ),
              ),
      ),
    ),
  );
}
