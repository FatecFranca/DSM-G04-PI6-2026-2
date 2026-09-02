import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../components/floter_option_card.dart';
import '../models/floter_models.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';

class FloterPage extends StatefulWidget {
  const FloterPage({super.key});

  @override
  State<FloterPage> createState() => _FloterPageState();
}

class _FloterPageState extends State<FloterPage> {
  final PageController _controladorPaginas = PageController();
  final TextEditingController _controladorObservacao = TextEditingController();
  int _etapaAtual = 0;
  CategoriaComida? _categoriaSelecionada;
  PreferenciaSabor? _saborSelecionado;
  FaixaPreco? _faixaPrecoSelecionada;
  QuantidadePessoas? _quantidadePessoasSelecionada;
  RestricaoAlimentar? _restricaoSelecionada;
  ModalidadeConsumo? _modalidadeSelecionada;

  static const int _quantidadeEtapas = 7;

  @override
  void dispose() {
    _controladorPaginas.dispose();
    _controladorObservacao.dispose();
    super.dispose();
  }

  bool get _etapaObrigatoriaRespondida {
    switch (_etapaAtual) {
      case 0: return _categoriaSelecionada != null;
      case 1: return _saborSelecionado != null;
      case 2: return _faixaPrecoSelecionada != null;
      case 3: return _quantidadePessoasSelecionada != null;
      case 4: return _restricaoSelecionada != null;
      case 5: return _modalidadeSelecionada != null;
      default: return true;
    }
  }

  void _avancar() {
    if (!_etapaObrigatoriaRespondida) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione uma opção para continuar.'), backgroundColor: AppTheme.accent));
      return;
    }
    if (_etapaAtual == _quantidadeEtapas - 1) {
      final preferencias = PreferenciasFloter(
        categoria: _categoriaSelecionada!, sabor: _saborSelecionado!, faixaPreco: _faixaPrecoSelecionada!, quantidadePessoas: _quantidadePessoasSelecionada!, restricaoAlimentar: _restricaoSelecionada!, modalidadeConsumo: _modalidadeSelecionada!, observacao: _controladorObservacao.text.trim().isEmpty ? null : _controladorObservacao.text.trim(),
      );
      context.push(AppRouter.floterResultados, extra: preferencias);
      return;
    }
    setState(() => _etapaAtual++);
    _controladorPaginas.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
  }

  void _voltar() {
    if (_etapaAtual == 0) {
      context.pop();
      return;
    }
    setState(() => _etapaAtual--);
    _controladorPaginas.previousPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Floter'), leading: IconButton(onPressed: _voltar, icon: const Icon(Icons.arrow_back_rounded))),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(children: [
                Row(children: [Expanded(child: LinearProgressIndicator(value: (_etapaAtual + 1) / _quantidadeEtapas, minHeight: 7, borderRadius: BorderRadius.circular(8), color: AppTheme.accent, backgroundColor: AppTheme.inputFill)), const SizedBox(width: 12), Text('${_etapaAtual + 1}/$_quantidadeEtapas', style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600))]),
                const SizedBox(height: 24),
                Expanded(child: PageView(controller: _controladorPaginas, physics: const NeverScrollableScrollPhysics(), children: [
                  _paginaDeOpcoes('O que você está com vontade de comer?', 'Escolha a opção que mais combina com o momento.', CategoriaComida.values, _categoriaSelecionada, (opcao) => setState(() => _categoriaSelecionada = opcao), (opcao) => opcao.descricao),
                  _paginaDeOpcoes('Qual tipo de sabor você prefere?', 'Vamos refinar sua experiência.', PreferenciaSabor.values, _saborSelecionado, (opcao) => setState(() => _saborSelecionado = opcao), (opcao) => opcao.descricao),
                  _paginaDeOpcoes('Qual faixa de preço você deseja pagar?', 'Selecione o valor que cabe no seu momento.', FaixaPreco.values, _faixaPrecoSelecionada, (opcao) => setState(() => _faixaPrecoSelecionada = opcao), (opcao) => opcao.descricao),
                  _paginaDeOpcoes('Para quantas pessoas é o pedido?', 'Assim encontramos porções adequadas.', QuantidadePessoas.values, _quantidadePessoasSelecionada, (opcao) => setState(() => _quantidadePessoasSelecionada = opcao), (opcao) => opcao.descricao),
                  _paginaDeOpcoes('Você possui alguma restrição alimentar?', 'Sua segurança e preferência vêm primeiro.', RestricaoAlimentar.values, _restricaoSelecionada, (opcao) => setState(() => _restricaoSelecionada = opcao), (opcao) => opcao.descricao),
                  _paginaDeOpcoes('Como você deseja receber seu pedido?', 'Escolha a modalidade mais conveniente.', ModalidadeConsumo.values, _modalidadeSelecionada, (opcao) => setState(() => _modalidadeSelecionada = opcao), (opcao) => opcao.descricao),
                  _paginaObservacao(),
                ])),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _voltar,
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: const Text('Voltar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: AppTheme.textSecondary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _avancar,
                        icon: Icon(
                          _etapaAtual == _quantidadeEtapas - 1
                              ? Icons.auto_awesome_rounded
                              : Icons.arrow_forward_rounded,
                        ),
                        label: Text(
                          _etapaAtual == _quantidadeEtapas - 1
                              ? 'Encontrar sugestões'
                              : 'Continuar',
                        ),
                      ),
                    ),
                  ],
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _paginaDeOpcoes<T>(String titulo, String subtitulo, List<T> opcoes, T? opcaoSelecionada, ValueChanged<T> aoSelecionar, String Function(T) obterDescricao) {
    return SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(titulo, style: const TextStyle(fontSize: 24, height: 1.2, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
      const SizedBox(height: 8), Text(subtitulo, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)), const SizedBox(height: 24),
      ...opcoes.map((opcao) => Padding(padding: const EdgeInsets.only(bottom: 10), child: FloterOptionCard(label: obterDescricao(opcao), selected: opcao == opcaoSelecionada, onTap: () => aoSelecionar(opcao)))),
    ]));
  }

  Widget _paginaObservacao() {
    return SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Conte mais sobre o que você gostaria de comer', style: TextStyle(fontSize: 24, height: 1.2, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
      const SizedBox(height: 8), const Text('Este campo é opcional. Use-o para contar algum detalhe especial.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)), const SizedBox(height: 24),
      TextField(controller: _controladorObservacao, minLines: 5, maxLines: 8, maxLength: 300, decoration: const InputDecoration(hintText: 'Ex.: algo quentinho, pouco temperado e que seja fácil de compartilhar…', alignLabelWithHint: true)),
    ]));
  }
}
