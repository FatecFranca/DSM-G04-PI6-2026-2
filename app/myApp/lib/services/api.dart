// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
// import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static const String _baseUrl = 'http://localhost:8080';

  static String? token;
  static int? userId;

  static void logout() {
    token = null;
    userId = null;
  }

  static Map<String, dynamic> _decodeJwtPayload(String jwt) {
    final payload = jwt.split('.')[1];
    final normalized = base64Url.normalize(payload);
    final decoded = utf8.decode(base64Url.decode(normalized));
    return jsonDecode(decoded) as Map<String, dynamic>;
  }

  Future<String> login(String email, String password) async {
    final url = Uri.parse('$_baseUrl/auth/login');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'senha': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final jwt = data['token'] as String?;
      if (jwt == null || jwt.isEmpty) {
        throw Exception('Token não encontrado na resposta.');
      }
      token = jwt;
      userId = _decodeJwtPayload(jwt)['id_usuario'] as int?;
      return jwt;
    } else if (response.statusCode == 401) {
      throw Exception('E-mail ou senha incorretos.');
    } else {
      throw Exception('Erro do servidor (${response.statusCode}).');
    }
  }

  Future<void> register(String nome, String email, String hashSenha) async {
    final url = Uri.parse('$_baseUrl/usuarios');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'nome': nome, 'email': email, 'hash_senha': hashSenha}),
    );

    if (response.statusCode == 201) {
      return;
    } else {
      throw Exception('Erro ${response.statusCode}: ${response.body}');
    }
  }

  Future<void> updateUsuario({String? nome, String? email, String? senha}) async {
    if (userId == null || token == null) {
      throw Exception('Usuário não autenticado.');
    }

    final url = Uri.parse('$_baseUrl/usuarios/$userId');
    final body = <String, String>{};
    if (nome != null && nome.isNotEmpty) body['nome'] = nome;
    if (email != null && email.isNotEmpty) body['email'] = email;
    if (senha != null && senha.isNotEmpty) body['senha'] = senha;

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 401) {
      throw Exception('Sessão expirada. Faça login novamente.');
    } else {
      throw Exception('Erro ${response.statusCode}: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getUsuario() async {
    if (userId == null || token == null) {
      throw Exception('Usuário não autenticado.');
    }

    final url = Uri.parse('$_baseUrl/usuarios/$userId');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['data'] as Map<String, dynamic>;
    } else if (response.statusCode == 401) {
      throw Exception('Sessão expirada. Faça login novamente.');
    } else {
      throw Exception('Erro ao buscar dados do usuário (${response.statusCode}).');
    }
  }

  Future<Map<String, dynamic>> fetchUserData(String token) async {
    final url = Uri.parse('$_baseUrl/user');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 401) {
      throw Exception('Sessão expirada. Faça login novamente.');
    } else {
      throw Exception('Erro ao buscar dados do usuário (${response.statusCode}).');
    }
  }

  Map<String, String> _authHeaders() {
    if (token == null) {
      throw Exception('Usuário não autenticado.');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<Map<String, dynamic>>> listEstabelecimentos() async {
    final url = Uri.parse('$_baseUrl/estabelecimentos');
    final response = await http.get(url, headers: _authHeaders());

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final data = decoded['data'] as List<dynamic>? ?? const <dynamic>[];
      return data
          .whereType<Map<String, dynamic>>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } else if (response.statusCode == 401) {
      throw Exception('Sessão expirada. Faça login novamente.');
    } else {
      throw Exception('Erro ao listar estabelecimentos (${response.statusCode}).');
    }
  }

  Future<Map<String, dynamic>> createInteracao({
    required int idEstabelecimento,
    required String tipoEvento,
    double? valor,
    String? origem,
  }) async {
    final url = Uri.parse('$_baseUrl/interacoes');
    final body = <String, dynamic>{
      'id_estabelecimento': idEstabelecimento,
      'tipo_evento': tipoEvento,
    };
    if (valor != null) body['valor'] = valor;
    if (origem != null && origem.isNotEmpty) body['origem'] = origem;

    final response = await http.post(
      url,
      headers: _authHeaders(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return Map<String, dynamic>.from(decoded['data'] ?? decoded);
    } else if (response.statusCode == 401) {
      throw Exception('Sessão expirada. Faça login novamente.');
    } else {
      throw Exception('Erro ao registrar interação (${response.statusCode}): ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getIaSugestoes({int limit = 20}) async {
    final url = Uri.parse('$_baseUrl/recomendacoes/ia-sugestoes?limit=$limit');
    final response = await http.get(url, headers: _authHeaders());

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final data = decoded['data'] as List<dynamic>? ?? const <dynamic>[];
      return data
          .whereType<Map<String, dynamic>>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } else if (response.statusCode == 401) {
      throw Exception('Sessão expirada. Faça login novamente.');
    } else {
      throw Exception('Erro ao buscar sugestões da IA (${response.statusCode}).');
    }
  }

  Future<List<Map<String, dynamic>>> getRecomendacoes({
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    final params = <String, String>{
      'limit': '$limit',
      if (forceRefresh) 'force_refresh': 'true',
    };
    final url = Uri.parse('$_baseUrl/recomendacoes').replace(queryParameters: params);
    final response = await http.get(url, headers: _authHeaders());

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final data = decoded['data'] as List<dynamic>? ?? const <dynamic>[];
      return data
          .whereType<Map<String, dynamic>>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } else if (response.statusCode == 401) {
      throw Exception('Sessão expirada. Faça login novamente.');
    } else {
      throw Exception('Erro ao buscar recomendações (${response.statusCode}).');
    }
  }
}