import { Request, Response } from "express";
import * as classificacoesEstabelecimentosModel from "../models/classificacoesEstabelecimentos";
import { ClassificacaoEstabelecimentoSchema } from "../types/classificacaoEstabelecimento";

export async function createClassificacaoEstabelecimentoController(req: Request, res: Response) {
  try {
    const parsed = ClassificacaoEstabelecimentoSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({
        errors: parsed.error.flatten()
      });
    }

    const classificacaoEstabelecimento = await classificacoesEstabelecimentosModel.createClassificacaoEstabelecimento(parsed.data);
    if (!classificacaoEstabelecimento) {
      return res.status(400).json({
        error: "Erro ao criar classificacao_estabelecimento"
      });
    }

    return res.status(201).json({ success: true, data: classificacaoEstabelecimento });
  } catch (error) {
    const statusCode = (error as { statusCode?: unknown })?.statusCode;
    if (typeof statusCode === "number") {
      return res.status(statusCode).json({
        success: false,
        message: error instanceof Error ? error.message : "Erro ao criar classificacao_estabelecimento"
      });
    }

    return res.status(500).json({
      success: false,
      message: "Erro ao criar classificacao_estabelecimento",
      error: error instanceof Error ? error.message : "Erro desconhecido"
    });
  }
}

export async function listClassificacoesEstabelecimentosController(_req: Request, res: Response) {
  try {
    const classificacoesEstabelecimentos = await classificacoesEstabelecimentosModel.listClassificacoesEstabelecimentos();
    return res.json({ success: true, data: classificacoesEstabelecimentos });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Erro ao listar classificacoes_estabelecimentos",
      error: error instanceof Error ? error.message : "Erro desconhecido"
    });
  }
}

export async function getClassificacaoEstabelecimentoByIdsController(req: Request, res: Response) {
  const idClassificacao: number = Number(req.params.id_classificacao);
  const idEstabelecimento: number = Number(req.params.id_estabelecimento);

  if (!idClassificacao || !idEstabelecimento) {
    return res.status(400).json({ success: false, message: "IDs invalidos" });
  }

  try {
    const classificacaoEstabelecimento = await classificacoesEstabelecimentosModel.getClassificacaoEstabelecimentoByIds(idClassificacao, idEstabelecimento);
    if (!classificacaoEstabelecimento) return res.status(404).json({ success: false, message: "Registro nao encontrado" });
    return res.json({ success: true, data: classificacaoEstabelecimento });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Erro ao buscar classificacao_estabelecimento",
      error: error instanceof Error ? error.message : "Erro desconhecido"
    });
  }
}

export async function deleteClassificacaoEstabelecimentoController(req: Request, res: Response) {
  const idClassificacao: number = Number(req.params.id_classificacao);
  const idEstabelecimento: number = Number(req.params.id_estabelecimento);

  if (!idClassificacao || !idEstabelecimento) {
    return res.status(400).json({ success: false, message: "IDs invalidos" });
  }

  try {
    const existing = await classificacoesEstabelecimentosModel.getClassificacaoEstabelecimentoByIds(idClassificacao, idEstabelecimento);
    if (!existing) return res.status(404).json({ success: false, message: "Registro nao encontrado" });

    await classificacoesEstabelecimentosModel.deleteClassificacaoEstabelecimento(idClassificacao, idEstabelecimento);
    return res.json({ success: true, message: "Registro removido com sucesso" });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Erro ao remover classificacao_estabelecimento",
      error: error instanceof Error ? error.message : "Erro desconhecido"
    });
  }
}
