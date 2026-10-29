import 'dart:async';
import 'package:flutter/material.dart';
import '../pages/notificacoes_page.dart';
import '../services/api.dart';

class NotificacoesButton extends StatefulWidget {
  const NotificacoesButton({required this.api, super.key});
  final ApiService api;

  @override
  State<NotificacoesButton> createState() => _NotificacoesButtonState();
}

class _NotificacoesButtonState extends State<NotificacoesButton>
    with WidgetsBindingObserver {
  Timer? _timer;
  int _naoLidas = 0;
  bool _buscando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _atualizar();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        _atualizar();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _atualizar();
  }

  Future<void> _atualizar() async {
    if (_buscando) return;
    _buscando = true;
    try {
      final dados = await widget.api.listNotificacoes();
      if (mounted) {
        setState(() => _naoLidas = (dados['naoLidas'] as num?)?.toInt() ?? 0);
      }
    } catch (_) {
      // O catalogo continua disponivel quando a caixa de avisos esta indisponivel.
    } finally {
      _buscando = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: _naoLidas == 0
        ? 'Notificações'
        : 'Notificações: $_naoLidas não lidas',
    icon: Badge(
      isLabelVisible: _naoLidas > 0,
      label: Text(_naoLidas > 99 ? '99+' : '$_naoLidas'),
      child: const Icon(Icons.notifications_outlined),
    ),
    onPressed: () async {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => NotificacoesPage(api: widget.api),
        ),
      );
      if (mounted) await _atualizar();
    },
  );
}
