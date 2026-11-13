-- RenameForeignKey
ALTER TABLE "tb_curtida_comentario" RENAME CONSTRAINT "tb_curtida_comentario_comentario_fkey" TO "tb_curtida_comentario_id_classificacao_id_estabelecimento_fkey";

-- RenameForeignKey
ALTER TABLE "tb_curtida_comentario" RENAME CONSTRAINT "tb_curtida_comentario_usuario_fkey" TO "tb_curtida_comentario_id_usuario_fkey";
