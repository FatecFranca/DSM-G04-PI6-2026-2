import { prisma } from "../../lib/prisma";
import { EventoInteracao, EventoInteracaoSchema, ErroMensagemInvalida } from "./contrato";

// O insert com chave unica e a invalidacao pertencem a mesma transacao.
// Em entregas concorrentes, apenas quem inserir o identificador executa o efeito.
export async function processarEventoInteracao(evento: EventoInteracao): Promise<"processado" | "duplicado"> {
  return prisma.$transaction(async (transacao) => {
    const registro = await transacao.tb_evento_processado.createMany({
      data: [{ id_evento: evento.id_evento }], skipDuplicates: true,
    });
    if (!registro.count) return "duplicado";
    const interacao = await transacao.tb_interacao_usuario_estabelecimento.findUnique({
      where: { id_interacao: evento.dados.id_interacao },
      select: { id_usuario: true },
    });
    if (!interacao) throw new ErroMensagemInvalida("Interacao referenciada nao existe");
    await transacao.tb_recomendacao_cache.deleteMany({ where: { id_usuario: interacao.id_usuario } });
    return "processado";
  });
}

export async function registrarQuarentena(registro: {
  chave: string; id_mensagem: string; conteudo: Buffer; motivo: string;
}) {
  await prisma.tb_mensagem_quarentena.upsert({
    where: { chave: registro.chave }, create: { ...registro, conteudo: Uint8Array.from(registro.conteudo) }, update: {},
  });
}

export async function reservarEventoPendente() {
  return prisma.$transaction(async (transacao) => {
    const agora = new Date();
    const pendente = await transacao.tb_evento_outbox.findFirst({
      where: { publicado_em: null, proxima_tentativa_em: { lte: agora } },
      orderBy: { criado_em: "asc" },
    });
    if (!pendente) return null;
    const reserva = await transacao.tb_evento_outbox.updateMany({
      where: { id_evento: pendente.id_evento, publicado_em: null, proxima_tentativa_em: { lte: agora } },
      data: { proxima_tentativa_em: new Date(agora.getTime() + 120000), tentativas: { increment: 1 } },
    });
    if (!reserva.count) return null;
    return {
      id_evento: pendente.id_evento,
      conteudo: EventoInteracaoSchema.parse(pendente.conteudo),
      tentativas: pendente.tentativas + 1,
    };
  });
}

export async function confirmarPublicacao(idEvento: string, idMensagem: string) {
  await prisma.tb_evento_outbox.update({
    where: { id_evento: idEvento }, data: { publicado_em: new Date(), id_mensagem: idMensagem },
  });
}

export async function reagendarPublicacao(idEvento: string, proximaTentativa: Date) {
  await prisma.tb_evento_outbox.updateMany({
    where: { id_evento: idEvento, publicado_em: null }, data: { proxima_tentativa_em: proximaTentativa },
  });
}
