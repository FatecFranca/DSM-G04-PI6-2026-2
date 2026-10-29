import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api.dart';
import '../pages/estabelecimento_page.dart';
import '../theme/app_theme.dart';

class SugestoesAutomaticas extends StatefulWidget {
  const SugestoesAutomaticas({required this.api, super.key});
  final ApiService api;
  @override
  State<SugestoesAutomaticas> createState() => _SugestoesAutomaticasState();
}

class _SugestoesAutomaticasState extends State<SugestoesAutomaticas>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _buscando = false;
  bool _iniciando = true;
  String? _erro;
  List<Map<String, dynamic>> _sugestoes = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _carregar();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed &&
          (ModalRoute.of(context)?.isCurrent ?? true)) {
        _carregar();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _carregar();
  }

  Future<void> _carregar() async {
    if (_buscando) return;
    _buscando = true;
    try {
      final sugestoes = await widget.api.getSugestoesAutomaticas();
      if (mounted) {
        setState(() {
          _sugestoes = sugestoes;
          _erro = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _erro = 'Não foi possível atualizar suas sugestões.');
      }
    } finally {
      _buscando = false;
      if (mounted) setState(() => _iniciando = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _sugestoes.isEmpty && _erro == null
      ? const SizedBox.shrink()
      : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sugestões com base nas suas avaliações',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_iniciando)
              const LinearProgressIndicator()
            else if (_erro != null)
              Row(
                children: [
                  Expanded(child: Text(_erro!)),
                  TextButton(
                    onPressed: _carregar,
                    child: const Text('Atualizar sugestões'),
                  ),
                ],
              )
            else if (_sugestoes.isEmpty)
              const Text(
                'Avalie os lugares que conhece. Suas sugestões aparecerão aqui automaticamente assim que forem preparadas.',
              )
            else ...[
              const Text(
                'Novas opções para descobrir, atualizadas conforme você avalia.',
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 158,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _sugestoes.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, indice) {
                    final local = _sugestoes[indice];
                    return SizedBox(
                      width: 230,
                      child: Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => EstabelecimentoPage(
                                  id: (local['id_estabelecimento'] as num)
                                      .toInt(),
                                  api: widget.api,
                                ),
                              ),
                            );
                            if (mounted) await _carregar();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.auto_awesome,
                                  color: AppTheme.accent,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${local['nome']}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${local['tipo']} · ${local['faixa_preco']}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        );
}
