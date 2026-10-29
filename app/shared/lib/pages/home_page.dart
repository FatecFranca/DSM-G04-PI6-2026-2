import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../components/cadastro_estabelecimento_dialog.dart';
import 'package:go_router/go_router.dart';
import '../components/app_bottom_nav.dart';
import '../components/app_scaffold.dart';
import '../components/notificacoes_button.dart';
import '../components/sugestoes_automaticas.dart';
import '../components/estado_conteudo.dart';
import '../services/api.dart';
import '../theme/app_theme.dart';

/// Home do catalogo. Todos os estabelecimentos e notas vem da API.
class HomePage extends StatefulWidget {
  const HomePage({this.api, super.key});
  final ApiService? api;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final ApiService _api = widget.api ?? ApiService();
  final _busca = TextEditingController();
  final _rolagem = ScrollController();
  List<Map<String, dynamic>> _locais = [];
  bool _carregando = true;
  bool _personalizadas = false;
  String? _erro;
  String? _categoria;
  String _ordenacao = 'catalogo';
  int _versao = 0;
  int _pagina = 0;
  static const _porPagina = 12;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _busca.dispose();
    _rolagem.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    final versao = ++_versao;
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final lista = _personalizadas
          ? await _api.getRecomendacoes(limit: 50, forceRefresh: true)
          : await _api.listEstabelecimentos();
      if (!mounted || versao != _versao) return;
      setState(() {
        _locais = lista.where((local) => local['ativo'] != false).toList();
        _pagina = 0;
        if (_categoria != null &&
            !_locais.any((local) => local['tipo'] == _categoria)) {
          _categoria = null;
        }
        _carregando = false;
      });
    } catch (erro) {
      if (!mounted || versao != _versao) return;
      setState(() {
        _erro = '$erro';
        _carregando = false;
      });
    }
  }

  static String _normalizar(Object? valor) {
    var texto = (valor ?? '').toString().toLowerCase();
    const grupos = {
      'áàâãä': 'a',
      'éèêë': 'e',
      'íìîï': 'i',
      'óòôõö': 'o',
      'úùûü': 'u',
      'ç': 'c',
    };
    for (final grupo in grupos.entries) {
      texto = texto.replaceAll(RegExp('[${grupo.key}]'), grupo.value);
    }
    return texto;
  }

  static String _rotulo(String texto) => texto.isEmpty
      ? 'Restaurante'
      : texto[0].toUpperCase() + texto.substring(1);
  static double? _nota(Map<String, dynamic> local) =>
      double.tryParse('${local['avaliacao'] ?? ''}'.replaceAll(',', '.'));
  static IconData _icone(String tipo) {
    final texto = _normalizar(tipo);
    if (texto.contains('pizza')) return Icons.local_pizza_outlined;
    if (texto.contains('burg') || texto.contains('lanche')) {
      return Icons.lunch_dining_outlined;
    }
    if (texto.contains('cafe') || texto.contains('cafeter')) {
      return Icons.coffee_outlined;
    }
    if (texto.contains('japon') || texto.contains('sushi')) {
      return Icons.ramen_dining_outlined;
    }
    if (texto.contains('bar')) return Icons.local_bar_outlined;
    if (texto.contains('doce') || texto.contains('sorvet')) {
      return Icons.icecream_outlined;
    }
    return Icons.restaurant_outlined;
  }

  Future<void> _abrir(Map<String, dynamic> local) async {
    final id = local['id_estabelecimento'];
    if (id is! num) return;
    await context.push('/estabelecimentos/${id.toInt()}');
    if (mounted) await _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final menuLateral = AppScaffold.usaMenuLateral(context);
    final termo = _normalizar(_busca.text.trim());
    final categorias =
        _locais
            .map((local) => '${local['tipo'] ?? ''}')
            .where((tipo) => tipo.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final encontrados = _locais
        .where(
          (local) =>
              (_categoria == null || local['tipo'] == _categoria) &&
              [
                'nome',
                'tipo',
                'cidade',
                'bairro',
              ].any((campo) => _normalizar(local[campo]).contains(termo)),
        )
        .toList();
    if (_ordenacao == 'nota') {
      encontrados.sort((a, b) => (_nota(b) ?? -1).compareTo(_nota(a) ?? -1));
    } else if (_ordenacao == 'nome') {
      encontrados.sort(
        (a, b) => _normalizar(a['nome']).compareTo(_normalizar(b['nome'])),
      );
    }
    final totalPaginas = (encontrados.length / _porPagina).ceil();
    final visiveis = encontrados
        .skip(_pagina * _porPagina)
        .take(_porPagina)
        .toList();
    return AppScaffold(
      indice: 0,
      sidebarContent: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ListTile(title: Text('Explorar')),
          for (final personalizadas in [false, true])
            ListTile(
              leading: Icon(
                personalizadas
                    ? Icons.auto_awesome_outlined
                    : Icons.restaurant_outlined,
              ),
              title: Text(
                personalizadas ? 'Para você' : 'Todos os restaurantes',
              ),
              selected: _personalizadas == personalizadas,
              selectedColor: AppTheme.accent,
              onTap: () => _trocarLista(personalizadas),
            ),
          const Divider(),
          const ListTile(title: Text('Categorias')),
          for (final tipo in <String?>[null, ...categorias])
            ListTile(
              leading: Icon(tipo == null ? Icons.apps : _icone(tipo)),
              title: Text(tipo == null ? 'Todas as categorias' : _rotulo(tipo)),
              selected: _categoria == tipo,
              selectedColor: AppTheme.accent,
              selectedTileColor: AppTheme.accent.withValues(alpha: .12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onTap: () => setState(() {
                _categoria = tipo;
                _pagina = 0;
              }),
            ),
        ],
      ),
      appBar: AppBar(
        centerTitle: !menuLateral,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.restaurant_menu, color: AppTheme.accent),
            SizedBox(width: 8),
            Flexible(child: Text('BoraLá', overflow: TextOverflow.ellipsis)),
          ],
        ),
        actions: [
          if (menuLateral)
            TextButton.icon(
              onPressed: _cadastrar,
              icon: const Icon(Icons.add_business_outlined),
              label: const Text('Cadastrar estabelecimento'),
            )
          else
            IconButton(
              onPressed: _cadastrar,
              tooltip: 'Cadastrar estabelecimento',
              icon: const Icon(Icons.add_business_outlined),
            ),
          NotificacoesButton(api: _api),
          IconButton(
            tooltip: 'Atualizar restaurantes',
            onPressed: _carregando ? null : _carregar,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Meu perfil',
            onPressed: () => context.go('/user'),
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(indice: 0),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: menuLateral ? 1600 : 1440),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _carregar,
                    child: CustomScrollView(
                      controller: _rolagem,
                      physics: const AlwaysScrollableScrollPhysics(),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _boasVindas(),
                                const SizedBox(height: 20),
                                if (_erro == null && !_carregando)
                                  SugestoesAutomaticas(api: _api),
                                TextField(
                                  controller: _busca,
                                  onChanged: (_) => setState(() => _pagina = 0),
                                  decoration: InputDecoration(
                                    hintText:
                                        'Buscar restaurante, comida ou bairro',
                                    prefixIcon: const Icon(Icons.search),
                                    suffixIcon: _busca.text.isEmpty
                                        ? null
                                        : IconButton(
                                            tooltip: 'Limpar busca',
                                            onPressed: () {
                                              _busca.clear();
                                              setState(() => _pagina = 0);
                                            },
                                            icon: const Icon(Icons.close),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                if (!menuLateral)
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 6,
                                    children: [
                                      ChoiceChip(
                                        label: const Text(
                                          'Todos os restaurantes',
                                        ),
                                        selected: !_personalizadas,
                                        onSelected: (_) => _trocarLista(false),
                                      ),
                                      ChoiceChip(
                                        label: const Text('Para você'),
                                        selected: _personalizadas,
                                        onSelected: (_) => _trocarLista(true),
                                      ),
                                    ],
                                  ),
                                if (!menuLateral && categorias.isNotEmpty) ...[
                                  const SizedBox(height: 18),
                                  if (kIsWeb)
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        for (final tipo in <String?>[
                                          null,
                                          ...categorias,
                                        ])
                                          _filtroCategoria(tipo),
                                      ],
                                    )
                                  else
                                    SizedBox(
                                      height: 46,
                                      child: ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: categorias.length + 1,
                                        separatorBuilder: (_, _) =>
                                            const SizedBox(width: 8),
                                        itemBuilder: (_, indice) {
                                          final tipo = indice == 0
                                              ? null
                                              : categorias[indice - 1];
                                          return ChoiceChip(
                                            avatar: Icon(
                                              tipo == null
                                                  ? Icons.apps
                                                  : _icone(tipo),
                                              size: 18,
                                            ),
                                            label: Text(
                                              tipo == null
                                                  ? 'Todas as categorias'
                                                  : _rotulo(tipo),
                                            ),
                                            selected: _categoria == tipo,
                                            onSelected: (_) => setState(() {
                                              _categoria = tipo;
                                              _pagina = 0;
                                            }),
                                          );
                                        },
                                      ),
                                    ),
                                ],
                                const SizedBox(height: 22),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _personalizadas
                                                ? 'Escolhidos para você'
                                                : 'Restaurantes para descobrir',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            _carregando
                                                ? 'Buscando novos sabores…'
                                                : encontrados.length
                                                          .toString() +
                                                      (encontrados.length == 1
                                                          ? ' local disponível'
                                                          : ' locais disponíveis'),
                                            style: const TextStyle(
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      tooltip: 'Ordenar restaurantes',
                                      icon: const Icon(Icons.sort),
                                      initialValue: _ordenacao,
                                      onSelected: (valor) => setState(() {
                                        _ordenacao = valor;
                                        _pagina = 0;
                                      }),
                                      itemBuilder: (_) => const [
                                        PopupMenuItem(
                                          value: 'catalogo',
                                          child: Text('Ordem do catálogo'),
                                        ),
                                        PopupMenuItem(
                                          value: 'nota',
                                          child: Text('Melhor avaliação'),
                                        ),
                                        PopupMenuItem(
                                          value: 'nome',
                                          child: Text('Nome: A–Z'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                              ],
                            ),
                          ),
                        ),
                        if (_carregando)
                          const SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: CircularProgressIndicator(),
                              ),
                            ),
                          )
                        else if (_erro != null)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: EstadoConteudo(
                              titulo:
                                  'Não foi possível carregar os restaurantes',
                              descricao: _erro!,
                              icone: Icons.cloud_off,
                              acao: _carregar,
                            ),
                          )
                        else if (encontrados.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: EstadoConteudo(
                              titulo: 'Nenhum restaurante encontrado',
                              descricao: termo.isNotEmpty || _categoria != null
                                  ? 'Experimente outra busca ou categoria.'
                                  : 'Ainda não há locais nesta seleção. Explore o catálogo completo.',
                              acao: () {
                                _busca.clear();
                                setState(() {
                                  _categoria = null;
                                });
                                _trocarLista(false);
                              },
                              textoAcao: 'Ver todos os restaurantes',
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                            sliver: SliverLayoutBuilder(
                              builder: (context, dimensoes) => SliverGrid(
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount:
                                          (dimensoes.crossAxisExtent / 310)
                                              .floor()
                                              .clamp(1, 4),
                                      crossAxisSpacing: 18,
                                      mainAxisSpacing: 18,
                                      mainAxisExtent: 324,
                                    ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, indice) =>
                                      _cartao(visiveis[indice]),
                                  childCount: visiveis.length,
                                ),
                              ),
                            ),
                          ),
                        if (!_carregando &&
                            _erro == null &&
                            encontrados.isNotEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                              child: _paginacao(
                                totalPaginas,
                                encontrados.length,
                                visiveis.length,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _cadastrar() async {
    final cadastrado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CadastroEstabelecimentoDialog(api: _api),
    );
    if (cadastrado != true || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Estabelecimento cadastrado!')),
    );
    setState(() {
      _personalizadas = false;
      _categoria = null;
      _busca.clear();
      _pagina = 0;
    });
    await _carregar();
  }

  Widget _paginacao(int totalPaginas, int totalLocais, int quantidade) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final janela = constraints.maxWidth < 480 ? 3 : 5;
        final inicio = (_pagina - janela ~/ 2).clamp(
          0,
          (totalPaginas - janela).clamp(0, totalPaginas),
        );
        final fim = (inicio + janela).clamp(0, totalPaginas);

        Widget botao(
          Widget conteudo,
          String rotulo,
          VoidCallback? acao, {
          bool selecionado = false,
        }) => Semantics(
          selected: selecionado,
          child: SizedBox(
            width: 44,
            height: 44,
            child: IconButton(
              tooltip: rotulo,
              onPressed: acao,
              style: IconButton.styleFrom(
                backgroundColor: selecionado
                    ? AppTheme.accent
                    : AppTheme.background,
                foregroundColor: AppTheme.textPrimary,
                disabledForegroundColor: AppTheme.textSecondary.withValues(
                  alpha: .35,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                side: BorderSide(color: Colors.white.withValues(alpha: .08)),
              ),
              icon: conteudo,
            ),
          ),
        );

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.secondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: .08)),
          ),
          child: Column(
            children: [
              Text(
                'Página ${_pagina + 1} de $totalPaginas',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Exibindo ${_pagina * _porPagina + 1}–${_pagina * _porPagina + quantidade} de $totalLocais locais',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 8,
                children: [
                  botao(
                    const Icon(Icons.chevron_left),
                    'Página anterior',
                    _pagina > 0 ? () => _mudarPagina(_pagina - 1) : null,
                  ),
                  for (var pagina = inicio; pagina < fim; pagina++)
                    botao(
                      Text(
                        '${pagina + 1}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      'Ir para página ${pagina + 1}',
                      () => _mudarPagina(pagina),
                      selecionado: pagina == _pagina,
                    ),
                  botao(
                    const Icon(Icons.chevron_right),
                    'Próxima página',
                    _pagina + 1 < totalPaginas
                        ? () => _mudarPagina(_pagina + 1)
                        : null,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _filtroCategoria(String? tipo) => ChoiceChip(
    avatar: Icon(tipo == null ? Icons.apps : _icone(tipo), size: 18),
    label: Text(tipo == null ? 'Todas as categorias' : _rotulo(tipo)),
    selected: _categoria == tipo,
    selectedColor: AppTheme.accent.withValues(alpha: .2),
    backgroundColor: AppTheme.secondary,
    side: BorderSide(
      color: _categoria == tipo
          ? AppTheme.accent
          : AppTheme.textSecondary.withValues(alpha: .2),
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    onSelected: (_) => setState(() {
      _categoria = tipo;
      _pagina = 0;
    }),
  );

  void _mudarPagina(int pagina) {
    setState(() => _pagina = pagina);
    _rolagem.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _trocarLista(bool personalizadas) {
    if (personalizadas == _personalizadas) return;
    setState(() {
      _personalizadas = personalizadas;
      _pagina = 0;
      _categoria = null;
    });
    _carregar();
  }

  Widget _boasVindas() => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: const LinearGradient(
        colors: [Color(0xFF622842), Color(0xFF211B35), Color(0xFF142B37)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      border: Border.all(color: AppTheme.accent.withValues(alpha: .22)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'BATEU A FOME?',
                style: TextStyle(
                  color: AppTheme.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Seu próximo lugar favorito está aqui.',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Explore restaurantes, cafés e novos sabores. Encontre um lugar para o seu momento.',
                style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        const Icon(Icons.ramen_dining, size: 44, color: AppTheme.accent),
      ],
    ),
  );

  Widget _cartao(Map<String, dynamic> local) {
    final tipo = '${local['tipo'] ?? 'Restaurante'}';
    final nota = _nota(local);
    final regiao = [
      local['bairro'],
      local['cidade'],
    ].where((v) => v != null && '$v'.trim().isNotEmpty).join(' · ');
    final horario = local['abre'] != null && local['fecha'] != null
        ? '${local['abre']} – ${local['fecha']}'
        : null;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withValues(alpha: .06)),
      ),
      child: InkWell(
        onTap: () => _abrir(local),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 164,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F3460), Color(0xFF302039)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -16,
                    bottom: -22,
                    child: Icon(
                      _icone(tipo),
                      size: 130,
                      color: Colors.white.withValues(alpha: .035),
                    ),
                  ),
                  Center(
                    child: Icon(
                      _icone(tipo),
                      size: 54,
                      color: const Color(0xFFF2BAC6),
                    ),
                  ),
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: Image.network(
                        _imagem(tipo),
                        fit: BoxFit.cover,
                        excludeFromSemantics: true,
                        errorBuilder: (_, _, _) => Center(
                          child: Icon(
                            _icone(tipo),
                            size: 54,
                            color: AppTheme.accent,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x33000000),
                            Color(0x00000000),
                            Color(0xAA000000),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 12,
                    bottom: 10,
                    child: Text(
                      'Imagem ilustrativa',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: _etiqueta(_rotulo(tipo)),
                  ),
                  if (nota != null)
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              nota.toStringAsFixed(1),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${local['nome'] ?? 'Restaurante'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _rotulo('${local['faixa_preco'] ?? ''}') +
                          (local['ambiente'] == null
                              ? ''
                              : ' · ${local['ambiente']}'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    if (regiao.isNotEmpty) ...[
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          const Icon(
                            Icons.place_outlined,
                            size: 14,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              regiao,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const Spacer(),
                    Row(
                      children: [
                        if (horario != null) ...[
                          const Icon(
                            Icons.schedule,
                            size: 14,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              horario,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ] else
                          const Spacer(),
                        const Text(
                          'Conhecer',
                          style: TextStyle(
                            color: AppTheme.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward,
                          color: AppTheme.accent,
                          size: 17,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _imagem(String tipo) {
    final categoria = _normalizar(tipo);
    final String foto;
    if (categoria.contains('pizza')) {
      foto = '1579751626657-72bc17010498';
    } else if (categoria.contains('burg') || categoria.contains('lanche')) {
      foto = '1568901346375-23c9450c58cd';
    } else if (categoria.contains('cafe')) {
      foto = '1509042239860-f550ce710b93';
    } else if (categoria.contains('japon') || categoria.contains('sushi')) {
      foto = '1579871494447-9811cf80d66c';
    } else if (categoria.contains('doce') || categoria.contains('sorvet')) {
      foto = '1563805042-7684c019e1cb';
    } else if (categoria.contains('bar')) {
      foto = '1514933651103-005eec06c04b';
    } else {
      foto = '1414235077428-338989a2e8c0';
    }
    return 'https://images.unsplash.com/photo-$foto?auto=format&fit=crop&w=800&q=80';
  }

  Widget _etiqueta(String texto) => Container(
    constraints: const BoxConstraints(maxWidth: 180),
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: AppTheme.background.withValues(alpha: .85),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Text(
      texto,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
    ),
  );
}
