import { prisma } from "../../lib/prisma";
import { InteracaoCreateDTO } from "../types/interacao";
import { criarEventoInteracao } from "../mensageria/contrato";
import { mensageriaAtiva } from "../mensageria/configuracao";
import { atualizarMediaAvaliacoes } from "./mediaAvaliacoes";


export async function createInteracao(idUsuario: number, data: InteracaoCreateDTO) {
  const dados = {
    id_usuario: idUsuario,
    id_estabelecimento: data.id_estabelecimento,
    tipo_evento: data.tipo_evento,
    valor: data.valor,
    origem: data.origem,
    regiao: data.regiao,
  };
  const publicar = mensageriaAtiva();
  if (!publicar && data.tipo_evento !== "rating") {
    return prisma.tb_interacao_usuario_estabelecimento.create({ data: dados });
  }
  return prisma.$transaction(async (transacao) => {
    if (data.tipo_evento === "rating") {
      await transacao.$queryRaw`SELECT id_estabelecimento FROM tb_estabelecimento WHERE id_estabelecimento = ${data.id_estabelecimento} FOR UPDATE`;
    }
    const interacao = await transacao.tb_interacao_usuario_estabelecimento.create({ data: dados });
    if (data.tipo_evento === "rating") {
      await transacao.tb_classificacao.create({ data: {
        id_usuario: idUsuario, created_at: interacao.created_at,
        estabelecimentos: { create: {
          id_estabelecimento: data.id_estabelecimento, nota: interacao.valor,
          id_interacao: interacao.id_interacao, created_at: interacao.created_at,
        } },
      } });
      await atualizarMediaAvaliacoes(transacao, data.id_estabelecimento);
    }
    if (publicar) {
      const evento = criarEventoInteracao(interacao);
      await transacao.tb_evento_outbox.create({ data: { id_evento: evento.id_evento, conteudo: evento } });
    }
    return interacao;
  });
}


export function listInteracoesUsuario(idUsuario: number, take = 100, idEstabelecimento?: number) {
  return prisma.tb_interacao_usuario_estabelecimento.findMany({
    where: { id_usuario: idUsuario, id_estabelecimento: idEstabelecimento },
    ...(idEstabelecimento === undefined ? {} : { distinct: ["tipo_evento" as const] }),
    orderBy: [{ created_at: "desc" }, { id_interacao: "desc" }],
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
    distinct: ["id_estabelecimento"],
    orderBy: [{ created_at: "desc" }, { id_interacao: "desc" }],
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
