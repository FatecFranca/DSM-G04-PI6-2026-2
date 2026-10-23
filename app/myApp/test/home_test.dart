import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meu_app/pages/home_page.dart';
import 'package:meu_app/services/api.dart';
import 'package:meu_app/services/sessao.dart';
import 'package:meu_app/theme/app_theme.dart';
import 'apoio.dart';

const locais = [
  {
    'id_estabelecimento': 1,
    'nome': 'Pizzaria Real',
    'tipo': 'pizzaria',
    'faixa_preco': 'medio',
    'avaliacao': '4.2',
    'abre': '18:00',
    'fecha': '23:00',
  },
  {
    'id_estabelecimento': 2,
    'nome': 'Burger da Praça',
    'tipo': 'hamburgueria',
    'faixa_preco': 'barato',
    'avaliacao': '4.7',
  },
  {
    'id_estabelecimento': 3,
    'nome': 'Café do Bairro',
    'tipo': 'cafeteria',
    'faixa_preco': 'medio',
    'avaliacao': '4.9',
  },
];
http.Response resposta(Object lista) => http.Response(
  jsonEncode({'data': lista}),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  late Sessao sessao;
  setUp(() async {
    sessao = await sessaoTeste();
  });
  tearDown(() => sessao.dispose());
  Future<void> abrir(WidgetTester tester, {MockClient? cliente}) async {
    final api = ApiService(
      sessao: sessao,
      cliente: cliente ?? MockClient((_) async => resposta(locais)),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: HomePage(api: api),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('home abre catalogo completo sem depender das recomendacoes', (
    tester,
  ) async {
    final caminhos = <String>[];
    await abrir(
      tester,
      cliente: MockClient((req) async {
        caminhos.add(req.url.path);
        return resposta(locais);
      }),
    );
    expect(caminhos, ['/estabelecimentos']);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -280));
    await tester.pumpAndSettle();
    expect(find.text('Pizzaria Real'), findsOneWidget);
    expect(find.text('Restaurantes para descobrir'), findsOneWidget);
    expect(find.text('3 locais disponíveis'), findsOneWidget);
  });
  testWidgets('categoria filtra os restaurantes da home', (tester) async {
    await abrir(tester);
    await tester.drag(find.byType(ListView).first, const Offset(-500, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Pizzaria'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -280));
    await tester.pumpAndSettle();
    expect(find.text('Pizzaria Real'), findsOneWidget);
    expect(find.text('Burger da Praça'), findsNothing);
    expect(find.text('1 local disponível'), findsOneWidget);
  });
  testWidgets('busca encontra nome com acento usando texto sem acento', (
    tester,
  ) async {
    await abrir(tester);
    await tester.enterText(find.byType(TextField), 'cafe');
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -280));
    await tester.pumpAndSettle();
    expect(find.text('Café do Bairro'), findsOneWidget);
    expect(find.text('Pizzaria Real'), findsNothing);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 1000));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Limpar busca'));
    await tester.pumpAndSettle();
    expect(find.text('3 locais disponíveis'), findsOneWidget);
  });
  testWidgets('Para voce consulta recomendacoes sem substituir o catalogo', (
    tester,
  ) async {
    final caminhos = <String>[];
    await abrir(
      tester,
      cliente: MockClient((req) async {
        caminhos.add(req.url.path);
        return resposta(
          req.url.path == '/recomendacoes' ? [locais[1]] : locais,
        );
      }),
    );
    await tester.tap(find.widgetWithText(ChoiceChip, 'Para você'));
    await tester.pumpAndSettle();
    expect(caminhos, ['/estabelecimentos', '/recomendacoes']);
    expect(find.text('Escolhidos para você'), findsOneWidget);
    expect(find.text('1 local disponível'), findsOneWidget);
  });
  testWidgets('ordenacao por nota permite explorar os melhores avaliados', (
    tester,
  ) async {
    await abrir(tester);
    await tester.ensureVisible(find.byTooltip('Ordenar restaurantes'));
    await tester.tap(find.byTooltip('Ordenar restaurantes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Melhor avaliação'));
    await tester.pumpAndSettle();
    final primeiro = tester.getTopLeft(find.text('Café do Bairro'));
    final segundo = tester.getTopLeft(find.text('Burger da Praça'));
    expect(primeiro.dy <= segundo.dy, isTrue);
    if (primeiro.dy == segundo.dy) expect(primeiro.dx < segundo.dx, isTrue);
  });
  testWidgets(
    'home vazia informa ausencia de dados sem inventar restaurantes',
    (tester) async {
      await abrir(tester, cliente: MockClient((_) async => resposta([])));
      expect(find.text('Nenhum restaurante encontrado'), findsOneWidget);
      expect(find.byType(Card), findsNothing);
    },
  );
  testWidgets('cards navegam para os detalhes do restaurante escolhido', (
    tester,
  ) async {
    final api = ApiService(
      sessao: sessao,
      cliente: MockClient((_) async => resposta(locais)),
    );
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, _) => HomePage(api: api),
        ),
        GoRoute(
          path: '/estabelecimentos/:id',
          builder: (_, state) => Scaffold(
            body: Text('Detalhes do local ${state.pathParameters['id']}'),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Pizzaria Real'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Pizzaria Real'));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 100));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pizzaria Real'));
    await tester.pumpAndSettle();
    expect(find.text('Detalhes do local 1'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
  });
  testWidgets('paginacao limita cards e busca reinicia na primeira pagina', (
    tester,
  ) async {
    final lista = List.generate(
      13,
      (i) => {
        ...locais[0],
        'id_estabelecimento': i + 1,
        'nome': 'Local ${i + 1}',
      },
    );
    await abrir(tester, cliente: MockClient((_) async => resposta(lista)));
    await tester.scrollUntilVisible(
      find.byTooltip('Próxima página'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Página 1 de 2'), findsOneWidget);
    expect(find.text('Local 13'), findsNothing);
    await tester.tap(find.byTooltip('Próxima página'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Local 13'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Local 13'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byType(TextField),
      -500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byType(TextField), 'Local 13');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byTooltip('Próxima página'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Página 1 de 1'), findsOneWidget);
    expect(
      tester.widget<IconButton>(find.byWidgetPredicate(
        (widget) => widget is IconButton && widget.tooltip == 'Próxima página',
      )).onPressed,
      isNull,
    );
  });

  testWidgets('home com restaurantes cabe em celular estreito', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await abrir(tester);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -420));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
