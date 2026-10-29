import { Prisma } from "../generated/prisma/client";
import { prisma } from "../../lib/prisma";
import * as type from "../types/estabelecimento";
import { camposAlterados, criarEventoEstabelecimento } from "../mensageria/contrato";


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
export async function listAvaliacoesEstabelecimento(id: number, pagina: number, idUsuario?: number) {
  const tamanho = 20;
  const inicio = (pagina - 1) * tamanho;
  const take = inicio + tamanho + 1;
  const [notas, comentarios] = await prisma.$transaction([
    prisma.tb_interacao_usuario_estabelecimento.findMany({
      where: { id_estabelecimento: id, tipo_evento: "rating", valor: { not: null } },
      distinct: ["id_usuario"],
      orderBy: [{ created_at: "desc" }, { id_interacao: "desc" }], take,
      select: { id_interacao: true, valor: true, created_at: true, usuario: { select: { nome: true } } },
    }),
    prisma.tb_classificacao_estabelecimento.findMany({
      where: { id_estabelecimento: id, id_interacao: null, OR: [{ nota: { not: null } }, { comentario: { not: null } }] },
      orderBy: [{ created_at: "desc" }, { id_classificacao: "desc" }], take,
      select: { id_classificacao: true, nota: true, comentario: true, created_at: true,
        _count: { select: { curtidas: true } },
        curtidas: { where: { id_usuario: idUsuario ?? -1 }, select: { id_usuario: true } },
        classificacao: { select: { id_usuario: true, usuario: { select: { nome: true } } } } },
    }),
  ]);
  const lista = [
    ...notas.map(n => ({ id: `interacao:${n.id_interacao}`, nome: n.usuario.nome,
      nota: Number(n.valor), comentario: null as string | null, created_at: n.created_at })),
    ...comentarios.map(c => ({ id: `classificacao:${c.id_classificacao}`, nome: c.classificacao.usuario.nome,
      id_classificacao: c.id_classificacao, total_curtidas: c._count.curtidas,
      curtido: c.curtidas.length > 0, proprio: c.classificacao.id_usuario === idUsuario,
      nota: c.nota === null ? null : Number(c.nota), comentario: c.comentario, created_at: c.created_at })),
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
export function updateEstabelecimento(id_estabelecimento: number, data: type.EstabelecimentoUpdateDTO) {
  return prisma.$transaction(async transacao => {
    // Serializa edicoes concorrentes para comparar com o valor realmente anterior.
    await transacao.$queryRaw`SELECT id_estabelecimento FROM tb_estabelecimento WHERE id_estabelecimento = ${id_estabelecimento} FOR UPDATE`;
    const antes = await transacao.tb_estabelecimento.findUniqueOrThrow({ where: { id_estabelecimento } });
    const depois = await transacao.tb_estabelecimento.update({ where: { id_estabelecimento }, data });
    const campos = camposAlterados(antes, depois);
    if (campos.length) {
      const evento = criarEventoEstabelecimento(id_estabelecimento, depois.nome, campos);
      // Mesmo com o transporte pausado, o aviso fica pendente na outbox.
      await transacao.tb_evento_outbox.create({ data: { id_evento: evento.id_evento, conteudo: evento } });
    }
    return depois;
  });
}

/** Remove um estabelecimento pela chave primaria. */
export function deleteEstabelecimento(id_estabelecimento: number) {
  return prisma.tb_estabelecimento.delete({
    where: { id_estabelecimento }
  });
}
// Operacoes CRUD (criar, ler, atualizar e excluir) dos estabelecimentos.
