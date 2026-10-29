import { Prisma } from "../generated/prisma/client";

/** O chamador deve bloquear o estabelecimento antes de gravar a nota. */
export async function atualizarMediaAvaliacoes(transacao: Prisma.TransactionClient, id: number) {
  const [resumo] = await transacao.$queryRaw<{ media: number | null; total: number }[]>`
    WITH notas AS (
      SELECT i.id_usuario, i.valor AS nota, i.created_at, i.id_interacao AS id, 1 AS origem
      FROM tb_interacao_usuario_estabelecimento i
      WHERE i.id_estabelecimento = ${id} AND i.tipo_evento = 'rating' AND i.valor BETWEEN 1 AND 5
      UNION ALL
      SELECT c.id_usuario, ce.nota, ce.created_at, ce.id_classificacao AS id, 0 AS origem
      FROM tb_classificacao_estabelecimento ce
      JOIN tb_classificacao c ON c.id_classificacao = ce.id_classificacao
      WHERE ce.id_estabelecimento = ${id} AND ce.nota BETWEEN 1 AND 5
    ), ultimas AS (
      SELECT DISTINCT ON (id_usuario) nota FROM notas
      ORDER BY id_usuario, created_at DESC, origem DESC, id DESC
    )
    SELECT AVG(nota)::double precision AS media, COUNT(*)::integer AS total FROM ultimas
  `;
  await transacao.tb_estabelecimento.update({
    where: { id_estabelecimento: id },
    data: { avaliacao: resumo.media ?? 0, total_avaliacoes: resumo.total },
  });
  // O ranking de outras pessoas tambem pode usar a media publica alterada.
  await transacao.tb_recomendacao_cache.deleteMany({});
}
