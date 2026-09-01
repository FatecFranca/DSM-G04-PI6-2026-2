import { Request, Response } from "express";
import { RecomendacoesQuerySchema } from "../types/recomendacao";
import * as recomendacoesModel from "../models/recomendacoes";

export async function listRecomendacoesController(
  req: Request & { user?: { id_usuario: number } },
  res: Response
) {
  const parsed = RecomendacoesQuerySchema.safeParse(req.query);
  if (!parsed.success) {
    return res.status(400).json({
      success: false,
      errors: parsed.error.flatten(),
    });
  }

  if (!req.user?.id_usuario) {
    return res.status(401).json({
      success: false,
      message: "Usuario nao autenticado",
    });
  }

  const idUsuario = req.user.id_usuario;
  const query = parsed.data;

  try {
    const modelVersion = await recomendacoesModel.getLatestReadyModelVersion();
    const contextHash = recomendacoesModel.buildContextHash(idUsuario, query);

    if (!query.force_refresh) {
      const cachedRanking = await recomendacoesModel.getCachedRecommendations(idUsuario, modelVersion, contextHash);
      if (cachedRanking) {
        return res.json({
          success: true,
          model_version: modelVersion,
          fallback: modelVersion === "fallback-v1",
          source: "cache",
          data: cachedRanking,
        });
      }
    }

    const candidates = await recomendacoesModel.listCandidateEstabelecimentos(query);
    const ranking = await recomendacoesModel.rankFallbackForUser(idUsuario, candidates, query.limit);

    await recomendacoesModel.upsertRecommendationsCache(idUsuario, modelVersion, contextHash, ranking);

    return res.json({
      success: true,
      model_version: modelVersion,
      fallback: true,
      source: "fresh",
      data: ranking,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Erro ao listar recomendacoes",
      error: error instanceof Error ? error.message : "Erro desconhecido",
    });
  }
}

export async function listAiSuggestionsController(
  req: Request & { user?: { id_usuario: number } },
  res: Response
) {
  if (!req.user?.id_usuario) {
    return res.status(401).json({
      success: false,
      message: "Usuario nao autenticado",
    });
  }

  const limit = Math.min(Math.max(Number(req.query.limit ?? 10) || 10, 1), 50);

  try {
    const data = await recomendacoesModel.listAiSuggestionsFromLikes(req.user.id_usuario, limit);
    return res.json({
      success: true,
      source: "ai-sugestao-like-based",
      data,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Erro ao gerar sugestoes por IA",
      error: error instanceof Error ? error.message : "Erro desconhecido",
    });
  }
}
