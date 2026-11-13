import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'sessao.dart';

class ErroApi implements Exception {
  const ErroApi(this.mensagem, {this.status});
  final String mensagem;
  final int? status;
  @override
  String toString() => mensagem;
}

class ApiService {
  Future<Map<String, dynamic>> cadastrarEstabelecimento(
    Map<String, dynamic> dados,
  ) async =>
      _registro(await _requisicao('POST', '/estabelecimentos', corpo: dados));
  ApiService({
    http.Client? cliente,
    String? baseUrl,
    Sessao? sessao,
    Duration tempoLimite = const Duration(seconds: 20),
  }) : _cliente = cliente ?? _clienteCompartilhado,
       _baseUrl = (baseUrl ?? urlConfigurada).replaceAll(RegExp(r'/+$'), ''),
       _sessao = sessao ?? Sessao.instancia,
       _tempoLimite = tempoLimite;
  static final http.Client _clienteCompartilhado = http.Client();
  static const _urlAmbiente = String.fromEnvironment('API_URL');
  static String get urlConfigurada => _urlAmbiente.isNotEmpty
      ? _urlAmbiente
      : (!kIsWeb && defaultTargetPlatform == TargetPlatform.android
            ? 'http://10.0.2.2:8080'
            : 'http://localhost:8080');
  final http.Client _cliente;
  final String _baseUrl;
  final Sessao _sessao;
  final Duration _tempoLimite;
  static String? get token => Sessao.instancia.token;
  static int? get userId => Sessao.instancia.idUsuario;
  static Future<void> logout() => Sessao.instancia.sair();

