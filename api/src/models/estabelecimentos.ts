import { Prisma } from "../generated/prisma/client";
import { prisma } from "../../lib/prisma";
import * as type from "../types/estabelecimento";

function badRequest(message: string) {
  const error = new Error(message) as Error & { statusCode: number };
  error.statusCode = 400;
  return error;
}

export async function createEstabelecimento(data: type.EstabelecimentoDTO) {
  try {
    return await prisma.tb_estabelecimento.create({
      data
    });
  } catch (error) {
    if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === "P2003") {
      throw badRequest("Dados informados invalidos");
    }

    throw error;
  }
}

export function listEstabelecimentos() {
  return prisma.tb_estabelecimento.findMany();
}

export function getEstabelecimentoById(id_estabelecimento: number) {
  return prisma.tb_estabelecimento.findUnique({
    where: { id_estabelecimento }
  });
}

export function updateEstabelecimento(id_estabelecimento: number, data: Prisma.tb_estabelecimentoUncheckedUpdateInput) {
  return prisma.tb_estabelecimento.update({
    where: { id_estabelecimento },
    data
  });
}

export function deleteEstabelecimento(id_estabelecimento: number) {
  return prisma.tb_estabelecimento.delete({
    where: { id_estabelecimento }
  });
}
