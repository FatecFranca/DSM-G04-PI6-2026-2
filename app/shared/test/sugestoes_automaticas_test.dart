import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_app/components/sugestoes_automaticas.dart';
import 'package:meu_app/services/api.dart';

class ApiSugestoesTeste extends ApiService {
  int consultas = 0;
  bool falhar = false;
  List<Map<String, dynamic>> sugestoes = [];
  @override
  Future<List<Map<String, dynamic>>> getSugestoesAutomaticas() async {
    consultas++;
    if (falhar) throw const ErroApi('offline');
    return sugestoes;
  }
}

void main() {
  testWidgets('sugestoes aparecem automaticamente e polling encerra ao sair', (
    tester,
  ) async {
    final api = ApiSugestoesTeste();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SugestoesAutomaticas(api: api)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Avalie os lugares'), findsNothing);
    api.sugestoes = [
      {
        'id_estabelecimento': 7,
        'nome': 'Nova pizzaria',
        'tipo': 'pizza',
        'faixa_preco': 'media',
      },
    ];
    await tester.pump(const Duration(seconds: 15));
    await tester.pumpAndSettle();
    expect(find.text('Nova pizzaria'), findsOneWidget);
    expect(api.consultas, 2);
    api.sugestoes = [
      {
        'id_estabelecimento': 8,
        'nome': 'Outro restaurante',
        'tipo': 'cafe',
        'faixa_preco': 'barata',
      },
    ];
    await tester.pump(const Duration(seconds: 15));
    await tester.pumpAndSettle();
    expect(find.text('Nova pizzaria'), findsNothing);
    expect(find.text('Outro restaurante'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    final consultas = api.consultas;
    await tester.pump(const Duration(seconds: 30));
    expect(api.consultas, consultas);
  });

  testWidgets('falha das sugestoes permite tentar novamente', (tester) async {
    final api = ApiSugestoesTeste()..falhar = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SugestoesAutomaticas(api: api)),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Não foi possível atualizar suas sugestões.'),
      findsOneWidget,
    );
    api.falhar = false;
    await tester.tap(find.text('Atualizar sugestões'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Avalie os lugares'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
