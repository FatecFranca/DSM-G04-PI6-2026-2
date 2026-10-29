CREATE TABLE "tb_notificacao" (
  "id_notificacao" SERIAL NOT NULL,
  "id_usuario" INTEGER NOT NULL,
  "id_estabelecimento" INTEGER NOT NULL,
  "id_evento" TEXT NOT NULL,
  "titulo" TEXT NOT NULL,
  "mensagem" TEXT NOT NULL,
  "criado_em" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "lida_em" TIMESTAMP(3),
  CONSTRAINT "tb_notificacao_pkey" PRIMARY KEY ("id_notificacao"),
  CONSTRAINT "tb_notificacao_id_usuario_fkey" FOREIGN KEY ("id_usuario") REFERENCES "tb_usuario"("id_usuario") ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT "tb_notificacao_id_estabelecimento_fkey" FOREIGN KEY ("id_estabelecimento") REFERENCES "tb_estabelecimento"("id_estabelecimento") ON DELETE RESTRICT ON UPDATE CASCADE
);
CREATE UNIQUE INDEX "tb_notificacao_id_usuario_id_evento_key" ON "tb_notificacao"("id_usuario", "id_evento");
CREATE INDEX "tb_notificacao_id_usuario_lida_em_criado_em_idx" ON "tb_notificacao"("id_usuario", "lida_em", "criado_em");
CREATE INDEX "tb_notificacao_id_estabelecimento_idx" ON "tb_notificacao"("id_estabelecimento");
