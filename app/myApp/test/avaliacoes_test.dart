import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meu_app/pages/avaliacoes_page.dart';
import 'package:meu_app/services/api.dart';
import 'apoio.dart';

void main() {
  testWidgets('mostra comentarios e carrega a proxima pagina do restaurante', (
    tester,
  ) async {
    final sessao = await sessaoTeste();

    final paginas = <String?>[];
    final api = ApiService(
      sessao: sessao,
      cliente: MockClient((req) async {
        expect(req.url.path, '/estabelecimentos/7/avaliacoes');
        final pagina = req.url.queryParameters['pagina'];
        paginas.add(pagina);
        return http.Response(
          jsonEncode({
            'data': {
              'avaliacoes': [
                {
                  'nome': pagina == '1' ? 'Ana' : 'Bruno',
                  'nota': 5,
                  'comentario': pagina == '1' ? 'Comida excelente!' : null,
                  'created_at': '2026-10-23T12:00:00Z',
                },
              ],
              'temMais': pagina == '1',
            },
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: AvaliacoesPage(id: 7, nome: 'Restaurante', api: api),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Comida excelente!'), findsOneWidget);
    expect(find.text('5.0 / 5'), findsOneWidget);
    await tester.tap(find.text('Carregar mais avaliações'));
    await tester.pumpAndSettle();
    expect(paginas, ['1', '2']);
    expect(find.text('Bruno'), findsOneWidget);
    expect(find.text('Avaliação sem comentário.'), findsOneWidget);
    expect(find.text('Carregar mais avaliações'), findsNothing);
    sessao.dispose();
  });

  testWidgets('lista vazia informa ausencia de avaliacoes', (tester) async {
    final sessao = await sessaoTeste();

    final api = ApiService(
      sessao: sessao,
      cliente: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'data': {'avaliacoes': [], 'temMais': false},
          }),
          200,
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: AvaliacoesPage(id: 7, nome: 'Restaurante', api: api),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ainda não há avaliações'), findsOneWidget);
    sessao.dispose();
  });
}
