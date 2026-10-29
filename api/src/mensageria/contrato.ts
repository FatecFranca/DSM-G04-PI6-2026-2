import { z } from "zod";
import { randomUUID } from "node:crypto";

export const EventoInteracaoSchema = z.object({
  id_evento: z.string().max(80),
  tipo: z.literal("interacao.registrada"),
  versao: z.literal(1),
  ocorrido_em: z.iso.datetime(),
  dados: z.object({ id_interacao: z.number().int().positive().max(2147483647) }).strict(),
}).strict().refine(
  (evento) => evento.id_evento === "interacao:" + evento.dados.id_interacao,
  { message: "Identificador do evento nao corresponde a interacao" },
);

export type EventoInteracao = z.infer<typeof EventoInteracaoSchema>;

export const camposNotificaveis = ["nome", "tipo", "faixa_preco", "ambiente", "publico", "avaliacao", "abre", "fecha"] as const;
export const EventoEstabelecimentoSchema = z.object({
  id_evento: z.string().regex(/^estabelecimento:[0-9a-f-]{36}$/),
  tipo: z.literal("estabelecimento.atualizado"),
  versao: z.literal(1),
  ocorrido_em: z.iso.datetime(),
  dados: z.object({
    id_estabelecimento: z.number().int().positive().max(2147483647),
    nome: z.string().min(1).max(500),
    campos: z.array(z.enum(camposNotificaveis)).min(1).max(camposNotificaveis.length),
  }).strict(),
}).strict();
export const EventoPreferenciasSchema = z.object({
  id_evento: z.string().regex(/^preferencias:[0-9a-f-]{36}$/), tipo: z.literal("preferencias.atualizadas"),
  versao: z.literal(1), ocorrido_em: z.iso.datetime(),
  dados: z.object({ id_usuario: z.number().int().positive().max(2147483647) }).strict(),
}).strict();
export const EventoComentarioSchema = z.object({
  id_evento: z.string().max(120),
  tipo: z.literal("comentario.curtido"), versao: z.literal(1), ocorrido_em: z.iso.datetime(),
  dados: z.object({
    id_classificacao: z.number().int().positive(),
    id_estabelecimento: z.number().int().positive(),
    id_usuario: z.number().int().positive(),
    total: z.number().int().positive().refine(n => n === 1 || n % 50 === 0),
  }).strict(),
}).strict().refine(e => e.id_evento === `comentario:${e.dados.id_classificacao}:${e.dados.id_estabelecimento}:${e.dados.total}`);
export const EventoMensageriaSchema = z.union([EventoInteracaoSchema, EventoEstabelecimentoSchema, EventoPreferenciasSchema, EventoComentarioSchema]);
export type EventoMensageria = z.infer<typeof EventoMensageriaSchema>;
export type EventoEstabelecimento = z.infer<typeof EventoEstabelecimentoSchema>;

export function criarEventoPreferencias(idUsuario: number) {
  return EventoPreferenciasSchema.parse({ id_evento: `preferencias:${randomUUID()}`,
    tipo: "preferencias.atualizadas", versao: 1, ocorrido_em: new Date().toISOString(), dados: { id_usuario: idUsuario } });
}

export function camposAlterados(antes: Record<string, unknown>, depois: Record<string, unknown>) {
  return camposNotificaveis.filter(campo => String(antes[campo]) !== String(depois[campo]));
}

export function criarEventoEstabelecimento(id: number, nome: string, campos: typeof camposNotificaveis[number][]) {
  return EventoEstabelecimentoSchema.parse({
    id_evento: `estabelecimento:${randomUUID()}`, tipo: "estabelecimento.atualizado",
    versao: 1, ocorrido_em: new Date().toISOString(),
    dados: { id_estabelecimento: id, nome, campos },
  });
}

export function criarEventoInteracao(interacao: { id_interacao: number; created_at: Date }): EventoInteracao {
  return EventoInteracaoSchema.parse({
    id_evento: "interacao:" + interacao.id_interacao,
    tipo: "interacao.registrada",
    versao: 1,
    ocorrido_em: interacao.created_at.toISOString(),
    dados: { id_interacao: interacao.id_interacao },
  });
}

export class ErroMensagemInvalida extends Error {}
