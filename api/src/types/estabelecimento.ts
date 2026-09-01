import { z } from "zod";

export const EstabelecimentoSchema = z.object({
  nome: z.string().min(1, "nome e obrigatorio"),
  tipo: z.string().min(1, "tipo e obrigatorio"),
  faixa_preco: z.string().min(1, "faixa_preco e obrigatorio"),
  ambiente: z.string().min(1, "ambiente e obrigatorio"),
  publico: z.string().min(1, "publico e obrigatorio"),
  avaliacao: z.union([z.number(), z.string().min(1, "avaliacao e obrigatoria")]),
  abre: z.string().min(1, "abre e obrigatorio"),
  fecha: z.string().min(1, "fecha e obrigatorio"),
});

export const EstabelecimentoUpdateSchema = EstabelecimentoSchema.partial();

export type EstabelecimentoDTO = z.infer<typeof EstabelecimentoSchema>;
export type EstabelecimentoUpdateDTO = z.infer<typeof EstabelecimentoUpdateSchema>;
