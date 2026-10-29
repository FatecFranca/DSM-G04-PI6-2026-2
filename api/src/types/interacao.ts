import { z } from "zod";

export const InteracaoCreateSchema = z.object({
  id_estabelecimento: z.coerce.number().int().positive(),
  tipo_evento: z.enum(["view", "click", "favorite", "like", "dislike", "neutral", "rating", "visitado"]),
  valor: z.coerce.number().min(1).max(5).optional(),
  origem: z.string().trim().max(120).optional(),
  regiao: z.string().trim().max(120).optional(),
}).refine(data => data.tipo_evento !== "rating" || data.valor !== undefined, {
  message: "Informe uma nota entre 1 e 5", path: ["valor"],
});

export type InteracaoCreateDTO = z.infer<typeof InteracaoCreateSchema>;
