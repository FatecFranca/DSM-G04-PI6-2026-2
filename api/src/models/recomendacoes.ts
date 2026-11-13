import { existsSync, readFileSync } from "node:fs";
import { resolve } from "node:path";
import { prisma } from "../../lib/prisma";

type ItemModelo = {
  id: number; nome: string; tipo: string; tipos: string[]; faixa_preco: string;
  ambiente: string; publico: string[]; nota: number; qualidade: number;
  periodos: Record<string, number>; abre: string; fecha: string;
  abre_min: number; fecha_min: number; cluster?: number | string | null;
};
type ModeloRecomendacao = {
  questionario: { id: string; pergunta: string; tipo_resposta: string; obrigatoria: boolean; opcoes: { valor: string; rotulo: string }[] }[];
  faixa_preco_ordem: string[]; pesos: Record<string, number>;
  qualidade: { beta: Record<string, number> };
  diversidade: { delta: number };
  similaridade: { tipo: Record<string, Record<string, number>>; ambiente: Record<string, Record<string, number>> };
  rotulos_motivos: Record<string, Record<string, string>>;
  estabelecimentos: ItemModelo[]; algoritmo: { top_k_padrao: number };
};
type Respostas = Record<string, string | string[] | undefined>;
const grupos = ["tipo", "faixa_preco", "ambiente", "publico", "periodo"] as const;

function carregarModelo(): ModeloRecomendacao {
  const candidatos = [resolve(__dirname, "../../modelo_recomendacao.json"), resolve(__dirname, "../../../modelo_recomendacao.json")];
  const caminho = candidatos.find(existsSync);
  if (!caminho) throw new Error("Arquivo modelo_recomendacao.json não encontrado.");
  return JSON.parse(readFileSync(caminho, "utf8")) as ModeloRecomendacao;
}
export const modeloRecomendacao = carregarModelo();
export const obterQuestionarioRecomendacao = () => modeloRecomendacao.questionario;

function normalizarRespostas(respostas: Respostas) {
  const normalizadas: Record<string, string[]> = {};
  for (const grupo of grupos) {
    const valor = respostas[grupo];
    const valores = valor == null || valor === "" ? [] : Array.isArray(valor) ? valor : [valor];
    const unicos = [...new Set(valores)];
    const opcoes = modeloRecomendacao.questionario.find(q => q.id === grupo)?.opcoes.map(o => o.valor) ?? [];
    const invalidos = unicos.filter(item => typeof item !== "string" || !opcoes.includes(item));
    if (invalidos.length) throw new Error(`Valores inválidos para '${grupo}': ${invalidos.join(", ")}.`);
    if (unicos.length) normalizadas[grupo] = unicos;
  }
  const importancia = String(respostas.importancia_nota || "media");
  if (!(importancia in modeloRecomendacao.qualidade.beta)) throw new Error(`importancia_nota inválida: ${importancia}`);
  return { respostas: normalizadas, importancia };
}

function similaridade(grupo: string, selecao: string[], item: ItemModelo): number {
  if (grupo === "tipo") return Math.max(...selecao.flatMap(u => item.tipos.map(t => modeloRecomendacao.similaridade.tipo[u][t])));
  if (grupo === "faixa_preco") {
    const ordem = modeloRecomendacao.faixa_preco_ordem, n = ordem.length - 1, p = ordem.indexOf(item.faixa_preco);
    return Math.max(...selecao.map(u => 1 - Math.abs(ordem.indexOf(u) - p) / n));
  }
  if (grupo === "ambiente") return Math.max(...selecao.map(u => modeloRecomendacao.similaridade.ambiente[u][item.ambiente]));
  if (grupo === "publico") return item.publico.filter(p => selecao.includes(p)).length / selecao.length;
  if (grupo === "periodo") return selecao.filter(p => item.periodos[p]).length / selecao.length;
  throw new Error(`Grupo inválido: ${grupo}`);
}
function somaSequencial(valores: number[]) { let total = 0; for (const valor of valores) total += valor; return total; }
function abertoAgora(item: ItemModelo, minuto: number) {
  return (item.abre_min <= minuto && minuto < item.fecha_min) || (item.fecha_min > 1440 && item.abre_min <= minuto + 1440 && minuto + 1440 < item.fecha_min);
}
function arredondarPython(valor: number, casas: number) {
  const fator = 10 ** casas, escalado = valor * fator, base = Math.floor(escalado), fracao = escalado - base;
  if (fracao === 0.5) return (base % 2 === 0 ? base : base + 1) / fator;
  return Math.round(escalado) / fator;
}
type Candidato = { id: number; item: ItemModelo; score: number; qualidade: number; ajuste: number | null; componentes: Record<string, number>; cluster: number | string | null | undefined; periodo_ok: boolean; aberto: boolean | null };

