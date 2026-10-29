import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meu_app/pages/avaliacoes_page.dart';
import 'package:meu_app/services/api.dart';
import 'apoio.dart';

void main() {
  testWidgets('curtir comentario atualiza contador e impede envio duplicado', (
    tester,
  ) async {
    final sessao = await sessaoTeste();
    var envios = 0;
    final api = ApiService(
      sessao: sessao,
      cliente: MockClient((req) async {
        final Object dados;
        if (req.method == 'PUT') {
          expect(req.url.path, '/estabelecimentos/7/comentarios/42/curtida');
          envios++;
          dados = {'curtido': true, 'total_curtidas': 50};
        } else {
          dados = {
            'avaliacoes': [
              {
                'id_classificacao': 42,
                'nome': 'Ana',
                'comentario': 'Adorei!',
                'total_curtidas': 49,
                'curtido': false,
                'proprio': false,
              },
            ],
            'temMais': false,
          };
        }
        return http.Response(
          jsonEncode({'data': dados}),
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
    await tester.ensureVisible(find.text('Curtir · 49'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Curtir · 49'));
    await tester.pumpAndSettle();
    expect(find.text('Curtido · 50'), findsOneWidget);
    await tester.tap(find.text('Curtido · 50'));
    await tester.pumpAndSettle();
    expect(envios, 1);
    sessao.dispose();
  });

  testWidgets('publica comentario e atualiza a lista', (tester) async {
    final sessao = await sessaoTeste();
    String? comentario;
    final api = ApiService(
      sessao: sessao,
      cliente: MockClient((req) async {
        Object dados;
        if (req.url.path == '/classificacoes') {
          expect(jsonDecode(req.body)['id_usuario'], sessao.idUsuario);
          dados = {'id_classificacao': 42};
        } else if (req.url.path == '/classificacoes-estabelecimentos') {
          final corpo = jsonDecode(req.body);
          expect(corpo['id_estabelecimento'], 7);
          expect(corpo['id_classificacao'], 42);
          comentario = corpo['comentario'] as String;
          dados = {};
        } else {
          dados = {
            'avaliacoes': [
              if (comentario != null) {'nome': 'Ana', 'comentario': comentario},
            ],
            'temMais': false,
          };
        }
        return http.Response(
          jsonEncode({'data': dados}),
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
    await tester.tap(find.text('Deixar um comentário'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Publicar comentário'));
    await tester.pumpAndSettle();
    expect(
      find.text('Escreva um comentário antes de publicar.'),
      findsOneWidget,
    );
    await tester.enterText(
      find.byType(TextFormField),
      '  Ótimo atendimento!  ',
    );
    await tester.tap(find.text('Publicar comentário'));
    await tester.pumpAndSettle();
    expect(comentario, 'Ótimo atendimento!');
    expect(find.text('Ótimo atendimento!'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    sessao.dispose();
  });

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
    await tester.ensureVisible(find.text('Carregar mais avaliações'));
    await tester.pumpAndSettle();
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
