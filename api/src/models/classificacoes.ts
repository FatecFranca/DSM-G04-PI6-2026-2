import { Prisma } from "../generated/prisma/client";
import { prisma } from "../../lib/prisma";
import * as type from "../types/classificacao";

function badRequest(message: string) {
  const error = new Error(message) as Error & { statusCode: number };
  error.statusCode = 400;
  return error;
}

export async function createClassificacao(data: type.ClassificacaoDTO) {
  const usuario = await prisma.tb_usuario.findUnique({
    where: { id_usuario: data.id_usuario },
    select: { id_usuario: true }
  });

  if (!usuario) {
    throw badRequest("Usuario nao encontrado");
  }

  try {
    return await prisma.tb_classificacao.create({
      data: {
        id_usuario: data.id_usuario
      }
    });
  } catch (error) {
    if (error instanceof Prisma.PrismaClientKnownRequestError && (error.code === "P2003" || error.code === "P2025")) {
      throw badRequest("Usuario nao encontrado");
    }

    throw error;
  }
}

export function listClassificacoes() {
  return prisma.tb_classificacao.findMany();
}

export function getClassificacaoById(id_classificacao: number) {
  return prisma.tb_classificacao.findUnique({
    where: { id_classificacao }
  });
}

export async function updateClassificacao(id_classificacao: number, data: Prisma.tb_classificacaoUncheckedUpdateInput) {
  if (typeof data.id_usuario === "number") {
    const usuario = await prisma.tb_usuario.findUnique({
      where: { id_usuario: data.id_usuario },
      select: { id_usuario: true }
    });

    if (!usuario) {
      throw badRequest("Usuario nao encontrado");
    }
  }

  try {
    return await prisma.tb_classificacao.update({
      where: { id_classificacao },
      data
    });
  } catch (error) {
    if (error instanceof Prisma.PrismaClientKnownRequestError && (error.code === "P2003" || error.code === "P2025")) {
      throw badRequest("Usuario nao encontrado");
    }

    throw error;
  }
}

export function deleteClassificacao(id_classificacao: number) {
  return prisma.tb_classificacao.delete({
    where: { id_classificacao }
  });
}
