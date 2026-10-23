import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meu_app/services/api.dart';
import 'package:meu_app/services/sessao.dart';
import 'package:meu_app/services/floter_service.dart';
import 'package:meu_app/models/floter_models.dart';
import 'apoio.dart';

void main() {
  late Sessao sessao;
  setUp(() async {
    sessao = await sessaoTeste();
  });
  tearDown(() => sessao.dispose());
  ApiService api(
    MockClient cliente, {
    Duration limite = const Duration(seconds: 20),
  }) => ApiService(
    cliente: cliente,
    sessao: sessao,
    baseUrl: 'http://teste.local',
    tempoLimite: limite,
  );
  test('login usa contrato real e persiste a sessao', () async {
    await sessao.sair();
    await api(
      MockClient((req) async {
        expect(req.url.path, '/auth/login');
        expect(jsonDecode(req.body), {
          'email': 'teste@example.com',
          'senha': 'segredo',
        });
        expect(req.headers['Authorization'], isNull);
        return http.Response(jsonEncode({'token': tokenTeste(id: 9)}), 200);
      }),
    ).login('teste@example.com', 'segredo');
    expect(sessao.idUsuario, 9);
  });
  test('cadastro envia nome email e hash_senha conforme API', () async {
    await api(
      MockClient((req) async {
        expect(req.url.path, '/usuarios');
        expect(jsonDecode(req.body)['hash_senha'], 'senha-teste');
        return http.Response('{"data":{}}', 201);
      }),
    ).register('Pessoa', 'pessoa@example.com', 'senha-teste');
  });
  test('lista locais envia Bearer e remove inativos', () async {
    final locais = await api(
      MockClient((req) async {
        expect(req.headers['Authorization'], 'Bearer ${sessao.token!}');
        return http.Response(
          '{"data":[{"nome":"Ativo"},{"nome":"Inativo","ativo":false}]}',
          200,
        );
      }),
    ).listEstabelecimentos();
    expect(locais.length, 1);
  });
  test('401 encerra sessao e permite redirecionar ao login', () async {
    await expectLater(
      api(MockClient((_) async => http.Response('{}', 401))).getUsuario(),
      throwsA(isA<ErroApi>()),
    );
    expect(sessao.autenticada, isFalse);
  });
  test('403 preserva sessao e apresenta mensagem', () async {
    await expectLater(
      api(
        MockClient(
          (_) async => http.Response('{"message":"Acesso negado"}', 403),
        ),
      ).getUsuario(),
      throwsA(isA<ErroApi>()),
    );
    expect(sessao.autenticada, isTrue);
  });
  test('requisicao antiga nao encerra outra sessao', () async {
    final resposta = Completer<http.Response>();
    final consulta = api(MockClient((_) => resposta.future)).getUsuario();
    await Future<void>.delayed(Duration.zero);
    await sessao.definirToken(tokenTeste(id: 99));
    resposta.complete(http.Response('{}', 401));
    await expectLater(consulta, throwsA(isA<ErroApi>()));
    expect(sessao.idUsuario, 99);
  });
  test('cabecalho de renovacao e respeitado quando fornecido', () async {
    final renovado = tokenTeste(validade: const Duration(hours: 2));
    await api(
      MockClient(
        (_) async => http.Response(
          '{"data":{}}',
          200,
          headers: {'x-access-token': renovado},
        ),
      ),
    ).getUsuario();
    expect(sessao.token, renovado);
  });
  test('JSON invalido tem erro amigavel', () async {
    await expectLater(
      api(MockClient((_) async => http.Response('<html>', 200))).getUsuario(),
      throwsA(isA<ErroApi>()),
    );
  });
  test('falha de rede tem mensagem tratada', () async {
    await expectLater(
      api(
        MockClient((_) async => throw http.ClientException('offline')),
      ).getUsuario(),
      throwsA(isA<ErroApi>()),
    );
  });
  test('timeout nao repete automaticamente uma escrita', () async {
    int envios = 0;
    await expectLater(
      api(
        MockClient((_) async {
          envios++;
          await Future<void>.delayed(const Duration(milliseconds: 30));
          return http.Response('{}', 201);
        }),
        limite: const Duration(milliseconds: 1),
      ).createInteracao(idEstabelecimento: 12, tipoEvento: 'like'),
      throwsA(isA<ErroApi>()),
    );
    expect(envios, 1);
  });
  test('interacao envia contrato usado pela outbox do backend', () async {
    await api(
      MockClient((req) async {
        expect(req.method, 'POST');
        expect(req.url.path, '/interacoes');
        expect(jsonDecode(req.body), {
          'id_estabelecimento': 12,
          'tipo_evento': 'rating',
          'valor': 4.0,
          'origem': 'app-flutter',
        });
        return http.Response('{"data":{"id_interacao":33}}', 201);
      }),
    ).createInteracao(
      idEstabelecimento: 12,
      tipoEvento: 'rating',
      valor: 4,
      origem: 'app-flutter',
    );
  });
  test('recomendacoes omitirem force_refresh quando falso', () async {
    await api(
      MockClient((req) async {
        expect(req.url.queryParameters.containsKey('force_refresh'), isFalse);
        return http.Response('{"data":[]}', 200);
      }),
    ).getRecomendacoes();
  });
  test('preferencias existentes sao lidas do snapshot', () async {
    final dados = await api(
      MockClient(
        (_) async => http.Response(
          '{"data":{"feature_json":{"categoria":"Pizza"}}}',
          200,
        ),
      ),
    ).getPreferencias();
    expect(dados?['categoria'], 'Pizza');
  });
  test('preferencias ausentes sao permitidas', () async {
    expect(
      await api(
        MockClient((_) async => http.Response('{"data":null}', 200)),
      ).getPreferencias(),
      isNull,
    );
  });
  test('Floter usa ranking real em vez de sugestoes simuladas', () async {
    final servico = FloterService(
      api: api(
        MockClient((req) async {
          expect(req.url.path, '/recomendacoes');
          expect(req.url.queryParameters['force_refresh'], 'true');
          return http.Response(
            '{"data":[{"id_estabelecimento":18,"nome":"Local real","tipo":"Pizza","faixa_preco":"medio","ambiente":"familiar"}]}',
            200,
          );
        }),
      ),
    );
    final locais = await servico.analisarPreferencias(
      const PreferenciasFloter(
        categoria: CategoriaComida.pizza,
        sabor: PreferenciaSabor.salgado,
        faixaPreco: FaixaPreco.medio,
        quantidadePessoas: QuantidadePessoas.duas,
        restricaoAlimentar: RestricaoAlimentar.nenhuma,
        modalidadeConsumo: ModalidadeConsumo.restaurante,
      ),
    );
    expect(locais.single.idEstabelecimento, 18);
    expect(locais.single.nome, 'Local real');
  });
}
