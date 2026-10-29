import 'package:go_router/go_router.dart';
import 'package:meu_app/pages/floter_page.dart';
import 'package:meu_app/components/floter_option_card.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meu_app/main.dart';
import 'package:meu_app/pages/sugestoes_page.dart';
import 'package:meu_app/pages/rating_history_page.dart';
import 'package:meu_app/pages/estabelecimento_page.dart';
import 'package:meu_app/router/app_router.dart';
import 'package:meu_app/services/api.dart';
import 'package:meu_app/services/sessao.dart';
import 'package:meu_app/theme/app_theme.dart';
import 'apoio.dart';

void main() {
  testWidgets('app abre formulario de login', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
  testWidgets('rota privada sem sessao redireciona ao login', (tester) async {
    final sessao = Sessao(armazenamento: MemoriaSessao());
    final router = AppRouter.criarRoteador(
      sessao: sessao,
      localInicial: '/user',
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/login');
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    sessao.dispose();
  });
  testWidgets('login funciona em viewport mobile estreita e com teclado', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextFormField).first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('descoberta apresenta locais reais e filtra busca', (
    tester,
  ) async {
    final sessao = await sessaoTeste();
    final api = ApiService(
      sessao: sessao,
      cliente: MockClient(
        (req) async => req.url.path == '/recomendacoes/automaticas'
            ? http.Response('{"data":[]}', 200)
            : http.Response(
                jsonEncode({
                  'data': [
                    {
                      'id_estabelecimento': 1,
                      'nome': 'Pizzaria real',
                      'tipo': 'Pizza',
                      'faixa_preco': 'medio',
                    },
                    {
                      'id_estabelecimento': 2,
                      'nome': 'Cafe real',
                      'tipo': 'Cafe',
                      'faixa_preco': 'baixo',
                    },
                  ],
                }),
                200,
              ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: SugestoesPage(api: api),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -280));
    await tester.pumpAndSettle();
    expect(find.text('Pizzaria real'), findsOneWidget);
    await tester.ensureVisible(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'Cafe');
    await tester.pump();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -280));
    await tester.pumpAndSettle();
    expect(find.text('Pizzaria real'), findsNothing);
    expect(find.text('Cafe real'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    sessao.dispose();
  });
  testWidgets('falha de rede apresenta tentativa novamente', (tester) async {
    final sessao = await sessaoTeste();
    final api = ApiService(
      sessao: sessao,
      cliente: MockClient((_) async => throw http.ClientException('offline')),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: SugestoesPage(api: api),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tentar novamente'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    sessao.dispose();
  });
  testWidgets('historico vazio permite fazer primeira avaliacao', (
    tester,
  ) async {
    final sessao = await sessaoTeste();
    final api = ApiService(
      sessao: sessao,
      cliente: MockClient((_) async => http.Response('{"data":[]}', 200)),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: RatingHistoryPage(api: api),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Fazer primeira avaliação'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    sessao.dispose();
  });
  testWidgets('detalhes registra view e like no backend', (tester) async {
    final sessao = await sessaoTeste();
    final tipos = <String>[];
    final api = ApiService(
      sessao: sessao,
      cliente: MockClient((req) async {
        if (req.url.path == '/interacoes/me') {
          return http.Response('{"data":[]}', 200);
        }
        if (req.url.path == '/notificacoes') {
          return http.Response(
            '{"data":{"notificacoes":[],"naoLidas":0,"temMais":false}}',
            200,
          );
        }
        if (req.method == 'POST') {
          tipos.add(jsonDecode(req.body)['tipo_evento'] as String);
          return http.Response('{"data":{"id_interacao":1}}', 201);
        }
        return http.Response(
          '{"data":{"id_estabelecimento":1,"nome":"Local real","tipo":"Pizza","faixa_preco":"medio","avaliacao":"4.5","abre":"18:00","fecha":"23:00","ambiente":"familiar","publico":"todos"}}',
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: EstabelecimentoPage(id: 1, api: api),
      ),
    );
    await tester.pumpAndSettle();
    expect(tipos, ['view']);
    await tester.scrollUntilVisible(
      find.text('Gostei'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Gostei'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gostei'));
    await tester.pumpAndSettle();
    expect(tipos, ['view', 'like']);
    await tester.pumpWidget(const SizedBox());
    sessao.dispose();
  });

  testWidgets('preferencias salvas sao restauradas no questionario', (
    tester,
  ) async {
    final sessao = await sessaoTeste();
    final api = ApiService(
      sessao: sessao,
      cliente: MockClient(
        (_) async => http.Response(
          '{"data":{"feature_json":{"categoria":"Pizza"}}}',
          200,
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: FloterPage(api: api),
      ),
    );
    await tester.pumpAndSettle();
    final selecionados = tester
        .widgetList<FloterOptionCard>(find.byType(FloterOptionCard))
        .where((card) => card.selected);
    expect(selecionados.single.label, 'Pizza');
    await tester.pumpWidget(const SizedBox());
    sessao.dispose();
  });
  testWidgets('questionario salva contrato completo antes de abrir resultados', (
    tester,
  ) async {
    final sessao = await sessaoTeste();
    Map<String, dynamic>? enviado;
    final api = ApiService(
      sessao: sessao,
      cliente: MockClient((req) async {
        if (req.method == 'PUT') {
          enviado = jsonDecode(req.body) as Map<String, dynamic>;
          return http.Response('{"data":{}}', 201);
        }
        return http.Response(
          '{"data":{"feature_json":{"categoria":"Pizza","sabor":"Salgado","faixa_preco":"Médio","quantidade_pessoas":"2 pessoas","restricao_alimentar":"Nenhuma","modalidade_consumo":"Comer no restaurante"}}}',
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    final router = GoRouter(
      initialLocation: '/floter',
      routes: [
        GoRoute(
          path: '/floter',
          builder: (_, _) => FloterPage(api: api),
        ),
        GoRoute(
          path: '/floter/resultados',
          builder: (_, _) => const Scaffold(body: Text('Resultado real')),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
    );
    await tester.pumpAndSettle();
    for (int etapa = 0; etapa < 6; etapa++) {
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Encontrar sugestões'));
    await tester.pumpAndSettle();
    expect(enviado?['categoria'], 'Pizza');
    expect(enviado?['faixa_preco'], 'Médio');
    expect(enviado?['modalidade_consumo'], 'Comer no restaurante');
    expect(find.text('Resultado real'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    sessao.dispose();
  });
  testWidgets('descoberta acomoda teclado em tela mobile', (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    final sessao = await sessaoTeste();
    final api = ApiService(
      sessao: sessao,
      cliente: MockClient((_) async => http.Response('{"data":[]}', 200)),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: SugestoesPage(api: api),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    sessao.dispose();
  });
}
