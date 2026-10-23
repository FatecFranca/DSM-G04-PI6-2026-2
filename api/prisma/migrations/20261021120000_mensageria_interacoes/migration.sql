CREATE TABLE "tb_evento_outbox" (
  "id_evento" TEXT NOT NULL PRIMARY KEY,
  "conteudo" JSONB NOT NULL,
  "criado_em" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "publicado_em" TIMESTAMP(3),
  "id_mensagem" TEXT,
  "tentativas" INTEGER NOT NULL DEFAULT 0,
  "proxima_tentativa_em" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX "tb_evento_outbox_publicado_em_proxima_tentativa_em_idx"
ON "tb_evento_outbox"("publicado_em", "proxima_tentativa_em");
CREATE TABLE "tb_evento_processado" (
  "id_evento" TEXT NOT NULL PRIMARY KEY,
  "processado_em" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE "tb_mensagem_quarentena" (
  "chave" TEXT NOT NULL PRIMARY KEY,
  "id_mensagem" TEXT NOT NULL,
  "conteudo" BYTEA NOT NULL,
  "motivo" TEXT NOT NULL,
  "criado_em" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);
