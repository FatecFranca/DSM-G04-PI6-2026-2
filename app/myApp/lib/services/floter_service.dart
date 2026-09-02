import '../models/floter_models.dart';

class FloterService {
  Future<List<SugestaoFloter>> analisarPreferencias(PreferenciasFloter preferencias) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return _sugestoesMockadas.where((sugestao) {
      final categoriaCompativel = preferencias.categoria == CategoriaComida.outra || sugestao.categoria == preferencias.categoria;
      final precoCompativel = sugestao.faixaPreco == preferencias.faixaPreco;
      final modalidadeCompativel = sugestao.modalidadesDisponiveis.contains(preferencias.modalidadeConsumo);
      final restricaoCompativel = preferencias.restricaoAlimentar == RestricaoAlimentar.nenhuma || preferencias.restricaoAlimentar == RestricaoAlimentar.outra || sugestao.restricoesAtendidas.contains(preferencias.restricaoAlimentar);
      return categoriaCompativel && precoCompativel && modalidadeCompativel && restricaoCompativel;
    }).toList();
  }

  static const List<SugestaoFloter> _sugestoesMockadas = [
    SugestaoFloter(nome: 'Burger artesanal', estabelecimento: 'Urban Burger', categoria: CategoriaComida.lanches, faixaPreco: FaixaPreco.medio, imagemUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=900', modalidadesDisponiveis: [ModalidadeConsumo.entrega, ModalidadeConsumo.retirada]),
    SugestaoFloter(nome: 'Pizza margherita', estabelecimento: 'Forno da Vila', categoria: CategoriaComida.pizza, faixaPreco: FaixaPreco.medio, imagemUrl: 'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=900', modalidadesDisponiveis: ModalidadeConsumo.values, restricoesAtendidas: [RestricaoAlimentar.vegetariana]),
    SugestaoFloter(nome: 'Bowl tropical', estabelecimento: 'Verde & Leve', categoria: CategoriaComida.saudavel, faixaPreco: FaixaPreco.economico, imagemUrl: 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=900', modalidadesDisponiveis: ModalidadeConsumo.values, restricoesAtendidas: [RestricaoAlimentar.vegetariana, RestricaoAlimentar.vegana, RestricaoAlimentar.semLactose, RestricaoAlimentar.semGluten]),
    SugestaoFloter(nome: 'Combinado especial', estabelecimento: 'Sakura Sushi', categoria: CategoriaComida.japonesa, faixaPreco: FaixaPreco.elaborado, imagemUrl: 'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=900', modalidadesDisponiveis: [ModalidadeConsumo.entrega, ModalidadeConsumo.restaurante], restricoesAtendidas: [RestricaoAlimentar.semLactose]),
    SugestaoFloter(nome: 'Lasanha da casa', estabelecimento: 'Cantina Família', categoria: CategoriaComida.massas, faixaPreco: FaixaPreco.medio, imagemUrl: 'https://images.unsplash.com/photo-1574894709920-11b28e7367e3?w=900', modalidadesDisponiveis: [ModalidadeConsumo.retirada, ModalidadeConsumo.restaurante]),
    SugestaoFloter(nome: 'Prato feito do dia', estabelecimento: 'Tempero de Casa', categoria: CategoriaComida.comidaCaseira, faixaPreco: FaixaPreco.economico, imagemUrl: 'https://images.unsplash.com/photo-1547592180-85f173990554?w=900', modalidadesDisponiveis: ModalidadeConsumo.values),
  ];
}
