import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_app/components/notificacoes_button.dart';
import 'package:meu_app/pages/notificacoes_page.dart';
import 'package:meu_app/services/api.dart';

class ApiAvisosTeste extends ApiService {
  bool lida = false;
  bool vazia = false;
  bool falhar = false;
  final cursores = <int?>[];
  @override
  Future<Map<String, dynamic>> listNotificacoes({int? antes}) async {
    cursores.add(antes);
    if (falhar) throw const ErroApi('Falha na caixa de avisos');
    return {
      'naoLidas': lida || vazia ? 0 : 1,
      'temMais': !vazia && antes == null,
      'notificacoes': vazia
          ? []
          : [
              {
                'id_notificacao': antes == null ? 2 : 1,
                'id_estabelecimento': 7,
                'titulo': antes == null
                    ? 'Pizzaria tem novidades'
                    : 'Aviso anterior',
                'mensagem': 'Atualizou o horário de abertura.',
                'criado_em': '2026-10-23T12:00:00Z',
                'lida_em': lida ? '2026-10-23T13:00:00Z' : null,
              },
            ],
    };
  }

  @override
  Future<void> marcarNotificacaoLida(int id) async {
    lida = true;
  }

  @override
  Future<Map<String, dynamic>> getEstabelecimento(int id) async => {
    'nome': 'Pizzaria',
    'tipo': 'pizza',
  };
  @override
  Future<List<Map<String, dynamic>>> listMinhasInteracoes(int id) async => [];
  @override
  Future<Map<String, dynamic>> createInteracao({
    required int idEstabelecimento,
    required String tipoEvento,
    double? valor,
    String? origem,
  }) async => {};
}

void main() {
  testWidgets('sino mostra contador, abre avisos e atualiza apos leitura', (
    tester,
  ) async {
    final api = ApiAvisosTeste();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(actions: [NotificacoesButton(api: api)]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Notificações: 1 não lidas'));
    await tester.pumpAndSettle();
    expect(find.text('Pizzaria tem novidades'), findsOneWidget);
    await tester.tap(find.text('Pizzaria tem novidades'));
    await tester.pumpAndSettle();
    expect(api.lida, true);
    expect(find.text('Pizzaria'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byTooltip('Notificações'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('lista pagina e informa ausencia de avisos', (tester) async {
    final api = ApiAvisosTeste();
    await tester.pumpWidget(MaterialApp(home: NotificacoesPage(api: api)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Carregar mais'));
    await tester.pumpAndSettle();
    expect(api.cursores, [null, 2]);
    expect(find.text('Aviso anterior'), findsOneWidget);
    api.vazia = true;
    await tester.tap(find.byTooltip('Atualizar notificações'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Nenhuma notificação'), findsOneWidget);
  });
  testWidgets('falha de carregamento oferece nova tentativa', (tester) async {
    final api = ApiAvisosTeste()..falhar = true;
    await tester.pumpWidget(MaterialApp(home: NotificacoesPage(api: api)));
    await tester.pumpAndSettle();
    expect(
      find.text('Não foi possível carregar as notificações'),
      findsOneWidget,
    );
    api.falhar = false;
    await tester.tap(find.byTooltip('Atualizar notificações'));
    await tester.pumpAndSettle();
    expect(find.text('Pizzaria tem novidades'), findsOneWidget);
  });
}