export function recomendar(respostasUsuario: Respostas, k?: number, agoraMin: number | null = null, diversificar = true) {
  const { respostas, importancia } = normalizarRespostas(respostasUsuario);
  if (agoraMin !== null && (!Number.isInteger(agoraMin) || agoraMin < 0 || agoraMin > 1439)) throw new Error("agora_min deve estar entre 0 e 1439 ou ser null.");
  const quantidade = k || modeloRecomendacao.algoritmo.top_k_padrao;
  if (!Number.isInteger(quantidade) || quantidade < 1 || quantidade > modeloRecomendacao.estabelecimentos.length) throw new Error("k inválido.");
  const respondidos = grupos.filter(g => respostas[g]);
  const totalPesos = somaSequencial(respondidos.map(g => modeloRecomendacao.pesos[g]));
  const beta = modeloRecomendacao.qualidade.beta[importancia];
  const ranking: Candidato[] = modeloRecomendacao.estabelecimentos.map(item => {
    const componentes = Object.fromEntries(respondidos.map(g => [g, similaridade(g, respostas[g], item)]));
    const ajuste = totalPesos > 0 ? somaSequencial(respondidos.map(g => modeloRecomendacao.pesos[g] * componentes[g])) / totalPesos : null;
    const score = ajuste === null ? item.qualidade : (1 - beta) * ajuste + beta * item.qualidade;
    return { id: item.id, item, score, qualidade: item.qualidade, ajuste, componentes,
      cluster: item.cluster, periodo_ok: !componentes.periodo || componentes.periodo > 0,
      aberto: agoraMin === null ? null : abertoAgora(item, agoraMin) };
  }).sort((a, b) => b.score - a.score || b.qualidade - a.qualidade || a.id - b.id);
  const elegiveis = ranking.filter(c => c.periodo_ok && c.aberto !== false);
  const selecionados: Candidato[] = [];
  const restantes = [...elegiveis], contagem = new Map<Candidato["cluster"], number>();
  const delta = diversificar ? modeloRecomendacao.diversidade.delta : 0;
  while (restantes.length && selecionados.length < quantidade) {
    let melhorIndice = 0;
    for (let i = 1; i < restantes.length; i++) {
      const a = restantes[i], b = restantes[melhorIndice];
      const as = a.score - delta * (contagem.get(a.cluster) ?? 0), bs = b.score - delta * (contagem.get(b.cluster) ?? 0);
      if (as > bs || (as === bs && (a.qualidade > b.qualidade || (a.qualidade === b.qualidade && a.id < b.id)))) melhorIndice = i;
    }
    const [item] = restantes.splice(melhorIndice, 1); selecionados.push(item);
    contagem.set(item.cluster, (contagem.get(item.cluster) ?? 0) + 1);
  }
  const elegiveisIds = new Set(elegiveis.map(c => c.id));
  const fora = new Set<number>();
  if (selecionados.length < quantidade) for (const item of ranking) {
    if (elegiveisIds.has(item.id) || selecionados.length >= quantidade) continue;
    selecionados.push(item); fora.add(item.id);
  }
  return selecionados.map((c, indice) => {
    const motivos: string[] = [];
    for (const [grupo, valor] of Object.entries(c.componentes)) {
      if (valor >= 0.999) motivos.push(modeloRecomendacao.rotulos_motivos[grupo].exato);
      else if (grupo === "tipo" && valor >= 0.3) motivos.push(modeloRecomendacao.rotulos_motivos[grupo].parcial);
    }
    if (c.qualidade >= 0.8) motivos.push(modeloRecomendacao.rotulos_motivos.qualidade.exato);
    return { posicao: indice + 1, id: c.item.id, nome: c.item.nome, tipo: c.item.tipo,
      faixa_preco: c.item.faixa_preco, ambiente: c.item.ambiente, publico: c.item.publico,
      nota: c.item.nota, abre: c.item.abre, fecha: c.item.fecha,
      score: arredondarPython(c.score * 100, 1), compatibilidade: c.ajuste === null ? null : arredondarPython(c.ajuste * 100, 1),
      cluster: c.cluster, motivos, aberto_agora: c.aberto, fora_do_filtro: fora.has(c.id) };
  });
}

function normalizarNome(nome: string) { return nome.normalize("NFD").replace(/[\u0300-\u036f]/g, "").trim().toLocaleLowerCase("pt-BR"); }
/** Associa itens do artefato minerado aos estabelecimentos cadastrados sem duplicar seus dados. */
export async function recomendarEstabelecimentos(respostas: Respostas, k?: number, agoraMin: number | null = null) {
  const ranking = recomendar(respostas, k, agoraMin);
  const nomes = new Set(ranking.map(item => normalizarNome(item.nome)));
  const registros = await prisma.tb_estabelecimento.findMany({ where: { ativo: true }, select: { id_estabelecimento: true, nome: true, avaliacao: true, cidade: true, bairro: true } });
  const registroPorNome = new Map(registros.filter(item => nomes.has(normalizarNome(item.nome))).map(item => [normalizarNome(item.nome), item]));
  return ranking.flatMap(item => {
    const registro = registroPorNome.get(normalizarNome(item.nome));
    return registro === undefined ? [] : [{ ...item, id_estabelecimento: registro.id_estabelecimento,
      avaliacao: Number(registro.avaliacao), cidade: registro.cidade, bairro: registro.bairro }];
  });
}
