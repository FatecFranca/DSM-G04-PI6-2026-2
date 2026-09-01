import { z } from "zod";

export const InteracaoCreateSchema = z.object({
  id_estabelecimento: z.coerce.number().int().positive(),
  tipo_evento: z.enum(["view", "click", "favorite", "like", "dislike", "rating", "visitado"]),
  valor: z.coerce.number().optional(),
  origem: z.string().trim().max(120).optional(),
  regiao: z.string().trim().max(120).optional(),
});

export type InteracaoCreateDTO = z.infer<typeof InteracaoCreateSchema>;
