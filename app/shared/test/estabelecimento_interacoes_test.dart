import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_app/pages/estabelecimento_page.dart';
import 'package:meu_app/services/api.dart';

class ApiInteracoesTeste extends ApiService {
  @override
  Future<Map<String, dynamic>> listNotificacoes({int? antes}) async => {
    'notificacoes': [],
    'naoLidas': 0,
    'temMais': false,
  };
  String opiniao = 'like';
  Completer<void>? envio;
  bool falhar = false;

  @override
  Future<Map<String, dynamic>> getEstabelecimento(int id) async => {
    'nome': 'Local teste',
    'tipo': 'bar',
    'faixa_preco': 'media',
  };

  @override
  Future<List<Map<String, dynamic>>> listMinhasInteracoes(int id) async => [
    {'tipo_evento': opiniao},
    if (opiniao == 'neutral') {'tipo_evento': 'like'},
    if (opiniao == 'neutral') {'tipo_evento': 'dislike'},
  ];

  @override
  Future<Map<String, dynamic>> createInteracao({
    required int idEstabelecimento,
    required String tipoEvento,
    double? valor,
    String? origem,
  }) async {
    if (tipoEvento == 'view') return {};
    await envio?.future;
    if (falhar) throw const ErroApi('Falha ao salvar');
    opiniao = tipoEvento;
    return {'tipo_evento': tipoEvento};
  }
}

void main() {
  Color? cor(WidgetTester tester, String texto) {
    final material = tester.widget<Material>(
      find
          .ancestor(of: find.text(texto), matching: find.byType(Material))
          .first,
    );
    return material.color;
  }

  testWidgets('troca destaque imediatamente, salva e restaura ao reabrir', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = ApiInteracoesTeste();
    await tester.pumpWidget(
      MaterialApp(home: EstabelecimentoPage(id: 1, api: api)),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Não gostei'));
    expect(cor(tester, 'Gostei'), Colors.amber);
    api.envio = Completer<void>();
    await tester.tap(find.text('Não gostei'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(cor(tester, 'Não gostei'), Colors.amber);
    expect(cor(tester, 'Gostei'), Colors.transparent);
    api.envio!.complete();
    await tester.pumpAndSettle();
    expect(api.opiniao, 'dislike');
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      MaterialApp(home: EstabelecimentoPage(id: 1, api: api)),
    );
    await tester.pumpAndSettle();
    expect(cor(tester, 'Não gostei'), Colors.amber);
    await tester.ensureVisible(find.text('Gostei'));
    await tester.tap(find.text('Gostei'));
    await tester.pumpAndSettle();
    expect(cor(tester, 'Gostei'), Colors.amber);
    expect(cor(tester, 'Não gostei'), Colors.transparent);
    await tester.tap(find.text('Gostei'));
    await tester.pumpAndSettle();
    expect(api.opiniao, 'neutral');
    expect(cor(tester, 'Gostei'), Colors.transparent);
    expect(cor(tester, 'Não gostei'), Colors.transparent);
    expect(find.text('Nenhuma opinião selecionada.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      MaterialApp(home: EstabelecimentoPage(id: 1, api: api)),
    );
    await tester.pumpAndSettle();
    expect(cor(tester, 'Gostei'), Colors.transparent);
    expect(cor(tester, 'Não gostei'), Colors.transparent);
  });

  testWidgets('restaura selecao anterior se o salvamento falhar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = ApiInteracoesTeste()..falhar = true;
    await tester.pumpWidget(
      MaterialApp(home: EstabelecimentoPage(id: 1, api: api)),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Não gostei'));
    await tester.tap(find.text('Não gostei'));
    await tester.pumpAndSettle();
    expect(cor(tester, 'Gostei'), Colors.amber);
    expect(cor(tester, 'Não gostei'), Colors.transparent);
    expect(find.text('Falha ao salvar'), findsOneWidget);
  });
}
