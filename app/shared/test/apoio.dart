import 'dart:convert';
import 'package:meu_app/services/sessao.dart';

class MemoriaSessao implements ArmazenamentoSessao {
  String? valor;
  @override
  Future<String?> ler() async => valor;
  @override
  Future<void> gravar(String token) async {
    valor = token;
  }

  @override
  Future<void> limpar() async {
    valor = null;
  }
}

String tokenTeste({
  int id = 7,
  Duration validade = const Duration(minutes: 30),
}) =>
    'cabecalho.${base64Url.encode(utf8.encode(jsonEncode({'id_usuario': id, 'exp': DateTime.now().add(validade).millisecondsSinceEpoch ~/ 1000}))).replaceAll('=', '')}.assinatura';
Future<Sessao> sessaoTeste() async {
  final sessao = Sessao(armazenamento: MemoriaSessao());
  await sessao.definirToken(tokenTeste());
  return sessao;
}
