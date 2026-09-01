import { Request, Response } from "express";
import * as classificacoesModel from "../models/classificacoes";
import { ClassificacaoSchema, ClassificacaoUpdateSchema } from "../types/classificacao";

export async function createClassificacaoController(req: Request, res: Response) {
  try {
    const parsed = ClassificacaoSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({
        errors: parsed.error.flatten()
      });
    }

    const classificacao = await classificacoesModel.createClassificacao(parsed.data);
    if (!classificacao) {
      return res.status(400).json({
        error: "Erro ao criar classificacao"
      });
    }

    return res.status(201).json({ success: true, data: classificacao });
  } catch (error) {
    const statusCode = (error as { statusCode?: unknown })?.statusCode;
    if (typeof statusCode === "number") {
      return res.status(statusCode).json({
        success: false,
        message: error instanceof Error ? error.message : "Erro ao criar classificacao"
      });
    }

    return res.status(500).json({
      success: false,
      message: "Erro ao criar classificacao",
      error: error instanceof Error ? error.message : "Erro desconhecido"
    });
  }
}

export async function listClassificacoesController(_req: Request, res: Response) {
  try {
    const classificacoes = await classificacoesModel.listClassificacoes();
    return res.json({ success: true, data: classificacoes });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Erro ao listar classificacoes",
      error: error instanceof Error ? error.message : "Erro desconhecido"
    });
  }
}

export async function getClassificacaoByIdController(req: Request, res: Response) {
  const id: number = Number(req.params.id);
  if (!id) return res.status(400).json({ success: false, message: "ID invalido" });

  try {
    const classificacao = await classificacoesModel.getClassificacaoById(id);
    if (!classificacao) return res.status(404).json({ success: false, message: "Registro nao encontrado" });
    return res.json({ success: true, data: classificacao });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Erro ao buscar classificacao",
      error: error instanceof Error ? error.message : "Erro desconhecido"
    });
  }
}

export async function updateClassificacaoController(req: Request, res: Response) {
  const id: number = Number(req.params.id);
  if (!id) return res.status(400).json({ success: false, message: "ID invalido" });

  try {
    const parsed = ClassificacaoUpdateSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({
        errors: parsed.error.flatten()
      });
    }

    const existing = await classificacoesModel.getClassificacaoById(id);
    if (!existing) return res.status(404).json({ success: false, message: "Registro nao encontrado" });

    const classificacao = await classificacoesModel.updateClassificacao(id, parsed.data);
    return res.json({ success: true, data: classificacao });
  } catch (error) {
    const statusCode = (error as { statusCode?: unknown })?.statusCode;
    if (typeof statusCode === "number") {
      return res.status(statusCode).json({
        success: false,
        message: error instanceof Error ? error.message : "Erro ao atualizar classificacao"
      });
    }

    return res.status(500).json({
      success: false,
      message: "Erro ao atualizar classificacao",
      error: error instanceof Error ? error.message : "Erro desconhecido"
    });
  }
}

export async function deleteClassificacaoController(req: Request, res: Response) {
  const id: number = Number(req.params.id);
  if (!id) return res.status(400).json({ success: false, message: "ID invalido" });

  try {
    const existing = await classificacoesModel.getClassificacaoById(id);
    if (!existing) return res.status(404).json({ success: false, message: "Registro nao encontrado" });

    await classificacoesModel.deleteClassificacao(id);
    return res.json({ success: true, message: "Registro removido com sucesso" });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Erro ao remover classificacao",
      error: error instanceof Error ? error.message : "Erro desconhecido"
    });
  }
}
