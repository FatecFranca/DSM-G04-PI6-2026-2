-- AlterTable
ALTER TABLE "tb_estabelecimento" ALTER COLUMN "updated_at" DROP DEFAULT;

-- AlterTable
ALTER TABLE "tb_usuario" ALTER COLUMN "updated_at" DROP DEFAULT;

-- RenameIndex
ALTER INDEX "tb_interacao_usuario_estabelecimento_id_estabelecimento_created" RENAME TO "tb_interacao_usuario_estabelecimento_id_estabelecimento_cre_idx";
