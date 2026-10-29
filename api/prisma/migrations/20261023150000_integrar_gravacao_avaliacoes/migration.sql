ALTER TABLE "tb_classificacao_estabelecimento"
  ALTER COLUMN "nota" TYPE DECIMAL(65,30) USING "nota"::numeric,
  ADD COLUMN "id_interacao" INTEGER;

CREATE UNIQUE INDEX "tb_classificacao_estabelecimento_id_interacao_key"
  ON "tb_classificacao_estabelecimento"("id_interacao");
ALTER TABLE "tb_classificacao_estabelecimento"
  ADD CONSTRAINT "tb_classificacao_estabelecimento_id_interacao_fkey"
  FOREIGN KEY ("id_interacao") REFERENCES "tb_interacao_usuario_estabelecimento"("id_interacao")
  ON DELETE SET NULL ON UPDATE CASCADE;

-- Recupera notas reais ja gravadas; preserva autor, estabelecimento, valor e data.
WITH avaliacoes AS MATERIALIZED (
  SELECT nextval(pg_get_serial_sequence('tb_classificacao', 'id_classificacao'))::integer AS id_classificacao,
    i.id_interacao, i.id_usuario, i.id_estabelecimento, i.valor, i.created_at
  FROM tb_interacao_usuario_estabelecimento i
  WHERE i.tipo_evento = 'rating' AND i.valor BETWEEN 1 AND 5
    AND NOT EXISTS (SELECT 1 FROM tb_classificacao_estabelecimento ce WHERE ce.id_interacao = i.id_interacao)
), classificacoes AS (
  INSERT INTO tb_classificacao (id_classificacao, id_usuario, created_at)
  SELECT id_classificacao, id_usuario, created_at FROM avaliacoes
  RETURNING id_classificacao
)
INSERT INTO tb_classificacao_estabelecimento
  (id_classificacao, id_estabelecimento, nota, created_at, id_interacao)
SELECT a.id_classificacao, a.id_estabelecimento, a.valor, a.created_at, a.id_interacao
FROM avaliacoes a JOIN classificacoes c USING (id_classificacao);

-- Reaproveita sugestoes reais que o consumidor ja havia persistido.
INSERT INTO tb_modelo_recomendacao (versao, algoritmo, status, created_at)
SELECT 'sugestoes-automaticas-v1', 'ranking-por-regras', 'ready', CURRENT_TIMESTAMP
WHERE EXISTS (SELECT 1 FROM tb_usuario_feature_snapshot
  WHERE model_version = 'sugestoes-automaticas-v1' AND jsonb_typeof(feature_json->'ranking') = 'array')
ON CONFLICT (versao) DO NOTHING;

INSERT INTO tb_recomendacao_cache
  (id_usuario, model_version, context_hash, ranking_json, expires_at, created_at)
SELECT DISTINCT ON (s.id_usuario) s.id_usuario, 'sugestoes-automaticas-v1', 'automaticas-v1',
  s.feature_json->'ranking', s.created_at + INTERVAL '10 minutes', s.created_at
FROM tb_usuario_feature_snapshot s JOIN tb_usuario u ON u.id_usuario = s.id_usuario
WHERE s.model_version = 'sugestoes-automaticas-v1' AND jsonb_typeof(s.feature_json->'ranking') = 'array' AND u.ativo
ORDER BY s.id_usuario, s.created_at DESC, s.id_snapshot DESC
ON CONFLICT (id_usuario, model_version, context_hash) DO NOTHING;
