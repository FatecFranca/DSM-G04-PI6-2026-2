import crypto from "crypto";
import { Prisma } from "../generated/prisma/client";
import { prisma } from "../../lib/prisma";
import { RecomendacoesQueryDTO } from "../types/recomendacao";

type CandidateEstabelecimento = {
  id_estabelecimento: number;
  nome: string;
  tipo: string;
  faixa_preco: string;
  ambiente: string;
  avaliacao: unknown;
  cidade: string | null;
  bairro: string | null;
};

const CACHE_TTL_MINUTES = 10;

const normalizeText = (value?: string | null) => (value ?? "").trim().toLowerCase();

export function buildContextHash(idUsuario: number, query: RecomendacoesQueryDTO) {
  const payload = JSON.stringify({
    idUsuario,
    tipo: normalizeText(query.tipo),
    faixa_preco: normalizeText(query.faixa_preco),
    ambiente: normalizeText(query.ambiente),
    cidade: normalizeText(query.cidade),
    bairro: normalizeText(query.bairro),
    limit: query.limit,
  });

  return crypto.createHash("sha256").update(payload).digest("hex");
}

export async function getLatestReadyModelVersion() {
  const model = await prisma.tb_modelo_recomendacao.findFirst({
    where: { status: "ready" },
    orderBy: [{ trained_at: "desc" }, { created_at: "desc" }],
    select: { versao: true },
  });

  return model?.versao ?? "fallback-v1";
}

export async function getCachedRecommendations(idUsuario: number, modelVersion: string, contextHash: string) {
  const cache = await prisma.tb_recomendacao_cache.findUnique({
    where: {
      id_usuario_model_version_context_hash: {
        id_usuario: idUsuario,
        model_version: modelVersion,
        context_hash: contextHash,
      },
    },
  });

  if (!cache || cache.expires_at <= new Date()) {
    return null;
  }

  const ranking = Array.isArray(cache.ranking_json) ? cache.ranking_json : [];
  return ranking;
}

export async function upsertRecommendationsCache(
  idUsuario: number,
  modelVersion: string,
  contextHash: string,
  ranking: Prisma.InputJsonValue
) {
  const expiresAt = new Date(Date.now() + CACHE_TTL_MINUTES * 60 * 1000);

  await prisma.tb_recomendacao_cache.upsert({
    where: {
      id_usuario_model_version_context_hash: {
        id_usuario: idUsuario,
        model_version: modelVersion,
        context_hash: contextHash,
      },
    },
    create: {
      id_usuario: idUsuario,
      model_version: modelVersion,
      context_hash: contextHash,
      ranking_json: ranking,
      expires_at: expiresAt,
    },
    update: {
      ranking_json: ranking,
      expires_at: expiresAt,
    },
  });
}

export function listCandidateEstabelecimentos(query: RecomendacoesQueryDTO) {
  return prisma.tb_estabelecimento.findMany({
    where: {
      ativo: true,
      tipo: query.tipo,
      faixa_preco: query.faixa_preco,
      ambiente: query.ambiente,
      cidade: query.cidade,
      bairro: query.bairro,
    },
    select: {
      id_estabelecimento: true,
      nome: true,
      tipo: true,
      faixa_preco: true,
      ambiente: true,
      avaliacao: true,
      cidade: true,
      bairro: true,
    },
    take: 250,
  });
}

