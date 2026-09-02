enum CategoriaComida { lanches('Lanches'), pizza('Pizza'), comidaCaseira('Marmita/comida caseira'), massas('Massas'), japonesa('Japonesa'), doces('Doces'), saudavel('Saudável'), outra('Outra opção'); const CategoriaComida(this.descricao); final String descricao; }
enum PreferenciaSabor { salgado('Salgado'), doce('Doce'), apimentado('Apimentado'), leve('Leve'), indiferente('Indiferente'); const PreferenciaSabor(this.descricao); final String descricao; }
enum FaixaPreco { economico('Econômico'), medio('Médio'), elaborado('Mais elaborado'); const FaixaPreco(this.descricao); final String descricao; }
enum QuantidadePessoas { uma('1 pessoa'), duas('2 pessoas'), tresOuMais('3 ou mais pessoas'); const QuantidadePessoas(this.descricao); final String descricao; }
enum RestricaoAlimentar { nenhuma('Nenhuma'), vegetariana('Vegetariana'), vegana('Vegana'), semLactose('Sem lactose'), semGluten('Sem glúten'), outra('Outra'); const RestricaoAlimentar(this.descricao); final String descricao; }
enum ModalidadeConsumo { entrega('Entrega'), retirada('Retirada no local'), restaurante('Comer no restaurante'); const ModalidadeConsumo(this.descricao); final String descricao; }

class PreferenciasFloter {
  const PreferenciasFloter({required this.categoria, required this.sabor, required this.faixaPreco, required this.quantidadePessoas, required this.restricaoAlimentar, required this.modalidadeConsumo, this.observacao});
  final CategoriaComida categoria;
  final PreferenciaSabor sabor;
  final FaixaPreco faixaPreco;
  final QuantidadePessoas quantidadePessoas;
  final RestricaoAlimentar restricaoAlimentar;
  final ModalidadeConsumo modalidadeConsumo;
  final String? observacao;
}

class SugestaoFloter {
  const SugestaoFloter({required this.nome, required this.estabelecimento, required this.categoria, required this.faixaPreco, required this.imagemUrl, required this.modalidadesDisponiveis, this.restricoesAtendidas = const []});
  final String nome;
  final String estabelecimento;
  final CategoriaComida categoria;
  final FaixaPreco faixaPreco;
  final String imagemUrl;
  final List<ModalidadeConsumo> modalidadesDisponiveis;
  final List<RestricaoAlimentar> restricoesAtendidas;
}
