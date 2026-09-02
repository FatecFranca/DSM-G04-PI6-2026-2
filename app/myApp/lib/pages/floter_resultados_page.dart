import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/floter_models.dart';
import '../router/app_router.dart';
import '../services/floter_service.dart';
import '../theme/app_theme.dart';

class FloterResultadosPage extends StatefulWidget {
  const FloterResultadosPage({required this.preferencias, super.key});
  final PreferenciasFloter preferencias;

  @override
  State<FloterResultadosPage> createState() => _FloterResultadosPageState();
}

class _FloterResultadosPageState extends State<FloterResultadosPage> {
  final FloterService _floterService = FloterService();
  List<SugestaoFloter> _sugestoes = const [];
  bool _analisando = true;
  String? _mensagemErro;

  @override
  void initState() { super.initState(); _analisarPreferencias(); }

  Future<void> _analisarPreferencias() async {
    setState(() { _analisando = true; _mensagemErro = null; });
    try {
      final sugestoesEncontradas = await _floterService.analisarPreferencias(widget.preferencias);
      if (!mounted) return;
      setState(() { _sugestoes = sugestoesEncontradas; _analisando = false; });
    } catch (erro) {
      if (!mounted) return;
      setState(() { _mensagemErro = erro.toString(); _analisando = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Sugestões do Floter')), body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 900), child: _conteudo()))));
  }

  Widget _conteudo() {
    if (_analisando) return const Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(color: AppTheme.accent), SizedBox(height: 18), Text('Analisando suas preferências…', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)), SizedBox(height: 6), Text('Estamos buscando as melhores combinações.', style: TextStyle(color: AppTheme.textSecondary))]);
    if (_mensagemErro != null) return _estadoVazio(Icons.cloud_off_rounded, 'Não foi possível analisar agora', 'Tente novamente em alguns instantes.', 'Tentar novamente', _analisarPreferencias);
    if (_sugestoes.isEmpty) return _estadoVazio(Icons.search_off_rounded, 'Ainda não encontramos a combinação ideal', 'Que tal ajustar uma preferência e tentar novamente?', 'Refazer pesquisa', () => context.go(AppRouter.floter));

    return ListView(padding: const EdgeInsets.all(20), children: [
      Text('${_sugestoes.length} ${_sugestoes.length == 1 ? 'sugestão encontrada' : 'sugestões encontradas'}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
      const SizedBox(height: 6), const Text('Selecionadas de acordo com as suas respostas.', style: TextStyle(color: AppTheme.textSecondary)), const SizedBox(height: 20),
      ..._sugestoes.map(_cartaoSugestao),
      OutlinedButton.icon(onPressed: () => context.go(AppRouter.floter), icon: const Icon(Icons.replay_rounded), label: const Text('Refazer pesquisa')),
    ]);
  }

  Widget _cartaoSugestao(SugestaoFloter sugestao) {
    return Card(margin: const EdgeInsets.only(bottom: 16), clipBehavior: Clip.antiAlias, child: LayoutBuilder(builder: (context, restricoes) {
      final layoutHorizontal = restricoes.maxWidth >= 620;
      final imagem = Image.network(sugestao.imagemUrl, width: layoutHorizontal ? 230 : double.infinity, height: layoutHorizontal ? 190 : 180, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: layoutHorizontal ? 230 : double.infinity, height: layoutHorizontal ? 190 : 180, color: AppTheme.inputFill, child: const Icon(Icons.restaurant_rounded, size: 54, color: AppTheme.textSecondary)));
      final informacoes = Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(sugestao.nome, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)), const SizedBox(height: 4), Text(sugestao.estabelecimento, style: const TextStyle(color: AppTheme.textSecondary)), const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [_etiqueta(Icons.restaurant_menu_rounded, sugestao.categoria.descricao), _etiqueta(Icons.payments_outlined, sugestao.faixaPreco.descricao)]), const SizedBox(height: 14),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Em breve você poderá pedir ${sugestao.nome} por aqui.'))), child: const Text('Visualizar ou pedir'))),
      ]));
      return layoutHorizontal ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [imagem, Expanded(child: informacoes)]) : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [imagem, informacoes]);
    }));
  }

  Widget _etiqueta(IconData icone, String descricao) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: AppTheme.inputFill, borderRadius: BorderRadius.circular(20)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icone, size: 15, color: AppTheme.accent), const SizedBox(width: 6), Text(descricao, style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary))]));

  Widget _estadoVazio(IconData icone, String titulo, String descricao, String textoBotao, VoidCallback aoPressionar) => Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icone, size: 72, color: AppTheme.accent), const SizedBox(height: 20), Text(titulo, textAlign: TextAlign.center, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)), const SizedBox(height: 8), Text(descricao, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondary)), const SizedBox(height: 24), ElevatedButton.icon(onPressed: aoPressionar, icon: const Icon(Icons.replay_rounded), label: Text(textoBotao))]));
}
