import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meu_app/components/cadastro_estabelecimento_dialog.dart';
import 'package:meu_app/services/api.dart';
import 'apoio.dart';

void main() {
  testWidgets('cadastro exige fechamento e envia formulario completo', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final sessao = await sessaoTeste();
    Map<String, dynamic>? enviado;
    final api = ApiService(
      sessao: sessao,
      cliente: MockClient((req) async {
        expect(req.method, 'POST');
        expect(req.url.path, '/estabelecimentos');
        enviado = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'data': {'id_estabelecimento': 99},
          }),
          201,
        );
      }),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<bool>(
                context: context,
                builder: (_) => CadastroEstabelecimentoDialog(api: api),
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Teste cadastro');
    for (final escolha in [
      'Restaurante',
      'Caro',
      'Formal',
      'Família',
    ].asMap().entries) {
      final campo = find
          .byType(DropdownButtonFormField<String>)
          .at(escolha.key);
      await tester.ensureVisible(campo);
      await tester.pumpAndSettle();
      await tester.tap(campo);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(escolha.value).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text(escolha.value).last);
      await tester.pumpAndSettle();
    }
    await tester.enterText(find.byType(TextFormField).at(1), '0900');
    await tester.tap(find.text('Cadastrar'));
    await tester.pumpAndSettle();
    expect(enviado, isNull);
    expect(find.text('Informe o horário de fechamento.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(2), '2200');
    await tester.tap(find.text('Cadastrar'));
    await tester.pumpAndSettle();
    expect(enviado, containsPair('abre', '09:00'));
    expect(enviado, containsPair('fecha', '22:00'));
    expect(enviado, containsPair('tipo', 'restaurante'));
    expect(find.byType(CadastroEstabelecimentoDialog), findsNothing);
    sessao.dispose();
  });
}
