import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../components/floter_option_card.dart';
import '../models/floter_models.dart';
import '../router/app_router.dart';
import '../services/api.dart';
import '../theme/app_theme.dart';

class FloterPage extends StatefulWidget {
  const FloterPage({this.api, super.key});
  final ApiService? api;

  @override
  /// Cria o estado que guardara respostas e etapa atual do questionario.
  State<FloterPage> createState() => _FloterPageState();
}

class _FloterPageState extends State<FloterPage> {
  late final ApiService _api = widget.api ?? ApiService();
  final PageController _controladorPaginas = PageController();
  final TextEditingController _controladorObservacao = TextEditingController();
  int _etapaAtual = 0;
  bool _salvando = false;
  bool _carregandoPreferencias = true;
  @override
  void initState() {
    super.initState();
    _restaurarPreferencias();
  }

  Future<void> _restaurarPreferencias() async {
    try {
      final preferencias = await _api.getPreferencias();
      if (!mounted || preferencias == null) return;
      setState(() {
        _categoriaSelecionada = CategoriaComida.values
            .where((v) => v.descricao == preferencias['categoria'])
            .firstOrNull;
        _saborSelecionado = PreferenciaSabor.values
            .where((v) => v.descricao == preferencias['sabor'])
            .firstOrNull;
        _faixaPrecoSelecionada = FaixaPreco.values
            .where((v) => v.descricao == preferencias['faixa_preco'])
            .firstOrNull;
        _quantidadePessoasSelecionada = QuantidadePessoas.values
            .where((v) => v.descricao == preferencias['quantidade_pessoas'])
            .firstOrNull;
        _restricaoSelecionada = RestricaoAlimentar.values
            .where((v) => v.descricao == preferencias['restricao_alimentar'])
            .firstOrNull;
        _modalidadeSelecionada = ModalidadeConsumo.values
            .where((v) => v.descricao == preferencias['modalidade_consumo'])
            .firstOrNull;
        _controladorObservacao.text =
            preferencias['observacao']?.toString() ?? '';
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível recuperar as preferências anteriores. Você pode preencher novamente.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _carregandoPreferencias = false);
    }
  }

  CategoriaComida? _categoriaSelecionada;
  PreferenciaSabor? _saborSelecionado;
  FaixaPreco? _faixaPrecoSelecionada;
  QuantidadePessoas? _quantidadePessoasSelecionada;
  RestricaoAlimentar? _restricaoSelecionada;
  ModalidadeConsumo? _modalidadeSelecionada;

  static const int _quantidadeEtapas = 7;

  @override
  /// Libera os controllers quando o questionario deixa de existir.
  void dispose() {
    _controladorPaginas.dispose();
    _controladorObservacao.dispose();
    super.dispose();
  }

  /// Retorna se a pergunta obrigatoria da etapa atual ja foi respondida.
  bool get _etapaObrigatoriaRespondida {
    switch (_etapaAtual) {
      case 0:
        return _categoriaSelecionada != null;
      case 1:
        return _saborSelecionado != null;
      case 2:
        return _faixaPrecoSelecionada != null;
      case 3:
        return _quantidadePessoasSelecionada != null;
      case 4:
        return _restricaoSelecionada != null;
      case 5:
        return _modalidadeSelecionada != null;
      default:
        return true;
    }
  }

  /// Avanca uma etapa ou salva tudo e navega aos resultados na ultima etapa.
  Future<void> _avancar() async {
    if (_salvando) return;
    if (!_etapaObrigatoriaRespondida) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione uma opção para continuar.'),
          backgroundColor: AppTheme.accent,
        ),
      );
      return;
    }
    if (_etapaAtual == _quantidadeEtapas - 1) {
      final preferencias = PreferenciasFloter(
        categoria: _categoriaSelecionada!,
        sabor: _saborSelecionado!,
        faixaPreco: _faixaPrecoSelecionada!,
        quantidadePessoas: _quantidadePessoasSelecionada!,
        restricaoAlimentar: _restricaoSelecionada!,
        modalidadeConsumo: _modalidadeSelecionada!,
        observacao: _controladorObservacao.text.trim().isEmpty
            ? null
            : _controladorObservacao.text.trim(),
      );
      setState(() => _salvando = true);
      try {
        await _api.savePreferencias({
          'categoria': preferencias.categoria.descricao,
          'sabor': preferencias.sabor.descricao,
          'faixa_preco': preferencias.faixaPreco.descricao,
          'quantidade_pessoas': preferencias.quantidadePessoas.descricao,
          'restricao_alimentar': preferencias.restricaoAlimentar.descricao,
          'modalidade_consumo': preferencias.modalidadeConsumo.descricao,
          if (preferencias.observacao != null)
            'observacao': preferencias.observacao,
        });
      } catch (error) {
        if (!mounted) return;
        setState(() => _salvando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Não foi possível salvar suas preferências: $error'),
          ),
        );
        return;
      }
      if (!mounted) return;
      setState(() => _salvando = false);
      context.go(AppRouter.floterResultados, extra: preferencias);
      return;
    }
    setState(() => _etapaAtual++);
    _controladorPaginas.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  /// Volta uma etapa sem apagar as preferencias ja informadas.
  void _voltar() {
    if (_etapaAtual == 0) {
      context.go(AppRouter.sugestoes);
      return;
    }
    setState(() => _etapaAtual--);
    _controladorPaginas.previousPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  /// Monta progresso, pergunta atual e botoes para avancar ou voltar.
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Floter'),
        leading: IconButton(
          onPressed: _salvando ? null : _voltar,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: _carregandoPreferencias
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: LinearProgressIndicator(
                                value: (_etapaAtual + 1) / _quantidadeEtapas,
                                minHeight: 7,
                                borderRadius: BorderRadius.circular(8),
                                color: AppTheme.accent,
                                backgroundColor: AppTheme.inputFill,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${_etapaAtual + 1}/$_quantidadeEtapas',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: PageView(
                            controller: _controladorPaginas,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              _paginaDeOpcoes(
                                'O que você está com vontade de comer?',
                                'Escolha a opção que mais combina com o momento.',
                                CategoriaComida.values,
                                _categoriaSelecionada,
                                (opcao) => setState(
                                  () => _categoriaSelecionada = opcao,
                                ),
                                (opcao) => opcao.descricao,
                              ),
                              _paginaDeOpcoes(
                                'Qual tipo de sabor você prefere?',
                                'Vamos refinar sua experiência.',
                                PreferenciaSabor.values,
                                _saborSelecionado,
                                (opcao) =>
                                    setState(() => _saborSelecionado = opcao),
                                (opcao) => opcao.descricao,
                              ),
                              _paginaDeOpcoes(
                                'Qual faixa de preço você deseja pagar?',
                                'Selecione o valor que cabe no seu momento.',
                                FaixaPreco.values,
                                _faixaPrecoSelecionada,
                                (opcao) => setState(
                                  () => _faixaPrecoSelecionada = opcao,
                                ),
                                (opcao) => opcao.descricao,
                              ),
                              _paginaDeOpcoes(
                                'Quantas pessoas vão com você?',
                                'Assim encontramos porções adequadas.',
                                QuantidadePessoas.values,
                                _quantidadePessoasSelecionada,
                                (opcao) => setState(
                                  () => _quantidadePessoasSelecionada = opcao,
                                ),
                                (opcao) => opcao.descricao,
                              ),
                              _paginaDeOpcoes(
                                'Você possui alguma restrição alimentar?',
                                'Sua segurança e preferência vêm primeiro.',
                                RestricaoAlimentar.values,
                                _restricaoSelecionada,
                                (opcao) => setState(
                                  () => _restricaoSelecionada = opcao,
                                ),
                                (opcao) => opcao.descricao,
                              ),
                              _paginaDeOpcoes(
                                'Como você pretende consumir?',
                                'Escolha a modalidade mais conveniente.',
                                ModalidadeConsumo.values,
                                _modalidadeSelecionada,
                                (opcao) => setState(
                                  () => _modalidadeSelecionada = opcao,
                                ),
                                (opcao) => opcao.descricao,
                              ),
                              _paginaObservacao(),
                            ],
                          ),
                        ),
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
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  side: const BorderSide(
                                    color: AppTheme.textSecondary,
                                  ),
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
                                onPressed: _salvando ? null : _avancar,
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
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _paginaDeOpcoes<T>(
    String titulo,
    String subtitulo,
    List<T> opcoes,
    T? opcaoSelecionada,
    ValueChanged<T> aoSelecionar,
    String Function(T) obterDescricao,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 24,
              height: 1.2,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitulo,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ...opcoes.map(
            (opcao) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FloterOptionCard(
                label: obterDescricao(opcao),
                selected: opcao == opcaoSelecionada,
                onTap: () => aoSelecionar(opcao),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Cria o campo livre de observacao mostrado na etapa final.
  Widget _paginaObservacao() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Conte mais sobre o que você gostaria de comer',
            style: TextStyle(
              fontSize: 24,
              height: 1.2,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Este campo é opcional. Use-o para contar algum detalhe especial.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _controladorObservacao,
            maxLength: 500,
            minLines: 5,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText:
                  'Ex.: algo quentinho, pouco temperado e que seja fácil de compartilhar…',
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }
}
// Coleta as preferencias que serao usadas para buscar resultados no Floter.
