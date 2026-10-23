import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class ArmazenamentoSessao {
  Future<String?> ler();
  Future<void> gravar(String token);
  Future<void> limpar();
}

class ArmazenamentoSeguro implements ArmazenamentoSessao {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _chave = 'floter.sessao';
  @override
  Future<String?> ler() => _storage.read(key: _chave);
  @override
  Future<void> gravar(String token) =>
      _storage.write(key: _chave, value: token);
  @override
  Future<void> limpar() => _storage.delete(key: _chave);
}

class Sessao extends ChangeNotifier {
  Sessao({ArmazenamentoSessao? armazenamento})
    : _armazenamento = armazenamento ?? ArmazenamentoSeguro();
  static final instancia = Sessao();
  final ArmazenamentoSessao _armazenamento;
  String? _token;
  int? _idUsuario;
  DateTime? _expiracao;
  Timer? _temporizador;
  Future<void> _persistencia = Future.value();
  String? get token => _token;
  int? get idUsuario => _idUsuario;
  bool get autenticada =>
      _token != null &&
      _expiracao != null &&
      _expiracao!.isAfter(DateTime.now());

  // A leitura local serve para expiracao e navegacao. A assinatura e validada pela API.
  static Map<String, dynamic> lerPayload(String token) {
    final partes = token.split('.');
    if (partes.length != 3) throw const FormatException('Token invalido');
    final dados = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(partes[1]))),
    );
    if (dados is! Map<String, dynamic> ||
        dados['id_usuario'] is! int ||
        (dados['id_usuario'] as int) <= 0 ||
        dados['exp'] is! num) {
      throw const FormatException('Sessao invalida');
    }
    return dados;
  }

  Future<void> inicializar() async {
    try {
      final salvo = await _armazenamento.ler();
      if (salvo != null) await definirToken(salvo);
    } catch (_) {
      await sair();
    }
  }

  Future<void> _salvar(String? token) {
    _persistencia = _persistencia.catchError((Object _) {}).then((_) async {
      if (token == null) {
        await _armazenamento.limpar();
      } else {
        await _armazenamento.gravar(token);
      }
    });
    return _persistencia;
  }

  Future<void> definirToken(String token) async {
    final dados = lerPayload(token);
    final expiracao = DateTime.fromMillisecondsSinceEpoch(
      (dados['exp'] as num).toInt() * 1000,
    );
    if (!expiracao.isAfter(DateTime.now())) {
      await sair();
      return;
    }
    _token = token;
    _idUsuario = dados['id_usuario'] as int;
    _expiracao = expiracao;
    _temporizador?.cancel();
    _temporizador = Timer(expiracao.difference(DateTime.now()), () {
      unawaited(sair());
    });
    // Persistencia indisponivel nao impede a sessao em memoria.
    try {
      await _salvar(token);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> sair() async {
    _token = null;
    _idUsuario = null;
    _expiracao = null;
    _temporizador?.cancel();
    notifyListeners();
    try {
      await _salvar(null);
    } catch (_) {}
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    super.dispose();
  }
}
