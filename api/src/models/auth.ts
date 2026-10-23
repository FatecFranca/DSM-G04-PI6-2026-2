import { prisma } from "../../lib/prisma";

/** Procura uma conta pelo e-mail; retorna o usuario ou `null` quando nao existe. */
export async function findUserByEmail(email: string) {
  return prisma.tb_usuario.findFirst({
    where: { email }
  });
}

/** Substitui a senha armazenada pelo novo hash bcrypt do usuario informado. */
export async function updateUserPassword(id_usuario: number, hash_senha: string) {
  return prisma.tb_usuario.update({
    where: { id_usuario },
    data: { hash_senha }
  });
}