export async function rankFallbackForUser(
  idUsuario: number,
  candidates: CandidateEstabelecimento[],
  limit: number
) {
  const userInteractions = await prisma.tb_interacao_usuario_estabelecimento.findMany({
    where: { id_usuario: idUsuario },
    orderBy: { created_at: "desc" },
    take: 300,
    include: {
      estabelecimento: {
        select: {
          tipo: true,
          faixa_preco: true,
          ambiente: true,
        },
      },
    },
  });

  const typeWeights = new Map<string, number>();
  const priceWeights = new Map<string, number>();
  const environmentWeights = new Map<string, number>();

  for (const interaction of userInteractions) {
    // Regra de negocio: aprendizado baseado apenas em like/dislike.
    const score =
      interaction.tipo_evento === "like"
        ? 3
        : interaction.tipo_evento === "dislike"
          ? -3
          : 0;

    if (score === 0) continue;

    const tipo = normalizeText(interaction.estabelecimento.tipo);
    const faixaPreco = normalizeText(interaction.estabelecimento.faixa_preco);
    const ambiente = normalizeText(interaction.estabelecimento.ambiente);

    typeWeights.set(tipo, (typeWeights.get(tipo) ?? 0) + score);
    priceWeights.set(faixaPreco, (priceWeights.get(faixaPreco) ?? 0) + score);
    environmentWeights.set(ambiente, (environmentWeights.get(ambiente) ?? 0) + score);
  }

  const ranked = candidates
    .map((item) => {
      const tipo = normalizeText(item.tipo);
      const faixaPreco = normalizeText(item.faixa_preco);
      const ambiente = normalizeText(item.ambiente);
      const avaliacao = Number(item.avaliacao ?? 0);

      let score = Math.max(0, Math.min(avaliacao, 5)) * 0.4;
      const motivos: string[] = ["avaliacao_publica"];

      const typeScore = typeWeights.get(tipo) ?? 0;
      if (typeScore > 0) {
        score += Math.min(typeScore, 10) * 0.35;
        motivos.push("preferencia_por_tipo");
      } else if (typeScore < 0) {
        score += Math.max(typeScore, -10) * 0.35;
        motivos.push("evita_tipo");
      }

      const priceScore = priceWeights.get(faixaPreco) ?? 0;
      if (priceScore > 0) {
        score += Math.min(priceScore, 10) * 0.25;
        motivos.push("preferencia_por_faixa_preco");
      } else if (priceScore < 0) {
        score += Math.max(priceScore, -10) * 0.25;
        motivos.push("evita_faixa_preco");
      }

      const environmentScore = environmentWeights.get(ambiente) ?? 0;
      if (environmentScore > 0) {
        score += Math.min(environmentScore, 10) * 0.2;
        motivos.push("preferencia_por_ambiente");
      } else if (environmentScore < 0) {
        score += Math.max(environmentScore, -10) * 0.2;
        motivos.push("evita_ambiente");
      }

      return {
        id_estabelecimento: item.id_estabelecimento,
        nome: item.nome,
        tipo: item.tipo,
        faixa_preco: item.faixa_preco,
        ambiente: item.ambiente,
        cidade: item.cidade,
        bairro: item.bairro,
        score: Number(score.toFixed(4)),
        motivos,
      };
    })
    .sort((a, b) => b.score - a.score)
    .slice(0, limit);

  return ranked;
}

type SuggestionItem = {
  id_estabelecimento: number;
  nome: string;
  tipo: string;
  faixa_preco: string;
  ambiente: string;
  score: number;
  baseado_em: string[];
};

type LikedPlace = {
  id_estabelecimento: number;
  nome: string;
  tipo: string;
  faixa_preco: string;
  ambiente: string;
  created_at: Date;
};

function splitTipoVariants(tipo: string) {
  return tipo
    .split(/[/,]/)
    .map((part) => part.trim())
    .filter(Boolean)
    .map((part) => normalizeText(part));
}

function tipoOverlapScore(candidateTipo: string, likedTipo: string) {
  const cParts = splitTipoVariants(candidateTipo);
  const lParts = splitTipoVariants(likedTipo);
  if (cParts.length === 0 || lParts.length === 0) return 0;

  let best = 0;
  for (const c of cParts) {
    for (const l of lParts) {
      if (c === l) best = Math.max(best, 1);
      else if (c.includes(l) || l.includes(c)) best = Math.max(best, 0.75);
    }
  }

  const setL = new Set(lParts);
  for (const c of cParts) {
    if (setL.has(c)) best = Math.max(best, 1);
  }
  return best;
}

/** Semelhança 0–1 entre um candidato e um estabelecimento que o usuário curtiu. */
function similarityToLiked(candidate: { tipo: string; faixa_preco: string; ambiente: string }, liked: LikedPlace) {
  const faixaC = normalizeText(candidate.faixa_preco);
  const ambienteC = normalizeText(candidate.ambiente);

  const faixaL = normalizeText(liked.faixa_preco);
  const ambienteL = normalizeText(liked.ambiente);

  const tipoS = tipoOverlapScore(candidate.tipo, liked.tipo);
  const faixaS = faixaC === faixaL ? 1 : 0;
  const ambienteS = ambienteC === ambienteL ? 1 : 0;

  return 0.45 * tipoS + 0.3 * faixaS + 0.25 * ambienteS;
}

type ScoredSuggestion = SuggestionItem & {
  primary_like_id: number;
};

