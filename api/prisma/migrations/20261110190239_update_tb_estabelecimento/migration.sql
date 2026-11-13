-- AlterTable
ALTER TABLE "tb_estabelecimento" ADD COLUMN     "aberto_almoco" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "aberto_madrugada" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "aberto_manha" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "aberto_noite" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "aberto_tarde" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "abre_min" INTEGER,
ADD COLUMN     "duracao_h" DOUBLE PRECISION,
ADD COLUMN     "fecha_apos_meia_noite" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "fecha_min" INTEGER;
