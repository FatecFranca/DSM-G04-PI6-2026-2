import { z } from "zod";

export const UsuarioSchema = z.object({
  nome: z.string().min(1, "nome e obrigatorio"),
  email: z.string().email("email invalido"),
  hash_senha: z.string().min(1, "hash_senha e obrigatorio"),
});

export const UsuarioUpdateSchema = z.object({
  nome: z.string().min(1, "nome e obrigatorio").optional(),
  email: z.string().email("email invalido").optional(),
  senha: z.string().min(1, "senha e obrigatoria").optional(),
});

export const PreferenciasUsuarioSchema = z.object({
  categoria: z.string().trim().min(1),
  sabor: z.string().trim().min(1),
  faixa_preco: z.string().trim().min(1),
  quantidade_pessoas: z.string().trim().min(1),
  restricao_alimentar: z.string().trim().min(1),
  modalidade_consumo: z.string().trim().min(1),
  localizacao: z.string().trim().max(160).optional(),
  observacao: z.string().trim().max(500).optional(),
});

export type UsuarioDTO = z.infer<typeof UsuarioSchema>;
export type UsuarioUpdateDTO = z.infer<typeof UsuarioUpdateSchema>;
