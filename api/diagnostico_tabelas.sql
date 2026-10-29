SELECT 'tb_usuario' AS tabela, COUNT(*) AS registros FROM tb_usuario
UNION ALL SELECT 'tb_estabelecimento', COUNT(*) FROM tb_estabelecimento
UNION ALL SELECT 'tb_classificacao', COUNT(*) FROM tb_classificacao
UNION ALL SELECT 'tb_classificacao_estabelecimento', COUNT(*) FROM tb_classificacao_estabelecimento
UNION ALL SELECT 'tb_interacao_usuario_estabelecimento', COUNT(*) FROM tb_interacao_usuario_estabelecimento
UNION ALL SELECT 'tb_evento_outbox', COUNT(*) FROM tb_evento_outbox
UNION ALL SELECT 'tb_evento_processado', COUNT(*) FROM tb_evento_processado
UNION ALL SELECT 'tb_mensagem_quarentena', COUNT(*) FROM tb_mensagem_quarentena
UNION ALL SELECT 'tb_modelo_recomendacao', COUNT(*) FROM tb_modelo_recomendacao
UNION ALL SELECT 'tb_usuario_feature_snapshot', COUNT(*) FROM tb_usuario_feature_snapshot
UNION ALL SELECT 'tb_recomendacao_cache', COUNT(*) FROM tb_recomendacao_cache
UNION ALL SELECT 'tb_notificacao', COUNT(*) FROM tb_notificacao
ORDER BY tabela;

SELECT COUNT(*) FILTER (WHERE publicado_em IS NULL) AS eventos_pendentes,
       COUNT(*) FILTER (WHERE publicado_em IS NOT NULL) AS eventos_publicados
FROM tb_evento_outbox;
