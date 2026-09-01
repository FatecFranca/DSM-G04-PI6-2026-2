import { Prisma } from "../generated/prisma/client";
import { prisma } from "../../lib/prisma";
import bcrypt from "bcrypt";
import * as type from "../types/usuario";
import e from "express";

function badRequest(message: string) {
  const error = new Error(message) as Error & { statusCode: number };
  error.statusCode = 400;
  return error;
}

function isBcryptHash(value: string) {
  return /^\$2[aby]\$\d{2}\$[./A-Za-z0-9]{53}$/.test(value);
}

export async function createUsuario(data: type.UsuarioDTO) {
 

  const senhaHash = isBcryptHash(data.hash_senha)
    ? data.hash_senha
    : await bcrypt.hash(data.hash_senha, 10);

  try {
    return await prisma.tb_usuario.create({
      data: {
        nome: data.nome,
        email: data.email,
        hash_senha: senhaHash,
      }
    });
  } catch (error) {
    return error instanceof Error
  }
}

export function listUsuarios() {
  return prisma.tb_usuario.findMany();
}

export function getUsuarioById(id_usuario: number) {
  return prisma.tb_usuario.findUnique({
    where: { id_usuario }
  });
}

export async function updateUsuario(id_usuario: number, data: type.UsuarioUpdateDTO) {
  const updateData: Prisma.tb_usuarioUncheckedUpdateInput = {};
  if (data.nome !== undefined) updateData.nome = data.nome;
  if (data.email !== undefined) updateData.email = data.email;
  if (data.senha !== undefined) updateData.hash_senha = await bcrypt.hash(data.senha, 10);

  return prisma.tb_usuario.update({
    where: { id_usuario },
    data: updateData
  });
}

export function deleteUsuario(id_usuario: number) {
  return prisma.tb_usuario.delete({
    where: { id_usuario }
  });
}
