import '../models/floter_models.dart';
import 'api.dart';

class FloterService {
  FloterService({ApiService? api}) : _api = api ?? ApiService();
  final ApiService _api;
  Future<List<SugestaoFloter>> analisarPreferencias(
    PreferenciasFloter preferencias,
  ) async {
    // As preferencias foram salvas pelo questionario e sao lidas pelo ranking da API.
    final locais = await _api.getRecomendacoes(limit: 30, forceRefresh: true);
    return locais.map(SugestaoFloter.fromJson).toList();
  }
}
