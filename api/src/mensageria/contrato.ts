import { z } from "zod";

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
