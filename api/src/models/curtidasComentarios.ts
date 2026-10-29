import { prisma } from "../../lib/prisma";
import { EventoComentarioSchema } from "../mensageria/contrato";

export async function curtirComentario(idClassificacao: number, idEstabelecimento: number, idUsuario: number) {
  return prisma.$transaction(async tx => {
    // Serializa contagem e marcos mesmo com curtidas simultaneas.
    await tx.$queryRaw`SELECT id_classificacao FROM tb_classificacao_estabelecimento WHERE id_classificacao = ${idClassificacao} AND id_estabelecimento = ${idEstabelecimento} FOR UPDATE`;
    const comentario = await tx.tb_classificacao_estabelecimento.findUnique({
      where: { id_classificacao_id_estabelecimento: { id_classificacao: idClassificacao, id_estabelecimento: idEstabelecimento } },
      include: { classificacao: true },
    });
    if (!comentario?.comentario?.trim()) throw Object.assign(new Error("Comentário não encontrado"), { statusCode: 404 });
    if (comentario.classificacao.id_usuario === idUsuario) throw Object.assign(new Error("Você não pode curtir seu próprio comentário"), { statusCode: 400 });
    const where = { id_classificacao: idClassificacao, id_estabelecimento: idEstabelecimento };
    const criada = await tx.tb_curtida_comentario.createMany({ data: [{ ...where, id_usuario: idUsuario }], skipDuplicates: true });
    const total = await tx.tb_curtida_comentario.count({ where });
    if (criada.count && (total === 1 || total % 50 === 0)) {
      const evento = EventoComentarioSchema.parse({
        id_evento: `comentario:${idClassificacao}:${idEstabelecimento}:${total}`,
        tipo: "comentario.curtido", versao: 1, ocorrido_em: new Date().toISOString(),
        dados: { ...where, id_usuario: comentario.classificacao.id_usuario, total },
      });
      await tx.tb_evento_outbox.create({ data: { id_evento: evento.id_evento, conteudo: evento } });
    }
    return { curtido: true, total_curtidas: total };
  });
}
