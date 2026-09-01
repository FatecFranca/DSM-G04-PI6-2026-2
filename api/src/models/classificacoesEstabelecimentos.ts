import { Prisma } from "../generated/prisma/client";
import { prisma } from "../../lib/prisma";
import * as type from "../types/classificacaoEstabelecimento";

function badRequest(message: string) {
  const error = new Error(message) as Error & { statusCode: number };
  error.statusCode = 400;
  return error;
}

export async function createClassificacaoEstabelecimento(data: type.ClassificacaoEstabelecimentoDTO) {
  const classificacao = await prisma.tb_classificacao.findUnique({
    where: { id_classificacao: data.id_classificacao },
    select: { id_classificacao: true }
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
    return await prisma.tb_classificacao_estabelecimento.create({
      data: {
        id_classificacao: data.id_classificacao,
        id_estabelecimento: data.id_estabelecimento
      }
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
  return prisma.tb_classificacao_estabelecimento.delete({
    where: {
      id_classificacao_id_estabelecimento: {
        id_classificacao,
        id_estabelecimento
      }
    }
  });
}
