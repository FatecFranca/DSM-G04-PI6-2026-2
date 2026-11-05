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

const escolhas = z.union([z.string().trim().min(1), z.array(z.string().trim().min(1)).min(1).max(20)])
  .transform(valor => [...new Set(Array.isArray(valor) ? valor : [valor])]);

export const PreferenciasUsuarioSchema = z.object({
  categoria: escolhas,
  sabor: z.string().trim().min(1),
  faixa_preco: z.string().trim().min(1),
  quantidade_pessoas: z.string().trim().min(1),
  restricao_alimentar: escolhas.refine(valores => !valores.includes("Nenhuma") || valores.length === 1, "Nenhuma nao pode ser combinada com outras restricoes"),
  modalidade_consumo: z.string().trim().min(1),
  localizacao: z.string().trim().max(160).optional(),
  observacao: z.string().trim().max(500).optional(),
});

export type UsuarioDTO = z.infer<typeof UsuarioSchema>;
export type UsuarioUpdateDTO = z.infer<typeof UsuarioUpdateSchema>;

