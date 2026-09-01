import { prisma } from "../../lib/prisma";
import { InteracaoCreateDTO } from "../types/interacao";

export async function createInteracao(idUsuario: number, data: InteracaoCreateDTO) {
  return prisma.tb_interacao_usuario_estabelecimento.create({
    data: {
      id_usuario: idUsuario,
      id_estabelecimento: data.id_estabelecimento,
      tipo_evento: data.tipo_evento,
      valor: data.valor,
      origem: data.origem,
      regiao: data.regiao,
    },
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
