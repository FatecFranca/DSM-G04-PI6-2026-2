import { Prisma } from "../generated/prisma/client";
import { prisma } from "../../lib/prisma";
import bcrypt from "bcrypt";
import * as type from "../types/usuario";

/** Cria um erro identificado como requisicao invalida para o controller retornar HTTP 400. */
function badRequest(message: string) {
  const error = new Error(message) as Error & { statusCode: number };
  error.statusCode = 400;
  return error;
}

/** Verifica pelo formato se o valor ja e um hash bcrypt e nao deve ser criptografado de novo. */
function isBcryptHash(value: string) {
  return /^\$2[aby]\$\d{2}\$[./A-Za-z0-9]{53}$/.test(value);
}

/** Valida duplicidade, protege a senha com bcrypt e cria o usuario no banco. */
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

/** Consulta todos os usuarios e omite dados sensiveis quando definido pelo select. */
export function listUsuarios() {
  return prisma.tb_usuario.findMany({
    select: { id_usuario: true, nome: true, email: true, telefone: true, url_imagem: true, ativo: true, created_at: true, updated_at: true },
  });
}

/** Busca um unico usuario pela chave primaria numerica. */
export function getUsuarioById(id_usuario: number) {
  return prisma.tb_usuario.findUnique({
    where: { id_usuario },
    select: { id_usuario: true, nome: true, email: true, telefone: true, url_imagem: true, ativo: true, created_at: true, updated_at: true },
  });
}

/** Prepara campos como senha e aplica a atualizacao no usuario solicitado. */
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

/** Busca o snapshot mais recente que guarda as preferencias do usuario. */
export function getPreferencias(idUsuario: number) {
  return prisma.tb_usuario_feature_snapshot.findFirst({
    where: { id_usuario: idUsuario, model_version: "preferencias-v1" },
    orderBy: { created_at: "desc" },
    select: { feature_json: true, created_at: true },
  });
}

/** Cria um novo snapshot JSON das preferencias para manter o historico. */
export function savePreferencias(idUsuario: number, preferencias: Prisma.InputJsonValue) {
  return prisma.tb_usuario_feature_snapshot.create({
    data: { id_usuario: idUsuario, model_version: "preferencias-v1", feature_json: preferencias },
    select: { feature_json: true, created_at: true },
  });
}

/** Exclui definitivamente a linha do usuario pela chave primaria. */
export function deleteUsuario(id_usuario: number) {
  return prisma.tb_usuario.delete({
    where: { id_usuario }
  });
}
// Consultas e alteracoes de usuarios ficam centralizadas aqui.
// Controllers nao precisam conhecer os detalhes do Prisma ou das tabelas.