/** Intercala sugestoes ligadas a likes diferentes para refletir gosto variado. */
function diversifyByTasteRoundRobin(
  limit: number,
  likedOrderIds: number[],
  allScored: ScoredSuggestion[],
): Omit<ScoredSuggestion, "primary_like_id">[] {
  const byPrimary = new Map<number, ScoredSuggestion[]>();
  for (const item of allScored) {
    const bucket = byPrimary.get(item.primary_like_id) ?? [];
    bucket.push(item);
    byPrimary.set(item.primary_like_id, bucket);
  }

  for (const arr of byPrimary.values()) arr.sort((a, b) => b.score - a.score);

  const preferenceOrder =
    likedOrderIds.length > 0
      ? likedOrderIds.filter((id) => byPrimary.has(id))
      : [...byPrimary.keys()];

  const picked: ScoredSuggestion[] = [];
  const usedCandidateIds = new Set<number>();
  const nextIndexByLike = new Map<number, number>();

  let rounds = 0;
  while (picked.length < limit && rounds < 2000) {
    rounds += 1;
    let addedThisRound = false;

    for (const likeId of preferenceOrder) {
      if (picked.length >= limit) break;
      const queue = byPrimary.get(likeId) ?? [];
      let index = nextIndexByLike.get(likeId) ?? 0;

      while (index < queue.length) {
        const candidate = queue[index];
        index += 1;
        nextIndexByLike.set(likeId, index);

        if (usedCandidateIds.has(candidate.id_estabelecimento)) continue;

        usedCandidateIds.add(candidate.id_estabelecimento);
        picked.push(candidate);
        addedThisRound = true;
        break;
      }
    }

    if (!addedThisRound) break;
  }

  if (picked.length < limit) {
    for (const item of allScored) {
      if (picked.length >= limit) break;
      if (usedCandidateIds.has(item.id_estabelecimento)) continue;
      usedCandidateIds.add(item.id_estabelecimento);
      picked.push(item);
    }
  }

  return picked.map(({ primary_like_id: _omit, ...rest }) => rest);
}

export async function listAiSuggestionsFromLikes(idUsuario: number, limit: number) {
  const interactions = await prisma.tb_interacao_usuario_estabelecimento.findMany({
    where: { id_usuario: idUsuario },
    orderBy: { created_at: "desc" },
    take: 500,
    include: {
      estabelecimento: {
        select: {
          id_estabelecimento: true,
          nome: true,
          tipo: true,
          faixa_preco: true,
          ambiente: true,
        },
      },
    },
  });

  const latestByPlace = new Map<number, (typeof interactions)[number]>();
  for (const interaction of interactions) {
    if (!latestByPlace.has(interaction.id_estabelecimento)) {
      latestByPlace.set(interaction.id_estabelecimento, interaction);
    }
  }

  const likedInteractions = [...latestByPlace.values()].filter((item) => item.tipo_evento === "like");
  if (likedInteractions.length === 0) return [];

  const likedSortedDesc = [...likedInteractions].sort(
    (a, b) => b.created_at.getTime() - a.created_at.getTime(),
  );

  const likedPlaces: LikedPlace[] = likedSortedDesc.map((row) => ({
    id_estabelecimento: row.estabelecimento.id_estabelecimento,
    nome: row.estabelecimento.nome,
    tipo: row.estabelecimento.tipo,
    faixa_preco: row.estabelecimento.faixa_preco,
    ambiente: row.estabelecimento.ambiente,
    created_at: row.created_at,
  }));

  const likedIdsOrder = likedPlaces.map((l) => l.id_estabelecimento);

  const excludedIds = new Set<number>([...latestByPlace.keys()]);

  const candidates = await prisma.tb_estabelecimento.findMany({
    where: { ativo: true },
    select: {
      id_estabelecimento: true,
      nome: true,
      tipo: true,
      faixa_preco: true,
      ambiente: true,
      avaliacao: true,
    },
    take: 500,
  });

  const epsilon = 0.02;
  const allScored: ScoredSuggestion[] = [];

  for (const item of candidates) {
    if (excludedIds.has(item.id_estabelecimento)) continue;

    const avaliacao = Number(item.avaliacao ?? 0);
    const avaliacaoPart = Math.max(0, Math.min(avaliacao, 5)) * 0.15;

    const sims = likedPlaces.map((L) => ({ L, sim: similarityToLiked(item, L) }));
    const maxSimValue = sims.reduce((best, candidate) => Math.max(best, candidate.sim), 0);

    let primaryLikeId = likedIdsOrder[0];
    for (const id of likedIdsOrder) {
      const hit = sims.find((s) => s.L.id_estabelecimento === id && s.sim >= maxSimValue - epsilon);
      if (hit) {
        primaryLikeId = id;
        break;
      }
    }

    const baseadoEm = sims
      .filter(({ sim }) => sim >= maxSimValue - epsilon && sim >= 0.3)
      .sort((a, b) => b.sim - a.sim)
      .slice(0, 3)
      .map(({ L }) => L.nome);

    const scoreFinal = Number((maxSimValue * 4 + avaliacaoPart).toFixed(4));

    allScored.push({
      id_estabelecimento: item.id_estabelecimento,
      nome: item.nome,
      tipo: item.tipo,
      faixa_preco: item.faixa_preco,
      ambiente: item.ambiente,
      score: scoreFinal,
      baseado_em: baseadoEm.length > 0 ? baseadoEm : [likedPlaces[0].nome],
      primary_like_id: primaryLikeId,
    });
  }

  allScored.sort((a, b) => b.score - a.score);

  return diversifyByTasteRoundRobin(limit, likedIdsOrder, allScored);
}
