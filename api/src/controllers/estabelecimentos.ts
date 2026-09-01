import { Request, Response } from "express";
import * as estabelecimentosModel from "../models/estabelecimentos";
import { EstabelecimentoSchema, EstabelecimentoUpdateSchema } from "../types/estabelecimento";

export async function createEstabelecimentoController(req: Request, res: Response) {
  try {
    const parsed = EstabelecimentoSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({
        errors: parsed.error.flatten()
      });
    }

    const estabelecimento = await estabelecimentosModel.createEstabelecimento(parsed.data);
    if (!estabelecimento) {
      return res.status(400).json({
        error: "Erro ao criar estabelecimento"
      });
    }

    return res.status(201).json({ success: true, data: estabelecimento });
  } catch (error) {
    const statusCode = (error as { statusCode?: unknown })?.statusCode;
    if (typeof statusCode === "number") {
      return res.status(statusCode).json({
        success: false,
        message: error instanceof Error ? error.message : "Erro ao criar estabelecimento"
      });
    }

    return res.status(500).json({
      success: false,
      message: "Erro ao criar estabelecimento",
      error: error instanceof Error ? error.message : "Erro desconhecido"
    });
  }
}

export async function listEstabelecimentosController(_req: Request, res: Response) {
  try {
    const estabelecimentos = await estabelecimentosModel.listEstabelecimentos();
    return res.json({ success: true, data: estabelecimentos });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Erro ao listar estabelecimentos",
      error: error instanceof Error ? error.message : "Erro desconhecido"
    });
  }
}

export async function getEstabelecimentoByIdController(req: Request, res: Response) {
  const id: number = Number(req.params.id);
  if (!id) return res.status(400).json({ success: false, message: "ID invalido" });

  try {
    const estabelecimento = await estabelecimentosModel.getEstabelecimentoById(id);
    if (!estabelecimento) return res.status(404).json({ success: false, message: "Registro nao encontrado" });
    return res.json({ success: true, data: estabelecimento });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Erro ao buscar estabelecimento",
      error: error instanceof Error ? error.message : "Erro desconhecido"
    });
  }
}

export async function updateEstabelecimentoController(req: Request, res: Response) {
  const id: number = Number(req.params.id);
  if (!id) return res.status(400).json({ success: false, message: "ID invalido" });

  try {
    const parsed = EstabelecimentoUpdateSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({
        errors: parsed.error.flatten()
      });
    }

    const existing = await estabelecimentosModel.getEstabelecimentoById(id);
    if (!existing) return res.status(404).json({ success: false, message: "Registro nao encontrado" });

    const estabelecimento = await estabelecimentosModel.updateEstabelecimento(id, parsed.data);
    return res.json({ success: true, data: estabelecimento });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Erro ao atualizar estabelecimento",
      error: error instanceof Error ? error.message : "Erro desconhecido"
    });
  }
}

export async function deleteEstabelecimentoController(req: Request, res: Response) {
  const id: number = Number(req.params.id);
  if (!id) return res.status(400).json({ success: false, message: "ID invalido" });

  try {
    const existing = await estabelecimentosModel.getEstabelecimentoById(id);
    if (!existing) return res.status(404).json({ success: false, message: "Registro nao encontrado" });

    await estabelecimentosModel.deleteEstabelecimento(id);
    return res.json({ success: true, message: "Registro removido com sucesso" });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Erro ao remover estabelecimento",
      error: error instanceof Error ? error.message : "Erro desconhecido"
    });
  }
}
