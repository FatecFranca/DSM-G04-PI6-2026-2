import { Prisma } from "../generated/prisma/client";
import { prisma } from "../../lib/prisma";
import * as type from "../types/estabelecimento";


function badRequest(message: string) {
  const error = new Error(message) as Error & { statusCode: number };
  error.statusCode = 400;
  return error;
}

/** Cadastra um estabelecimento e converte erros conhecidos em mensagens amigaveis. */
export async function createEstabelecimento(data: type.EstabelecimentoDTO) {
  try {
    return await prisma.tb_estabelecimento.create({
      data
    });
  } catch (error) {
    if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === "P2003") {
      throw badRequest("Dados informados invalidos");
    }

    throw error;
  }
}

/** Retorna todos os estabelecimentos encontrados pelo Prisma. */
export function listEstabelecimentos() {
  return prisma.tb_estabelecimento.findMany();
}

/** Publica somente nome, nota, comentario e data; nunca dados da conta. */
export async function listAvaliacoesEstabelecimento(id: number, pagina: number) {
  const tamanho = 20;
  const inicio = (pagina - 1) * tamanho;
  const take = inicio + tamanho + 1;
  const [notas, comentarios] = await prisma.$transaction([
    prisma.tb_interacao_usuario_estabelecimento.findMany({
      where: { id_estabelecimento: id, tipo_evento: "rating", valor: { not: null } },
      orderBy: [{ created_at: "desc" }, { id_interacao: "desc" }], take,
      select: { id_interacao: true, valor: true, created_at: true, usuario: { select: { nome: true } } },
    }),
    prisma.tb_classificacao_estabelecimento.findMany({
      where: { id_estabelecimento: id, OR: [{ nota: { not: null } }, { comentario: { not: null } }] },
      orderBy: [{ created_at: "desc" }, { id_classificacao: "desc" }], take,
      select: { id_classificacao: true, nota: true, comentario: true, created_at: true,
        classificacao: { select: { usuario: { select: { nome: true } } } } },
    }),
  ]);
  const lista = [
    ...notas.map(n => ({ id: `interacao:${n.id_interacao}`, nome: n.usuario.nome,
      nota: Number(n.valor), comentario: null as string | null, created_at: n.created_at })),
    ...comentarios.map(c => ({ id: `classificacao:${c.id_classificacao}`, nome: c.classificacao.usuario.nome,
      nota: c.nota, comentario: c.comentario, created_at: c.created_at })),
  ].sort((a, b) => b.created_at.getTime() - a.created_at.getTime()
    || b.id.split(":")[0].localeCompare(a.id.split(":")[0])
    || Number(b.id.split(":")[1]) - Number(a.id.split(":")[1]));
  return { avaliacoes: lista.slice(inicio, inicio + tamanho), temMais: lista.length > inicio + tamanho };
}

/** Busca um estabelecimento pela sua chave primaria. */
export function getEstabelecimentoById(id_estabelecimento: number) {
  return prisma.tb_estabelecimento.findUnique({
    where: { id_estabelecimento }
  });
}

/** Atualiza os campos recebidos sem precisar reconstruir todo o registro. */
export function updateEstabelecimento(id_estabelecimento: number, data: Prisma.tb_estabelecimentoUncheckedUpdateInput) {
  return prisma.tb_estabelecimento.update({
    where: { id_estabelecimento },
    data
  });
}

/** Remove um estabelecimento pela chave primaria. */
export function deleteEstabelecimento(id_estabelecimento: number) {
  return prisma.tb_estabelecimento.delete({
    where: { id_estabelecimento }
  });
}
// Operacoes CRUD (criar, ler, atualizar e excluir) dos estabelecimentos.
