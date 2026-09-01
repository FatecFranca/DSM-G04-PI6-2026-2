import { z } from "zod";

export const ClassificacaoSchema = z.object({
  id_usuario: z.number().int().min(1, "id_usuario e obrigatorio"),
});

export const ClassificacaoUpdateSchema = ClassificacaoSchema.partial();

export type ClassificacaoDTO = z.infer<typeof ClassificacaoSchema>;
export type ClassificacaoUpdateDTO = z.infer<typeof ClassificacaoUpdateSchema>;
