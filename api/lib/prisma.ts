import "./ambiente";

if (!process.env.DATABASE_URL?.trim()) throw new Error("DATABASE_URL nao configurada no ambiente ou em api/.env");

import { PrismaClient } from "../src/generated/prisma/client";
import { PrismaPg } from '@prisma/adapter-pg'

const adapter = new PrismaPg({
  connectionString: process.env.DATABASE_URL,
})

export const prisma = new PrismaClient({adapter});
// Este modulo cria uma unica conexao compartilhada com o banco de dados.
// Importar `prisma` em outros arquivos evita abrir uma conexao nova a cada consulta.
