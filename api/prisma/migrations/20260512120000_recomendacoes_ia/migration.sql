-- Enums para interacoes e modelos de recomendacao
CREATE TYPE "tipo_evento_interacao" AS ENUM ('view', 'click', 'favorite', 'like', 'dislike', 'rating', 'visitado');

CREATE TYPE "status_modelo_recomendacao" AS ENUM ('training', 'ready', 'archived', 'failed');

-- Usuario: alinhar ao App1 (email obrigatorio e unico) e timestamps
ALTER TABLE "tb_usuario" DROP COLUMN IF EXISTS "login";

ALTER TABLE "tb_usuario" ALTER COLUMN "email" SET NOT NULL;

CREATE UNIQUE INDEX "tb_usuario_email_key" ON "tb_usuario"("email");

ALTER TABLE "tb_usuario" ADD COLUMN "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;

-- Classificacoes
ALTER TABLE "tb_classificacao" ADD COLUMN "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;

CREATE INDEX "tb_classificacao_id_usuario_idx" ON "tb_classificacao"("id_usuario");

ALTER TABLE "tb_classificacao_estabelecimento" ADD COLUMN "nota" INTEGER,
ADD COLUMN "comentario" TEXT,
ADD COLUMN "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;

CREATE INDEX "tb_classificacao_estabelecimento_id_estabelecimento_idx" ON "tb_classificacao_estabelecimento"("id_estabelecimento");

-- Estabelecimentos (campos extras para filtros e IA)
ALTER TABLE "tb_estabelecimento" ADD COLUMN "latitude" DECIMAL(65,30),
ADD COLUMN "longitude" DECIMAL(65,30),
ADD COLUMN "cidade" TEXT,
ADD COLUMN "bairro" TEXT,
ADD COLUMN "tags" JSONB,
ADD COLUMN "ativo" BOOLEAN NOT NULL DEFAULT true,
ADD COLUMN "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;

CREATE INDEX "tb_estabelecimento_tipo_faixa_preco_ambiente_idx" ON "tb_estabelecimento"("tipo", "faixa_preco", "ambiente");

CREATE INDEX "tb_estabelecimento_cidade_bairro_idx" ON "tb_estabelecimento"("cidade", "bairro");

-- Modelo de recomendacao (versao fallback usada pelo seed)
CREATE TABLE "tb_modelo_recomendacao" (
    "id_modelo" SERIAL NOT NULL,
    "versao" TEXT NOT NULL,
    "algoritmo" TEXT NOT NULL,
    "metricas_json" JSONB,
    "storage_uri" TEXT,
    "status" "status_modelo_recomendacao" NOT NULL DEFAULT 'training',
    "trained_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "tb_modelo_recomendacao_pkey" PRIMARY KEY ("id_modelo")
);

CREATE UNIQUE INDEX "tb_modelo_recomendacao_versao_key" ON "tb_modelo_recomendacao"("versao");

-- Snapshots de features (extensibilidade futura)
CREATE TABLE "tb_usuario_feature_snapshot" (
    "id_snapshot" SERIAL NOT NULL,
    "id_usuario" INTEGER NOT NULL,
    "model_version" TEXT NOT NULL,
    "feature_json" JSONB NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "tb_usuario_feature_snapshot_pkey" PRIMARY KEY ("id_snapshot")
);

CREATE INDEX "tb_usuario_feature_snapshot_id_usuario_created_at_idx" ON "tb_usuario_feature_snapshot"("id_usuario", "created_at");

CREATE INDEX "tb_usuario_feature_snapshot_model_version_idx" ON "tb_usuario_feature_snapshot"("model_version");

ALTER TABLE "tb_usuario_feature_snapshot" ADD CONSTRAINT "tb_usuario_feature_snapshot_id_usuario_fkey" FOREIGN KEY ("id_usuario") REFERENCES "tb_usuario"("id_usuario") ON DELETE RESTRICT ON UPDATE CASCADE;

-- Interacoes usuario-estabelecimento
CREATE TABLE "tb_interacao_usuario_estabelecimento" (
    "id_interacao" SERIAL NOT NULL,
    "id_usuario" INTEGER NOT NULL,
    "id_estabelecimento" INTEGER NOT NULL,
    "tipo_evento" "tipo_evento_interacao" NOT NULL,
    "valor" DECIMAL(65,30),
    "origem" TEXT,
    "regiao" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "tb_interacao_usuario_estabelecimento_pkey" PRIMARY KEY ("id_interacao")
);

CREATE INDEX "tb_interacao_usuario_estabelecimento_id_usuario_created_at_idx" ON "tb_interacao_usuario_estabelecimento"("id_usuario", "created_at");

CREATE INDEX "tb_interacao_usuario_estabelecimento_id_estabelecimento_created_at_idx" ON "tb_interacao_usuario_estabelecimento"("id_estabelecimento", "created_at");

CREATE INDEX "tb_interacao_usuario_estabelecimento_tipo_evento_created_at_idx" ON "tb_interacao_usuario_estabelecimento"("tipo_evento", "created_at");

ALTER TABLE "tb_interacao_usuario_estabelecimento" ADD CONSTRAINT "tb_interacao_usuario_estabelecimento_id_usuario_fkey" FOREIGN KEY ("id_usuario") REFERENCES "tb_usuario"("id_usuario") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "tb_interacao_usuario_estabelecimento" ADD CONSTRAINT "tb_interacao_usuario_estabelecimento_id_estabelecimento_fkey" FOREIGN KEY ("id_estabelecimento") REFERENCES "tb_estabelecimento"("id_estabelecimento") ON DELETE RESTRICT ON UPDATE CASCADE;

-- Cache de ranking de recomendacoes
CREATE TABLE "tb_recomendacao_cache" (
    "id_usuario" INTEGER NOT NULL,
    "model_version" TEXT NOT NULL,
    "context_hash" TEXT NOT NULL,
    "ranking_json" JSONB NOT NULL,
    "expires_at" TIMESTAMP(3) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "tb_recomendacao_cache_pkey" PRIMARY KEY ("id_usuario","model_version","context_hash")
);

CREATE INDEX "tb_recomendacao_cache_expires_at_idx" ON "tb_recomendacao_cache"("expires_at");

ALTER TABLE "tb_recomendacao_cache" ADD CONSTRAINT "tb_recomendacao_cache_id_usuario_fkey" FOREIGN KEY ("id_usuario") REFERENCES "tb_usuario"("id_usuario") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "tb_recomendacao_cache" ADD CONSTRAINT "tb_recomendacao_cache_model_version_fkey" FOREIGN KEY ("model_version") REFERENCES "tb_modelo_recomendacao"("versao") ON DELETE RESTRICT ON UPDATE CASCADE;