  Future<Map<String, dynamic>> _requisicao(
    String metodo,
    String caminho, {
    Map<String, dynamic>? corpo,
    Map<String, String>? parametros,
    bool autenticada = true,
  }) async {
    final tokenEnviado = _sessao.token;
    if (autenticada && !_sessao.autenticada) {
      await _sessao.sair();
      throw const ErroApi(
        'SessÃƒÂ£o expirada. FaÃƒÂ§a login novamente.',
        status: 401,
      );
    }
    final url = Uri.parse(
      '$_baseUrl$caminho',
    ).replace(queryParameters: parametros);
    final requisicao = http.Request(metodo, url);
    requisicao.headers['Content-Type'] = 'application/json';
    if (autenticada) {
      requisicao.headers['Authorization'] = 'Bearer $tokenEnviado';
    }
    if (corpo != null) requisicao.body = jsonEncode(corpo);
    late http.Response resposta;
    try {
      final recebida = await _cliente.send(requisicao).timeout(_tempoLimite);
      resposta = await http.Response.fromStream(recebida).timeout(_tempoLimite);
    } on TimeoutException {
      throw const ErroApi(
        'O servidor demorou para responder. Tente novamente.',
      );
    } on http.ClientException {
      throw const ErroApi(
        'NÃƒÂ£o foi possÃƒÂ­vel conectar. Verifique sua conexÃƒÂ£o e tente novamente.',
      );
    }
    if (resposta.statusCode == 401 && autenticada) {
      // Uma resposta antiga nao pode encerrar uma nova sessao.
      if (_sessao.token == tokenEnviado) await _sessao.sair();
      throw const ErroApi(
        'SessÃƒÂ£o expirada. FaÃƒÂ§a login novamente.',
        status: 401,
      );
    }
    Map<String, dynamic> dados = {};
    try {
      if (resposta.bodyBytes.isNotEmpty) {
        final decodificado = jsonDecode(utf8.decode(resposta.bodyBytes));
        if (decodificado is! Map<String, dynamic>) {
          throw const FormatException();
        }
        dados = decodificado;
      }
    } on FormatException {
      throw const ErroApi('O servidor retornou uma resposta invÃƒÂ¡lida.');
    }
    if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
      final mensagem = resposta.statusCode >= 500
          ? 'NÃƒÂ£o foi possÃƒÂ­vel concluir agora. Tente novamente.'
          : (dados['message'] ??
                    (dados['error'] is String ? dados['error'] : null) ??
                    'Confira os dados informados.')
                .toString();
      throw ErroApi(mensagem, status: resposta.statusCode);
    }
    if (autenticada && _sessao.token == tokenEnviado) {
      final cabecalho =
          resposta.headers['x-access-token'] ??
          resposta.headers['authorization'];
      if (cabecalho != null) {
        final renovado = cabecalho.replaceFirst(
          RegExp(r'^Bearer\s+', caseSensitive: false),
          '',
        );
        try {
          await _sessao.definirToken(renovado);
        } on FormatException {
          /* Manter token atual. */
        }
      }
    }
    return dados;
  }

  List<Map<String, dynamic>> _lista(Map<String, dynamic> resposta) {
    final lista = resposta['data'];
    if (lista is! List) throw const ErroApi('A lista recebida ÃƒÂ© invÃƒÂ¡lida.');
    return lista.map((item) {
      if (item is! Map) {
        throw const ErroApi('Um registro recebido ÃƒÂ© invÃƒÂ¡lido.');
      }
      return Map<String, dynamic>.from(item);
    }).toList();
  }

  Map<String, dynamic> _registro(Map<String, dynamic> resposta) {
    if (resposta['data'] is! Map) {
      throw const ErroApi('O registro recebido ÃƒÂ© invÃƒÂ¡lido.');
    }
    return Map<String, dynamic>.from(resposta['data'] as Map);
  }

  Future<String> login(String email, String password) async {
    final dados = await _requisicao(
      'POST',
      '/auth/login',
      autenticada: false,
      corpo: {'email': email.trim(), 'senha': password},
    );
    final jwt = dados['token'];
    if (jwt is! String) {
      throw const ErroApi('O servidor nÃƒÂ£o retornou a sessÃƒÂ£o.');
    }
    try {
      await _sessao.definirToken(jwt);
    } on FormatException {
      throw const ErroApi('O servidor retornou uma sessÃƒÂ£o invÃƒÂ¡lida.');
    }
    if (!_sessao.autenticada) {
      throw const ErroApi('A sessÃƒÂ£o recebida jÃƒÂ¡ expirou.');
    }
    return jwt;
  }

  Future<void> register(String nome, String email, String senha) async {
    await _requisicao(
      'POST',
      '/usuarios',
      autenticada: false,
      corpo: {'nome': nome.trim(), 'email': email.trim(), 'hash_senha': senha},
    );
  }

  Future<void> updateUsuario({
    String? nome,
    String? email,
    String? senha,
  }) async {
    final id = _sessao.idUsuario;
    if (id == null) throw const ErroApi('FaÃƒÂ§a login novamente.', status: 401);
    await _requisicao(
      'PUT',
      '/usuarios/$id',
      corpo: {
        if (nome != null && nome.trim().isNotEmpty) 'nome': nome.trim(),
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
        if (senha != null && senha.isNotEmpty) 'senha': senha,
      },
    );
  }

  Future<Map<String, dynamic>> getUsuario() async {
    final id = _sessao.idUsuario;
    if (id == null) throw const ErroApi('FaÃƒÂ§a login novamente.', status: 401);
    return _registro(await _requisicao('GET', '/usuarios/$id'));
  }

  Future<Map<String, dynamic>> fetchUserData(String token) async {
    if (token != _sessao.token) {
      throw const ErroApi('SessÃƒÂ£o invÃƒÂ¡lida.', status: 401);
    }
    return getUsuario();
  }

  Future<List<Map<String, dynamic>>> listEstabelecimentos() async => _lista(
    await _requisicao('GET', '/estabelecimentos'),
  ).where((item) => item['ativo'] != false).toList();
  Future<Map<String, dynamic>> getEstabelecimento(int id) async =>
      _registro(await _requisicao('GET', '/estabelecimentos/$id'));
  Future<Map<String, dynamic>> getAvaliacoesEstabelecimento(
    int id, {
    int pagina = 1,
  }) async => _registro(
    await _requisicao(
      'GET',
      '/estabelecimentos/$id/avaliacoes',
      parametros: {'pagina': '$pagina'},
    ),
  );
  Future<List<Map<String, dynamic>>> listMinhasAvaliacoes({
    int limit = 100,
  }) async => _lista(
    await _requisicao(
      'GET',
      '/interacoes/me/avaliacoes',
      parametros: {'limit': '$limit'},
    ),
  );
  Future<List<Map<String, dynamic>>> listMinhasInteracoes(int id) async =>
      _lista(
        await _requisicao(
          'GET',
          '/interacoes/me',
          parametros: {'id_estabelecimento': '$id', 'limit': '300'},
        ),
      );

  Future<Map<String, dynamic>> listNotificacoes({int? antes}) async =>
      _registro(
        await _requisicao(
          'GET',
          '/notificacoes',
          parametros: {if (antes != null) 'antes': '$antes'},
        ),
      );

  Future<void> marcarNotificacaoLida(int id) async {
    await _requisicao('PATCH', '/notificacoes/$id/lida');
  }

  Future<void> publicarComentario(int id, String comentario) async {
    final classificacao = _registro(
      await _requisicao(
        'POST',
        '/classificacoes',
        corpo: {'id_usuario': _sessao.idUsuario},
      ),
    );
    await _requisicao(
      'POST',
      '/classificacoes-estabelecimentos',
      corpo: {
        'id_classificacao': classificacao['id_classificacao'],
        'id_estabelecimento': id,
        'comentario': comentario.trim(),
      },
    );
  }

  Future<Map<String, dynamic>> curtirComentario(
    int id,
    int classificacao,
  ) async => _registro(
    await _requisicao(
      'PUT',
      '/estabelecimentos/$id/comentarios/$classificacao/curtida',
    ),
  );

  Future<Map<String, dynamic>> createInteracao({
    required int idEstabelecimento,
    required String tipoEvento,
    double? valor,
    String? origem,
  }) async => _registro(
    await _requisicao(
      'POST',
      '/interacoes',
      corpo: {
        'id_estabelecimento': idEstabelecimento,
        'tipo_evento': tipoEvento,
        'valor': ?valor,
        if (origem != null && origem.isNotEmpty) 'origem': origem,
      },
    ),
  );
  Future<List<Map<String, dynamic>>> getSugestoesAutomaticas() async =>
      _lista(await _requisicao('GET', '/recomendacoes/automaticas'));
  Future<List<Map<String, dynamic>>> recomendar({
    required Map<String, dynamic> respostas,
    int k = 20,
    int? agoraMin,
  }) async => _lista(
    await _requisicao(
      'POST',
      '/recomendacoes',
      corpo: {'respostas': respostas, 'agora_min': agoraMin, 'k': k},
    ),
  );
  Future<List<Map<String, dynamic>>> getQuestionarioRecomendacao() async {
    final resposta = await _requisicao('GET', '/recomendacoes/modelo');
    final modelo = resposta['data'];
    if (modelo is! Map || modelo['questionario'] is! List) {
      throw const ErroApi('O questionÃƒÂ¡rio de recomendaÃƒÂ§ÃƒÂ£o ÃƒÂ© invÃƒÂ¡lido.');
    }
    return (modelo['questionario'] as List)
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}
