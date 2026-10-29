import { Request, Response } from "express";
import * as interacoesModel from "../models/interacoes";
import { InteracaoCreateSchema } from "../types/interacao";

type AuthenticatedRequest = Request & { user?: { id_usuario: number } };

/** Registra uma nova interacao do usuario autenticado com um estabelecimento. */
export async function createInteracaoController(req: AuthenticatedRequest, res: Response) {
  if (!req.user?.id_usuario) {
    return res.status(401).json({
      success: false,
      message: "Usuario nao autenticado",
    });
  }

  const parsed = InteracaoCreateSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({
      success: false,
      errors: parsed.error.flatten(),
    });
  }

  try {
    const created = await interacoesModel.createInteracao(req.user.id_usuario, parsed.data);
    return res.status(201).json({ success: true, data: created });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Erro ao registrar interacao",
      error: error instanceof Error ? error.message : "Erro desconhecido",
    });
  }
}

/** Lista as interacoes recentes pertencentes ao usuario autenticado. */
export async function listMyInteracoesController(req: AuthenticatedRequest, res: Response) {
  if (!req.user?.id_usuario) {
    return res.status(401).json({
      success: false,
      message: "Usuario nao autenticado",
    });
  }

  const take = Math.min(Number(req.query.limit ?? 100) || 100, 300);
  try {
    const id = req.query.id_estabelecimento === undefined ? undefined : Number(req.query.id_estabelecimento);
    if (id !== undefined && (!Number.isInteger(id) || id <= 0)) {
      return res.status(400).json({ success: false, message: "Estabelecimento invalido" });
    }
    const data = await interacoesModel.listInteracoesUsuario(req.user.id_usuario, take, id);
    return res.json({ success: true, data });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Erro ao listar interacoes do usuario",
      error: error instanceof Error ? error.message : "Erro desconhecido",
    });
  }
}

/** Lista somente interacoes do tipo avaliacao feitas pelo usuario atual. */
export async function listMyAvaliacoesController(req: AuthenticatedRequest, res: Response) {
  if (!req.user?.id_usuario) {
    return res.status(401).json({ success: false, message: "Usuario nao autenticado" });
  }

  const take = Math.min(Number(req.query.limit ?? 100) || 100, 300);
  try {
    const data = await interacoesModel.listAvaliacoesUsuario(req.user.id_usuario, take);
    return res.json({ success: true, data });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Erro ao listar avaliacoes do usuario",
      error: error instanceof Error ? error.message : "Erro desconhecido",
    });
  }
}
// Recebe eventos como clique, like e dislike e delega sua gravacao ao model.
