import { Request, Response } from "express";
import * as interacoesModel from "../models/interacoes";
import { InteracaoCreateSchema } from "../types/interacao";

type AuthenticatedRequest = Request & { user?: { id_usuario: number } };

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

export async function listMyInteracoesController(req: AuthenticatedRequest, res: Response) {
  if (!req.user?.id_usuario) {
    return res.status(401).json({
      success: false,
      message: "Usuario nao autenticado",
    });
  }

  const take = Math.min(Number(req.query.limit ?? 100) || 100, 300);
  try {
    const data = await interacoesModel.listInteracoesUsuario(req.user.id_usuario, take);
    return res.json({ success: true, data });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Erro ao listar interacoes do usuario",
      error: error instanceof Error ? error.message : "Erro desconhecido",
    });
  }
}
