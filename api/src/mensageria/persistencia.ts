import { prisma } from "../../lib/prisma";
import { EventoInteracao, EventoMensageria, EventoMensageriaSchema, ErroMensagemInvalida } from "./contrato";
import { gerarSugestoesAutomaticas } from "../models/sugestoesAutomaticas";

// O insert com chave unica e a invalidacao pertencem a mesma transacao.
// Em entregas concorrentes, apenas quem inserir o identificador executa o efeito.
export async function processarEventoInteracao(evento: EventoInteracao): Promise<"processado" | "duplicado"> {
  return processarEventoMensageria(evento);
}

export async function processarEventoMensageria(evento: EventoMensageria): Promise<"processado" | "duplicado"> {
  return prisma.$transaction(async (transacao) => {
    const registro = await transacao.tb_evento_processado.createMany({
      data: [{ id_evento: evento.id_evento }], skipDuplicates: true,
    });
    if (!registro.count) return "duplicado";
    if (evento.tipo === "comentario.curtido") {
      const comentario = await transacao.tb_classificacao_estabelecimento.findUnique({
        where: { id_classificacao_id_estabelecimento: {
          id_classificacao: evento.dados.id_classificacao, id_estabelecimento: evento.dados.id_estabelecimento,
        } }, include: { classificacao: { include: { usuario: true } }, estabelecimento: true },
      });
      if (!comentario || !comentario.classificacao.usuario.ativo || comentario.classificacao.id_usuario !== evento.dados.id_usuario) return "processado";
      await transacao.tb_notificacao.createMany({ data: [{
        id_usuario: evento.dados.id_usuario, id_estabelecimento: evento.dados.id_estabelecimento,
        id_evento: evento.id_evento,
        titulo: evento.dados.total === 1 ? "Seu comentário recebeu uma curtida!" : `Seu comentário chegou a ${evento.dados.total} curtidas!`,
        mensagem: `Seu comentário em ${comentario.estabelecimento.nome} recebeu ${evento.dados.total} ${evento.dados.total === 1 ? "curtida" : "curtidas"}.`,
      }], skipDuplicates: true });
      return "processado";
    }
    if (evento.tipo === "estabelecimento.atualizado") {
      const local = await transacao.tb_estabelecimento.findUnique({
        where: { id_estabelecimento: evento.dados.id_estabelecimento }, select: { id_estabelecimento: true },
      });
      // Um restaurante removido antes do consumo nao gera um aviso sem destino.
      if (!local) return "processado";
      const favoritos = await transacao.tb_interacao_usuario_estabelecimento.findMany({
        where: {
          id_estabelecimento: evento.dados.id_estabelecimento, tipo_evento: "favorite",
          created_at: { lte: new Date(evento.ocorrido_em) }, usuario: { ativo: true },
        }, distinct: ["id_usuario"], select: { id_usuario: true },
      });
      const rotulos: Record<string, string> = {
        nome: "nome", tipo: "tipo de estabelecimento", faixa_preco: "faixa de preço",
        ambiente: "ambiente", publico: "público", avaliacao: "avaliação pública",
        abre: "horário de abertura", fecha: "horário de fechamento",
      };
      if (favoritos.length) await transacao.tb_notificacao.createMany({
        data: favoritos.map(favorito => ({
          id_usuario: favorito.id_usuario, id_estabelecimento: evento.dados.id_estabelecimento,
          id_evento: evento.id_evento, titulo: `${evento.dados.nome} tem novidades`,
          mensagem: `Um dos seus favoritos atualizou: ${evento.dados.campos.map(campo => rotulos[campo]).join(", ")}. Confira os detalhes.`,
        })), skipDuplicates: true,
      });
      return "processado";
    }
    if (evento.tipo === "preferencias.atualizadas") {
      await transacao.tb_recomendacao_cache.deleteMany({ where: { id_usuario: evento.dados.id_usuario } });
      await gerarSugestoesAutomaticas(transacao, evento.dados.id_usuario, evento.id_evento);
      return "processado";
    }
    const interacao = await transacao.tb_interacao_usuario_estabelecimento.findUnique({
      where: { id_interacao: evento.dados.id_interacao },
      select: { id_usuario: true, tipo_evento: true },
    });
    if (!interacao) throw new ErroMensagemInvalida("Interacao referenciada nao existe");
    await transacao.tb_recomendacao_cache.deleteMany({ where: { id_usuario: interacao.id_usuario } });
    if (["rating", "like", "dislike", "neutral"].includes(interacao.tipo_evento)) {
      await gerarSugestoesAutomaticas(transacao, interacao.id_usuario, evento.id_evento);
    }
    return "processado";
  }, { timeout: 15000 });
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
      conteudo: EventoMensageriaSchema.parse(pendente.conteudo),
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
