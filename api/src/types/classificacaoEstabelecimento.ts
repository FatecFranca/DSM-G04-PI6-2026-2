import { z } from "zod";

export const ClassificacaoEstabelecimentoSchema = z.object({
  id_classificacao: z.number().int().min(1, "id_classificacao e obrigatorio"),
  id_estabelecimento: z.number().int().min(1, "id_estabelecimento e obrigatorio"),
  nota: z.number().int().min(1).max(5).optional(),
  comentario: z.string().trim().min(1).max(2000).optional(),
});

export type ClassificacaoEstabelecimentoDTO = z.infer<typeof ClassificacaoEstabelecimentoSchema>;

