-- CreateTable
CREATE TABLE "tb_usuario" (
    "id_usuario" SERIAL NOT NULL,
    "url_imagem" TEXT,
    "nome" TEXT NOT NULL,
    "email" TEXT,
    "login" TEXT NOT NULL,
    "telefone" TEXT,
    "hash_senha" TEXT NOT NULL,
    "ativo" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "tb_usuario_pkey" PRIMARY KEY ("id_usuario")
);

-- CreateTable
CREATE TABLE "tb_classificacao" (
    "id_classificacao" SERIAL NOT NULL,
    "id_usuario" INTEGER NOT NULL,

    CONSTRAINT "tb_classificacao_pkey" PRIMARY KEY ("id_classificacao")
);

-- CreateTable
CREATE TABLE "tb_classificacao_estabelecimento" (
    "id_classificacao" INTEGER NOT NULL,
    "id_estabelecimento" INTEGER NOT NULL,

    CONSTRAINT "tb_classificacao_estabelecimento_pkey" PRIMARY KEY ("id_classificacao","id_estabelecimento")
);

-- CreateTable
CREATE TABLE "tb_estabelecimento" (
    "id_estabelecimento" SERIAL NOT NULL,
    "nome" TEXT NOT NULL,
    "tipo" TEXT NOT NULL,
    "faixa_preco" TEXT NOT NULL,
    "ambiente" TEXT NOT NULL,
    "publico" TEXT NOT NULL,
    "avaliacao" DECIMAL(65,30) NOT NULL,
    "abre" TEXT NOT NULL,
    "fecha" TEXT NOT NULL,

    CONSTRAINT "tb_estabelecimento_pkey" PRIMARY KEY ("id_estabelecimento")
);

-- AddForeignKey
ALTER TABLE "tb_classificacao" ADD CONSTRAINT "tb_classificacao_id_usuario_fkey" FOREIGN KEY ("id_usuario") REFERENCES "tb_usuario"("id_usuario") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tb_classificacao_estabelecimento" ADD CONSTRAINT "tb_classificacao_estabelecimento_id_classificacao_fkey" FOREIGN KEY ("id_classificacao") REFERENCES "tb_classificacao"("id_classificacao") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tb_classificacao_estabelecimento" ADD CONSTRAINT "tb_classificacao_estabelecimento_id_estabelecimento_fkey" FOREIGN KEY ("id_estabelecimento") REFERENCES "tb_estabelecimento"("id_estabelecimento") ON DELETE RESTRICT ON UPDATE CASCADE;
