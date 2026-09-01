import { z } from "zod";

export const RecomendacoesQuerySchema = z.object({
  limit: z.coerce.number().int().min(1).max(50).default(10),
  tipo: z.string().trim().min(1).optional(),
  faixa_preco: z.string().trim().min(1).optional(),
  ambiente: z.string().trim().min(1).optional(),
  cidade: z.string().trim().min(1).optional(),
  bairro: z.string().trim().min(1).optional(),
  force_refresh: z.coerce.boolean().optional().default(false),
});

export type RecomendacoesQueryDTO = z.infer<typeof RecomendacoesQuerySchema>;
