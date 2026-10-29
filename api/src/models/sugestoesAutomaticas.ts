import { Prisma } from "../generated/prisma/client";
import { prisma } from "../../lib/prisma";
import { listCandidateEstabelecimentos, rankFallbackForUser } from "./recomendacoes";
import { RecomendacoesQuerySchema } from "../types/recomendacao";

export const VERSAO_SUGESTOES = "sugestoes-automaticas-v1";

/** Executado pelo consumidor, na mesma transacao do controle de duplicidade. */
export async function gerarSugestoesAutomaticas(db: Prisma.TransactionClient, idUsuario: number, idEvento: string) {
  // Serializa entregas diferentes para a mesma pessoa; usa o historico atual, mesmo fora de ordem.
  await db.$queryRaw`SELECT id_usuario FROM tb_usuario WHERE id_usuario = ${idUsuario} FOR UPDATE`;
  const usuario = await db.tb_usuario.findUnique({ where: { id_usuario: idUsuario }, select: { ativo: true } });
  if (!usuario?.ativo) return;
  const query = RecomendacoesQuerySchema.parse({ limit: 10 });
  const [candidatos, interacoes, classificacoes] = await Promise.all([
    listCandidateEstabelecimentos(query, db),
    db.tb_interacao_usuario_estabelecimento.findMany({
      where: { id_usuario: idUsuario, tipo_evento: { in: ["rating", "like", "dislike", "neutral"] } },
      distinct: ["id_estabelecimento"], select: { id_estabelecimento: true },
    }),
    db.tb_classificacao_estabelecimento.findMany({
      where: { classificacao: { id_usuario: idUsuario }, nota: { not: null } },
      distinct: ["id_estabelecimento"], select: { id_estabelecimento: true },
    }),
  ]);
  const conhecidos = new Set([...interacoes, ...classificacoes].map(item => item.id_estabelecimento));
  const ranking = await rankFallbackForUser(idUsuario, candidatos.filter(item => !conhecidos.has(item.id_estabelecimento)), 10, db);
  await db.tb_usuario_feature_snapshot.deleteMany({ where: { id_usuario: idUsuario, model_version: VERSAO_SUGESTOES } });
  await db.tb_usuario_feature_snapshot.create({ data: {
    id_usuario: idUsuario, model_version: VERSAO_SUGESTOES,
    feature_json: { id_evento: idEvento, ranking },
  } });
  // Registra o algoritmo realmente utilizado, sem simular treinamento de ML.
  await db.tb_modelo_recomendacao.upsert({
    where: { versao: VERSAO_SUGESTOES },
    create: { versao: VERSAO_SUGESTOES, algoritmo: "ranking-por-regras", status: "ready" }, update: {},
  });
  const chave = { id_usuario: idUsuario, model_version: VERSAO_SUGESTOES, context_hash: "automaticas-v1" };
  await db.tb_recomendacao_cache.upsert({
    where: { id_usuario_model_version_context_hash: chave },
    create: { ...chave, ranking_json: ranking, expires_at: new Date(Date.now() + 10 * 60 * 1000) },
    update: { ranking_json: ranking, expires_at: new Date(Date.now() + 10 * 60 * 1000), created_at: new Date() },
  });
}

export async function listarSugestoesAutomaticas(idUsuario: number) {
  const registro = await prisma.tb_usuario_feature_snapshot.findFirst({
    where: { id_usuario: idUsuario, model_version: VERSAO_SUGESTOES },
    orderBy: [{ created_at: "desc" }, { id_snapshot: "desc" }],
  });
  const conteudo = registro?.feature_json as { ranking?: Prisma.JsonArray } | undefined;
  const ranking = conteudo?.ranking ?? [];
  const ids = ranking.map(item => Number((item as Prisma.JsonObject).id_estabelecimento));
  const ativos = await prisma.tb_estabelecimento.findMany({ where: { id_estabelecimento: { in: ids }, ativo: true }, select: { id_estabelecimento: true } });
  const permitidos = new Set(ativos.map(item => item.id_estabelecimento));
  return { atualizado_em: registro?.created_at ?? null,
    sugestoes: ranking.filter(item => permitidos.has(Number((item as Prisma.JsonObject).id_estabelecimento))) };
}
