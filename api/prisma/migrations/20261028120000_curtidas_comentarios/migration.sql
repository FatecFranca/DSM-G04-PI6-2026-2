CREATE TABLE "tb_curtida_comentario" (
  "id_classificacao" INTEGER NOT NULL,
  "id_estabelecimento" INTEGER NOT NULL,
  "id_usuario" INTEGER NOT NULL,
  "criado_em" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "tb_curtida_comentario_pkey" PRIMARY KEY ("id_classificacao", "id_estabelecimento", "id_usuario"),
  CONSTRAINT "tb_curtida_comentario_comentario_fkey" FOREIGN KEY ("id_classificacao", "id_estabelecimento") REFERENCES "tb_classificacao_estabelecimento"("id_classificacao", "id_estabelecimento") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "tb_curtida_comentario_usuario_fkey" FOREIGN KEY ("id_usuario") REFERENCES "tb_usuario"("id_usuario") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "tb_curtida_comentario_id_usuario_idx" ON "tb_curtida_comentario"("id_usuario");
