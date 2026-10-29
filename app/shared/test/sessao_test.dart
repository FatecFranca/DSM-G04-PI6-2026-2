import 'package:flutter_test/flutter_test.dart';
import 'package:meu_app/services/sessao.dart';
import 'apoio.dart';

void main() {
  test('restaura token valido do armazenamento', () async {
    final memoria = MemoriaSessao()..valor = tokenTeste();
    final sessao = Sessao(armazenamento: memoria);
    await sessao.inicializar();
    expect(sessao.autenticada, isTrue);
    expect(sessao.idUsuario, 7);
    sessao.dispose();
  });
  test('remove token expirado na inicializacao', () async {
    final memoria = MemoriaSessao()
      ..valor = tokenTeste(validade: const Duration(minutes: -1));
    final sessao = Sessao(armazenamento: memoria);
    await sessao.inicializar();
    expect(sessao.autenticada, isFalse);
    expect(memoria.valor, isNull);
    sessao.dispose();
  });
  test('token malformado nao impede abrir o app', () async {
    final memoria = MemoriaSessao()..valor = 'invalido';
    final sessao = Sessao(armazenamento: memoria);
    await sessao.inicializar();
    expect(memoria.valor, isNull);
    sessao.dispose();
  });
  test('logout limpa memoria e persistencia', () async {
    final memoria = MemoriaSessao();
    final sessao = Sessao(armazenamento: memoria);
    await sessao.definirToken(tokenTeste());
    await sessao.sair();
    expect(sessao.token, isNull);
    expect(sessao.idUsuario, isNull);
    expect(memoria.valor, isNull);
    sessao.dispose();
  });
  test('gravacoes concorrentes respeitam logout', () async {
    final memoria = MemoriaSessao();
    final sessao = Sessao(armazenamento: memoria);
    await Future.wait([sessao.definirToken(tokenTeste()), sessao.sair()]);
    expect(memoria.valor, isNull);
    expect(sessao.autenticada, isFalse);
    sessao.dispose();
  });
  testWidgets('expiracao notifica e encerra sessao', (tester) async {
    final sessao = Sessao(armazenamento: MemoriaSessao());
    await sessao.definirToken(tokenTeste(validade: const Duration(seconds: 2)));
    await tester.pump(const Duration(seconds: 3));
    expect(sessao.autenticada, isFalse);
    sessao.dispose();
  });
}
