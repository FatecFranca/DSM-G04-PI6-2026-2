import { Request, Response } from "express";
import { z } from "zod";
import { obterQuestionarioRecomendacao, recomendarEstabelecimentos } from "../models/recomendacoes";

const requisicaoSchema = z.object({
  respostas: z.record(z.string(), z.union([z.string(), z.array(z.string())])).default({}),
  agora_min: z.number().int().min(0).max(1439).nullable().optional().default(null),
  k: z.number().int().min(1).max(50).optional(),
});

export function getModeloRecomendacaoController(_req: Request, res: Response) {
  return res.json({ success: true, data: { questionario: obterQuestionarioRecomendacao() } });
}

export async function recomendarController(req: Request & { user?: { id_usuario: number } }, res: Response) {
  if (!req.user?.id_usuario) return res.status(401).json({ success: false, message: "Usuario nao autenticado" });
  const parsed = requisicaoSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ success: false, errors: parsed.error.flatten() });
  try {
    const { respostas, agora_min, k } = parsed.data;
    const data = await recomendarEstabelecimentos(respostas, k, agora_min);
    return res.json({ success: true, source: "modelo-mineracao", data });
  } catch (error) {
    return res.status(400).json({ success: false, message: error instanceof Error ? error.message : "Requisicao invalida" });
  }
}
