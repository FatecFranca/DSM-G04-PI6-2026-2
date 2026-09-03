import { Prisma } from "../generated/prisma/client";
import { prisma } from "../../lib/prisma";
import bcrypt from "bcrypt";
import * as type from "../types/usuario";

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
      },
      select: { id_usuario: true, nome: true, email: true, telefone: true, url_imagem: true, ativo: true, created_at: true, updated_at: true },
    });
  } catch (error) {
    if ((error as { code?: string }).code === "P2002") throw badRequest("E-mail ja cadastrado");
    throw error;
  }
}

export function listUsuarios() {
  return prisma.tb_usuario.findMany({
    select: { id_usuario: true, nome: true, email: true, telefone: true, url_imagem: true, ativo: true, created_at: true, updated_at: true },
  });
}

export function getUsuarioById(id_usuario: number) {
  return prisma.tb_usuario.findUnique({
    where: { id_usuario },
    select: { id_usuario: true, nome: true, email: true, telefone: true, url_imagem: true, ativo: true, created_at: true, updated_at: true },
  });
}

export async function updateUsuario(id_usuario: number, data: type.UsuarioUpdateDTO) {
  const updateData: Prisma.tb_usuarioUncheckedUpdateInput = {};
  if (data.nome !== undefined) updateData.nome = data.nome;
  if (data.email !== undefined) updateData.email = data.email;
  if (data.senha !== undefined) updateData.hash_senha = await bcrypt.hash(data.senha, 10);

  return prisma.tb_usuario.update({
    where: { id_usuario },
    data: updateData,
    select: { id_usuario: true, nome: true, email: true, telefone: true, url_imagem: true, ativo: true, created_at: true, updated_at: true },
  });
}

export function getPreferencias(idUsuario: number) {
  return prisma.tb_usuario_feature_snapshot.findFirst({
    where: { id_usuario: idUsuario, model_version: "preferencias-v1" },
    orderBy: { created_at: "desc" },
    select: { feature_json: true, created_at: true },
  });
}

export function savePreferencias(idUsuario: number, preferencias: Prisma.InputJsonValue) {
  return prisma.tb_usuario_feature_snapshot.create({
    data: { id_usuario: idUsuario, model_version: "preferencias-v1", feature_json: preferencias },
    select: { feature_json: true, created_at: true },
  });
}

export function deleteUsuario(id_usuario: number) {
  return prisma.tb_usuario.delete({
    where: { id_usuario }
  });
}
