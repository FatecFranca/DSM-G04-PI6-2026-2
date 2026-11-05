/** Categorias especificas; restaurante generico nao comprova um tipo de cozinha. */
export const normalizar = (valor: string) => valor.normalize("NFD").replace(/[\u0300-\u036f]/g, "").trim().toLowerCase();
export function categoriasDoLocal(local: { nome: string; tipo: string; tags?: unknown }): string[] {
  const texto = normalizar(local.tipo + " " + local.nome);
  const categorias = new Set<string>();
  if (/pizza|pizzaria/.test(texto)) categorias.add("pizza");
  if (/hamburg|burguer|burger|lanche|pastel|hot dog/.test(texto)) categorias.add("lanches");
  if (/japonesa|sushi|japa|wasabi|wok/.test(texto) || /^(konomi|daniel san|saiko nani|cobra kai|sumo day)$/i.test(local.nome)) categorias.add("japonesa");
  if (/massas|italiana|cantina|macarrao/.test(texto)) categorias.add("massas");
  if (/comida caseira|marmita|mineiro|brasileira/.test(texto)) categorias.add("marmita/comida caseira");
  if (/doce|confeitaria|sorvete|cake/.test(texto)) categorias.add("doces");
  if (/saudavel|salada|natural|vegano|vegetariano/.test(texto)) categorias.add("saudavel");
  if (Array.isArray(local.tags)) for (const tag of local.tags) if (typeof tag === "string") categorias.add(normalizar(tag));
  return [...categorias];
}
export function categoriasSalvas(valor: unknown): string[] {
  return (Array.isArray(valor) ? valor : typeof valor === "string" ? [valor] : [])
    .filter((item): item is string => typeof item === "string").map(normalizar);
}
export function correspondeCategoria(local: { nome: string; tipo: string; tags?: unknown }, categorias: string[]): boolean {
  return categorias.length === 0 || categorias.includes("outra opcao") || categorias.some(c => categoriasDoLocal(local).includes(c));
}
