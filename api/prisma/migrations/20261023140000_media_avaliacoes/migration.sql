ALTER TABLE "tb_estabelecimento" ADD COLUMN "total_avaliacoes" INTEGER NOT NULL DEFAULT 0;

-- Recupera as notas existentes, contando apenas a mais recente de cada pessoa por local.
WITH notas AS (
  SELECT i.id_usuario, i.id_estabelecimento, i.valor AS nota, i.created_at, i.id_interacao AS id, 1 AS origem
  FROM tb_interacao_usuario_estabelecimento i
  WHERE i.tipo_evento = 'rating' AND i.valor BETWEEN 1 AND 5
  UNION ALL
  SELECT c.id_usuario, ce.id_estabelecimento, ce.nota, ce.created_at, ce.id_classificacao AS id, 0 AS origem
  FROM tb_classificacao_estabelecimento ce
  JOIN tb_classificacao c ON c.id_classificacao = ce.id_classificacao
  WHERE ce.nota BETWEEN 1 AND 5
), ultimas AS (
  SELECT DISTINCT ON (id_usuario, id_estabelecimento) id_estabelecimento, nota FROM notas
  ORDER BY id_usuario, id_estabelecimento, created_at DESC, origem DESC, id DESC
), medias AS (
  SELECT id_estabelecimento, AVG(nota) AS media, COUNT(*)::integer AS total
  FROM ultimas GROUP BY id_estabelecimento
)
UPDATE tb_estabelecimento e SET avaliacao = medias.media, total_avaliacoes = medias.total
FROM medias WHERE e.id_estabelecimento = medias.id_estabelecimento;

DELETE FROM tb_recomendacao_cache
WHERE EXISTS (SELECT 1 FROM tb_estabelecimento WHERE total_avaliacoes > 0);
