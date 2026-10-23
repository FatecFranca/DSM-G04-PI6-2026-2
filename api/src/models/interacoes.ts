import { prisma } from "../../lib/prisma";
import { InteracaoCreateDTO } from "../types/interacao";
import { criarEventoInteracao } from "../mensageria/contrato";
import { mensageriaAtiva } from "../mensageria/configuracao";


export async function createInteracao(idUsuario: number, data: InteracaoCreateDTO) {
  const dados = {
    id_usuario: idUsuario,
    id_estabelecimento: data.id_estabelecimento,
    tipo_evento: data.tipo_evento,
    valor: data.valor,
    origem: data.origem,
    regiao: data.regiao,
  };
  if (!mensageriaAtiva()) {
    return prisma.tb_interacao_usuario_estabelecimento.create({ data: dados });
  }
  return prisma.$transaction(async (transacao) => {
    const interacao = await transacao.tb_interacao_usuario_estabelecimento.create({ data: dados });
    const evento = criarEventoInteracao(interacao);
    await transacao.tb_evento_outbox.create({ data: { id_evento: evento.id_evento, conteudo: evento } });
    return interacao;
  });
}


export function listInteracoesUsuario(idUsuario: number, take = 100) {
  return prisma.tb_interacao_usuario_estabelecimento.findMany({
    where: { id_usuario: idUsuario },
    orderBy: { created_at: "desc" },
    take,
    include: {
      estabelecimento: {
        select: {
          id_estabelecimento: true,
          nome: true,
          tipo: true,
          faixa_preco: true,
          ambiente: true,
        },
      },
    },
  });
}

/** Filtra o historico para devolver apenas avaliacoes/notas feitas pelo usuario. */
export function listAvaliacoesUsuario(idUsuario: number, take = 100) {
  return prisma.tb_interacao_usuario_estabelecimento.findMany({
    where: { id_usuario: idUsuario, tipo_evento: "rating" },
    orderBy: { created_at: "desc" },
    take,
    include: {
      estabelecimento: {
        select: {
          id_estabelecimento: true,
          nome: true,
          tipo: true,
          faixa_preco: true,
          ambiente: true,
          cidade: true,
          bairro: true,
        },
      },
    },
  });
}
// Operacoes de banco para o historico de interacoes entre usuarios e locais.
