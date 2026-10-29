import { Prisma } from "../generated/prisma/client";
import { prisma } from "../../lib/prisma";
import * as type from "../types/classificacaoEstabelecimento";
import { atualizarMediaAvaliacoes } from "./mediaAvaliacoes";
import { criarEventoPreferencias } from "../mensageria/contrato";
import { mensageriaAtiva } from "../mensageria/configuracao";


function badRequest(message: string) {
  const error = new Error(message) as Error & { statusCode: number };
  error.statusCode = 400;
  return error;
}

/** Confere as duas entidades e cria a avaliacao sem permitir relacionamento duplicado. */
export async function createClassificacaoEstabelecimento(data: type.ClassificacaoEstabelecimentoDTO) {
  const classificacao = await prisma.tb_classificacao.findUnique({
    where: { id_classificacao: data.id_classificacao },
    select: { id_classificacao: true, id_usuario: true }
  });

  if (!classificacao) {
    throw badRequest("Classificacao nao encontrada");
  }

  const estabelecimento = await prisma.tb_estabelecimento.findUnique({
    where: { id_estabelecimento: data.id_estabelecimento },
    select: { id_estabelecimento: true }
  });

  if (!estabelecimento) {
    throw badRequest("Estabelecimento nao encontrado");
  }

  try {
    return await prisma.$transaction(async transacao => {
      await transacao.$queryRaw`SELECT id_estabelecimento FROM tb_estabelecimento WHERE id_estabelecimento = ${data.id_estabelecimento} FOR UPDATE`;
      const avaliacao = await transacao.tb_classificacao_estabelecimento.create({
      data: {
        id_classificacao: data.id_classificacao,
        id_estabelecimento: data.id_estabelecimento,
        nota: data.nota,
        comentario: data.comentario,
      }
      });
      if (data.nota !== undefined) await atualizarMediaAvaliacoes(transacao, data.id_estabelecimento);
      if (data.nota !== undefined && mensageriaAtiva()) {
        const evento = criarEventoPreferencias(classificacao.id_usuario);
        await transacao.tb_evento_outbox.create({ data: { id_evento: evento.id_evento, conteudo: evento } });
      }
      return avaliacao;
    });
  } catch (error) {
    if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === "P2002") {
      throw badRequest("Relacionamento ja cadastrado");
    }

    if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === "P2003") {
      throw badRequest("Classificacao ou estabelecimento invalido");
    }

    throw error;
  }
}


export function listClassificacoesEstabelecimentos() {
  return prisma.tb_classificacao_estabelecimento.findMany();
}


export function getClassificacaoEstabelecimentoByIds(id_classificacao: number, id_estabelecimento: number) {
  return prisma.tb_classificacao_estabelecimento.findUnique({
    where: {
      id_classificacao_id_estabelecimento: {
        id_classificacao,
        id_estabelecimento
      }
    }
  });
}

export function deleteClassificacaoEstabelecimento(id_classificacao: number, id_estabelecimento: number) {
  return prisma.$transaction(async transacao => {
    await transacao.$queryRaw`SELECT id_estabelecimento FROM tb_estabelecimento WHERE id_estabelecimento = ${id_estabelecimento} FOR UPDATE`;
    const removida = await transacao.tb_classificacao_estabelecimento.delete({
    where: {
      id_classificacao_id_estabelecimento: {
        id_classificacao,
        id_estabelecimento
      }
    }
    });
    if (removida.nota !== null) await atualizarMediaAvaliacoes(transacao, id_estabelecimento);
    if (removida.nota !== null && mensageriaAtiva()) {
      const classificacao = await transacao.tb_classificacao.findUniqueOrThrow({ where: { id_classificacao } });
      const evento = criarEventoPreferencias(classificacao.id_usuario);
      await transacao.tb_evento_outbox.create({ data: { id_evento: evento.id_evento, conteudo: evento } });
    }
    return removida;
  });
}
