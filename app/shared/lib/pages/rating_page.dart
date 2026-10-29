import '../components/app_scaffold.dart';
import '../components/app_bottom_nav.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router/app_router.dart';
import '../services/api.dart';
import '../theme/app_theme.dart';

class RatingPage extends StatefulWidget {
  const RatingPage({super.key});

  @override
  /// Cria o estado que controla pesquisa, selecao, nota e comentario.
  State<RatingPage> createState() => _RatingPageState();
}

class _RatingPageState extends State<RatingPage> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _api = ApiService();

  List<Map<String, dynamic>> _estabelecimentos = [];
  List<Map<String, dynamic>> _filtered = [];
  Map<String, dynamic>? _selected;

  bool _loadingList = true;
  String? _loadError;
  Timer? _debounce;

  double _avaliacao = 0;
  bool _isSubmitting = false;

  @override
  /// Inicia a consulta de locais e registra o observador do campo de busca.
  void initState() {
    super.initState();
    _fetchEstabelecimentos();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  /// Libera os campos e remove o observador quando a pagina fecha.
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  /// Busca os estabelecimentos na API e atualiza a lista ou a mensagem de erro.
  /// Busca os estabelecimentos na API e atualiza a lista ou a mensagem de erro.
  Future<void> _fetchEstabelecimentos() async {
    setState(() {
      _loadingList = true;
      _loadError = null;
    });
    try {
      final list = await _api.listEstabelecimentos();
      if (!mounted) return;
      list.sort(
        (a, b) => (a['nome'] ?? '').toString().compareTo(
          (b['nome'] ?? '').toString(),
        ),
      );
      setState(() {
        _estabelecimentos = list;
        _filtered = list;
        _loadingList = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _loadingList = false;
      });
    }
  }

  /// Filtra localmente os estabelecimentos quando o texto pesquisado muda.
  /// Filtra localmente os estabelecimentos quando o texto pesquisado muda.
  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 180), () {
      final q = _searchController.text.trim().toLowerCase();
      setState(() {
        if (q.isEmpty) {
          _filtered = _estabelecimentos;
        } else {
          _filtered = _estabelecimentos.where((e) {
            final nome = (e['nome'] ?? '').toString().toLowerCase();
            final tipo = (e['tipo'] ?? '').toString().toLowerCase();
            final bairro = (e['bairro'] ?? '').toString().toLowerCase();
            final cidade = (e['cidade'] ?? '').toString().toLowerCase();
            return nome.contains(q) ||
                tipo.contains(q) ||
                bairro.contains(q) ||
                cidade.contains(q);
          }).toList();
        }
      });
    });
  }

  /// Guarda o estabelecimento escolhido e esconde os demais resultados.
  /// Guarda o estabelecimento escolhido e esconde os demais resultados.
  void _selectEstabelecimento(Map<String, dynamic> item) {
    setState(() {
      _selected = item;
      _searchController.text = (item['nome'] ?? '').toString();
    });
    FocusScope.of(context).unfocus();
  }

  /// Remove a selecao atual e reinicia os dados da avaliacao.
  /// Remove a selecao atual e reinicia os dados da avaliacao.
  void _clearSelection() {
    setState(() {
      _selected = null;
      _searchController.clear();
      _filtered = _estabelecimentos;
      _avaliacao = 0;
    });
  }

  /// Valida a escolha e a nota, envia a avaliacao e informa sucesso ou falha.
  /// Valida a escolha e a nota, envia a avaliacao e informa sucesso ou falha.
  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;
    if (_selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pesquise e selecione um estabelecimento.'),
          backgroundColor: AppTheme.accent,
        ),
      );
      return;
    }
    if (_avaliacao == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, dê uma avaliação'),
          backgroundColor: AppTheme.accent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final idEstabelecimento = (_selected!['id_estabelecimento'] as num)
          .toInt();

      // Registra a nota como rating para histórico
      await _api.createInteracao(
        idEstabelecimento: idEstabelecimento,
        tipoEvento: 'rating',
        valor: _avaliacao,
        origem: 'app-flutter',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Avaliação salva! Suas sugestões serão atualizadas automaticamente.',
          ),
          backgroundColor: Colors.green,
        ),
      );
      context.go(AppRouter.sugestoes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao enviar avaliação: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  /// Monta todas as secoes da avaliacao e a navegacao inferior.
  Widget build(BuildContext context) {
    return AppScaffold(
      indice: 1,
      appBar: AppBar(title: const Text('Nova Avaliação')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionTitle('Pesquisar Estabelecimento'),
                const SizedBox(height: 12),
                _buildSearchField(),
                const SizedBox(height: 12),
                _buildSearchResults(),
                const SizedBox(height: 24),
                _buildSectionTitle('Informações do Local'),
                const SizedBox(height: 12),
                _buildSelectedInfo(),
                const SizedBox(height: 28),
                _buildSectionTitle('Sua Avaliação'),
                const SizedBox(height: 16),
                _buildStarRating(),
                const SizedBox(height: 28),
                _buildSectionTitle('Funcionamento'),
                const SizedBox(height: 12),
                _buildFuncionamento(),
                const SizedBox(height: 32),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(
                      _isSubmitting ? 'Enviando...' : 'Enviar Avaliação',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, 1),
    );
  }

  /// Monta o campo de texto usado para localizar estabelecimentos.
  /// Monta o campo de texto usado para localizar estabelecimentos.
  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: 'Buscar pelo nome, tipo, bairro...',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: _clearSelection,
              ),
      ),
    );
  }

  /// Mostra progresso, erro, lista vazia ou os locais que combinam com a busca.
  /// Mostra progresso, erro, lista vazia ou os locais que combinam com a busca.
  Widget _buildSearchResults() {
    if (_loadingList) {
      return _infoBox(
        const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: CircularProgressIndicator(color: AppTheme.accent),
          ),
        ),
      );
    }
    if (_loadError != null) {
      return _infoBox(
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Não foi possível carregar a lista.',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _loadError!,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _fetchEstabelecimentos,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (_selected != null) {
      // Quando selecionado, esconde a lista para focar nos detalhes
      return const SizedBox.shrink();
    }

    final query = _searchController.text.trim();
    if (query.isEmpty) {
      return _infoBox(
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Digite o nome do lugar onde você foi para selecionar.',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      );
    }
    if (_filtered.isEmpty) {
      return _infoBox(
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Nenhum estabelecimento encontrado para "$query".',
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      );
    }

    final results = _filtered.take(15).toList();
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.secondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: results.length,
        separatorBuilder: (_, _) => Divider(
          color: AppTheme.inputFill.withValues(alpha: 0.4),
          height: 1,
        ),
        itemBuilder: (context, index) {
          final item = results[index];
          final nome = (item['nome'] ?? '').toString();
          final tipo = (item['tipo'] ?? '').toString();
          final faixa = (item['faixa_preco'] ?? '').toString();
          final ambiente = (item['ambiente'] ?? '').toString();
          return ListTile(
            title: Text(
              nome,
              style: const TextStyle(color: AppTheme.textPrimary),
            ),
            subtitle: Text(
              [tipo, faixa, ambiente].where((s) => s.isNotEmpty).join(' • '),
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.accent,
            ),
            onTap: () => _selectEstabelecimento(item),
          );
        },
      ),
    );
  }

  /// Apresenta nome, categoria, preco e demais dados do local selecionado.
  /// Apresenta nome, categoria, preco e demais dados do local selecionado.
  Widget _buildSelectedInfo() {
    if (_selected == null) {
      return _infoBox(
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Selecione um estabelecimento acima para ver os detalhes.',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      );
    }

    final s = _selected!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.secondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.place_rounded, color: AppTheme.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  (s['nome'] ?? '').toString(),
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _clearSelection,
                icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                label: const Text('Trocar'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow(Icons.store_outlined, 'Tipo', (s['tipo'] ?? '-').toString()),
          _infoRow(
            Icons.attach_money_rounded,
            'Faixa de preço',
            (s['faixa_preco'] ?? '-').toString(),
          ),
          _infoRow(
            Icons.chair_outlined,
            'Ambiente',
            (s['ambiente'] ?? '-').toString(),
          ),
          _infoRow(
            Icons.groups_outlined,
            'Público',
            (s['publico'] ?? '-').toString(),
          ),
          _infoRow(
            Icons.star_rounded,
            'Avaliação pública',
            _formatNumber(s['avaliacao']),
          ),
          if ((s['cidade'] ?? '').toString().isNotEmpty)
            _infoRow(
              Icons.location_city_rounded,
              'Cidade',
              (s['cidade'] ?? '-').toString(),
            ),
        ],
      ),
    );
  }

  /// Monta a secao com horarios de abertura e fechamento.
  /// Monta a secao com horarios de abertura e fechamento.
  Widget _buildFuncionamento() {
    final abre = (_selected?['abre'] ?? '-').toString();
    final fecha = (_selected?['fecha'] ?? '-').toString();
    return Row(
      children: [
        Expanded(
          child: _funcionamentoCard(Icons.schedule_outlined, 'Abre às', abre),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _funcionamentoCard(Icons.schedule_rounded, 'Fecha às', fecha),
        ),
      ],
    );
  }

  /// Cria um cartao compacto contendo um dos horarios do estabelecimento.
  /// Cria um cartao compacto contendo um dos horarios do estabelecimento.
  Widget _funcionamentoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.inputFill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Padroniza uma linha de informacao com icone, rotulo e valor.
  /// Padroniza uma linha de informacao com icone, rotulo e valor.
  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textSecondary, size: 18),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Aplica o recipiente visual padrao ao widget recebido.
  /// Aplica o recipiente visual padrao ao widget recebido.
  Widget _infoBox(Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.secondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  /// Cria o titulo visual que separa uma secao do formulario.
  /// Cria o titulo visual que separa uma secao do formulario.
  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: AppTheme.accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  /// Cria as estrelas interativas e a descricao correspondente a nota.
  /// Cria as estrelas interativas e a descricao correspondente a nota.
  Widget _buildStarRating() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.secondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _avaliacao > 0
              ? AppTheme.accent.withValues(alpha: 0.4)
              : Colors.transparent,
        ),
      ),
      child: Column(
        children: [
          Text(
            _avaliacao == 0
                ? 'Toque para avaliar'
                : _getAvaliacaoLabel(_avaliacao),
            style: TextStyle(
              color: _avaliacao > 0 ? AppTheme.accent : AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starValue = (index + 1).toDouble();
              return GestureDetector(
                onTap: () => setState(() => _avaliacao = starValue),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    index < _avaliacao
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: index < _avaliacao
                        ? Colors.amber
                        : AppTheme.textSecondary,
                    size: 40,
                  ),
                ),
              );
            }),
          ),
          if (_avaliacao > 0) ...[
            const SizedBox(height: 8),
            Text(
              '$_avaliacao / 5',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Traduz uma nota numerica em uma descricao facil de entender.
  /// Traduz uma nota numerica em uma descricao facil de entender.
  String _getAvaliacaoLabel(double avaliacao) {
    switch (avaliacao.toInt()) {
      case 1:
        return 'Péssimo 😞';
      case 2:
        return 'Ruim 😕';
      case 3:
        return 'Regular 😐';
      case 4:
        return 'Bom 😊';
      case 5:
        return 'Excelente! 🤩';
      default:
        return '';
    }
  }

  /// Converte valores numericos de tipos variados em texto para exibicao.
  /// Converte valores numericos de tipos variados em texto para exibicao.
  String _formatNumber(dynamic value) {
    if (value == null) return '-';
    if (value is num) return value.toStringAsFixed(1);
    final asDouble = double.tryParse(value.toString());
    return asDouble == null ? value.toString() : asDouble.toStringAsFixed(1);
  }

  /// Cria a barra inferior e navega quando o usuario escolhe outra area.
  /// Cria a barra inferior e navega quando o usuario escolhe outra area.
  Widget _buildBottomNav(BuildContext context, int currentIndex) =>
      AppBottomNav(indice: currentIndex);
}
// Tela de avaliacao dos estabelecimentos. O estado acompanha notas e comentarios.
