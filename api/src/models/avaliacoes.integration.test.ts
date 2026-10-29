import "dotenv/config";
import { test } from "node:test";
import assert from "node:assert/strict";
import { ClassificacaoEstabelecimentoSchema } from "../types/classificacaoEstabelecimento";
import { InteracaoCreateSchema } from "../types/interacao";

test("validacao conserva nota e comentario e rejeita notas fora da escala", () => {
  const dados = { id_classificacao: 1, id_estabelecimento: 2, nota: 4, comentario: "  Gostei do atendimento  " };
  assert.deepEqual(ClassificacaoEstabelecimentoSchema.parse(dados), { ...dados, comentario: "Gostei do atendimento" });
  for (const nota of [0, 6, 2.5]) {
    assert.equal(ClassificacaoEstabelecimentoSchema.safeParse({ ...dados, nota }).success, false);
  }
  assert.equal(InteracaoCreateSchema.safeParse({ id_estabelecimento: 2, tipo_evento: "rating" }).success, false);
});

test("banco: grava notas, recupera a ultima avaliacao e conserva comentarios", {
  skip: !process.env.DATABASE_URL_TESTE,
}, async () => {
  process.env.DATABASE_URL = process.env.DATABASE_URL_TESTE;
  process.env.PUBSUB_ATIVO = "false";
  const { prisma } = await import("../../lib/prisma");
  const { createInteracao, listAvaliacoesUsuario, listInteracoesUsuario } = await import("./interacoes");
  const { listAvaliacoesEstabelecimento } = await import("./estabelecimentos");
  const { createClassificacaoEstabelecimento, deleteClassificacaoEstabelecimento } = await import("./classificacoesEstabelecimentos");
  const usuario = await prisma.tb_usuario.create({ data: {
    nome: "Pessoa teste", email: `avaliacao-${Date.now()}@example.invalid`, hash_senha: "teste-nao-autenticavel",
  } });
  const local = await prisma.tb_estabelecimento.create({ data: {
    nome: "Local teste", tipo: "bar", faixa_preco: "media", ambiente: "calmo", publico: "todos",
    avaliacao: 4.8, abre: "08:00", fecha: "18:00",
  } });
  const outro = await prisma.tb_usuario.create({ data: {
    nome: "Outra pessoa", email: `outra-avaliacao-${Date.now()}@example.invalid`, hash_senha: "teste-nao-autenticavel",
  } });
  let idClassificacao: number | undefined;
  try {
    const primeira = await createInteracao(usuario.id_usuario, {
      id_estabelecimento: local.id_estabelecimento, tipo_evento: "rating", valor: 2,
    });
    assert.equal(Number((await prisma.tb_interacao_usuario_estabelecimento.findUniqueOrThrow({
      where: { id_interacao: primeira.id_interacao },
    })).valor), 2);
    const espelho = await prisma.tb_classificacao_estabelecimento.findUniqueOrThrow({
      where: { id_interacao: primeira.id_interacao }, include: { classificacao: true },
    });
    assert.equal(espelho.classificacao.id_usuario, usuario.id_usuario);
    assert.equal(espelho.id_estabelecimento, local.id_estabelecimento);
    assert.equal(Number(espelho.nota), 2);
    assert.equal(espelho.created_at.getTime(), primeira.created_at.getTime());
    let resumo = await prisma.tb_estabelecimento.findUniqueOrThrow({ where: { id_estabelecimento: local.id_estabelecimento } });
    assert.equal(Number(resumo.avaliacao), 2);
    assert.equal(resumo.total_avaliacoes, 1);
    await createInteracao(usuario.id_usuario, { id_estabelecimento: local.id_estabelecimento, tipo_evento: "rating", valor: 5 });
    const historico = await listAvaliacoesUsuario(usuario.id_usuario);
    assert.equal(historico.length, 1);
    assert.equal(Number(historico[0].valor), 5);
    const selecao = await listInteracoesUsuario(usuario.id_usuario, 100, local.id_estabelecimento);
    assert.equal(Number(selecao.find(item => item.tipo_evento === "rating")!.valor), 5);
    const publico = await listAvaliacoesEstabelecimento(local.id_estabelecimento, 1);
    assert.equal(publico.avaliacoes.length, 1);
    assert.equal(publico.avaliacoes[0].nota, 5);
    resumo = await prisma.tb_estabelecimento.findUniqueOrThrow({ where: { id_estabelecimento: local.id_estabelecimento } });
    assert.equal(Number(resumo.avaliacao), 5);
    assert.equal(resumo.total_avaliacoes, 1);
    // Notas concorrentes de pessoas distintas devem compor a mesma media.
    await Promise.all([
      createInteracao(usuario.id_usuario, { id_estabelecimento: local.id_estabelecimento, tipo_evento: "rating", valor: 4 }),
      createInteracao(outro.id_usuario, { id_estabelecimento: local.id_estabelecimento, tipo_evento: "rating", valor: 2 }),
    ]);
    resumo = await prisma.tb_estabelecimento.findUniqueOrThrow({ where: { id_estabelecimento: local.id_estabelecimento } });
    assert.equal(Number(resumo.avaliacao), 3);
    // Se a outbox falhar, nota, classificacao e media devem permanecer consistentes.
    process.env.PUBSUB_ATIVO = "true";
    process.env.GOOGLE_CLOUD_PROJECT = "teste";
    process.env.PUBSUB_TOPICO = "teste";
    process.env.PUBSUB_ASSINATURA = "teste";
    const antes = await prisma.tb_classificacao.count({ where: { id_usuario: usuario.id_usuario } });
    const [sequencia] = await prisma.$queryRaw<{ id: bigint }[]>`
      SELECT nextval(pg_get_serial_sequence('tb_interacao_usuario_estabelecimento', 'id_interacao')) AS id`;
    const eventoConflitante = `interacao:${Number(sequencia.id) + 1}`;
    await prisma.tb_evento_outbox.create({ data: { id_evento: eventoConflitante, conteudo: {} } });
    try {
      await assert.rejects(createInteracao(usuario.id_usuario, {
        id_estabelecimento: local.id_estabelecimento, tipo_evento: "rating", valor: 1,
      }));
      assert.equal(await prisma.tb_classificacao.count({ where: { id_usuario: usuario.id_usuario } }), antes);
      resumo = await prisma.tb_estabelecimento.findUniqueOrThrow({ where: { id_estabelecimento: local.id_estabelecimento } });
      assert.equal(Number(resumo.avaliacao), 3);
    } finally {
      await prisma.tb_evento_outbox.delete({ where: { id_evento: eventoConflitante } });
      process.env.PUBSUB_ATIVO = "false";
    }
    assert.equal(resumo.total_avaliacoes, 2);
    assert.equal("email" in publico.avaliacoes[0], false);
    const classificacao = await prisma.tb_classificacao.create({ data: { id_usuario: usuario.id_usuario } });
    idClassificacao = classificacao.id_classificacao;
    await createClassificacaoEstabelecimento({ id_classificacao: idClassificacao, id_estabelecimento: local.id_estabelecimento, nota: 5, comentario: "Bom atendimento" });
    const gravada = await prisma.tb_classificacao_estabelecimento.findUniqueOrThrow({ where: {
      id_classificacao_id_estabelecimento: { id_classificacao: idClassificacao, id_estabelecimento: local.id_estabelecimento },
    } });
    assert.equal(Number(gravada.nota), 5);
    assert.equal(gravada.comentario, "Bom atendimento");
    const comentarios = await listAvaliacoesEstabelecimento(local.id_estabelecimento, 1);
    assert.ok(comentarios.avaliacoes.some(item => item.comentario === "Bom atendimento" && item.nota === 5));
    resumo = await prisma.tb_estabelecimento.findUniqueOrThrow({ where: { id_estabelecimento: local.id_estabelecimento } });
    assert.equal(Number(resumo.avaliacao), 3.5);
    assert.equal(resumo.total_avaliacoes, 2);
    await deleteClassificacaoEstabelecimento(idClassificacao, local.id_estabelecimento);
    resumo = await prisma.tb_estabelecimento.findUniqueOrThrow({ where: { id_estabelecimento: local.id_estabelecimento } });
    assert.equal(Number(resumo.avaliacao), 3);
  } finally {
    const classificacoes = await prisma.tb_classificacao.findMany({ where: { id_usuario: { in: [usuario.id_usuario, outro.id_usuario] } }, select: { id_classificacao: true } });
    await prisma.tb_classificacao_estabelecimento.deleteMany({ where: { id_estabelecimento: local.id_estabelecimento } });
    await prisma.tb_classificacao.deleteMany({ where: { id_classificacao: { in: classificacoes.map(item => item.id_classificacao) } } });
    idClassificacao = undefined;
    await prisma.tb_interacao_usuario_estabelecimento.deleteMany({ where: { id_estabelecimento: local.id_estabelecimento } });
    if (idClassificacao) {
      await prisma.tb_classificacao_estabelecimento.deleteMany({ where: { id_classificacao: idClassificacao } });
      await prisma.tb_classificacao.delete({ where: { id_classificacao: idClassificacao } });
    }
    await prisma.tb_estabelecimento.delete({ where: { id_estabelecimento: local.id_estabelecimento } });
    await prisma.tb_usuario.delete({ where: { id_usuario: usuario.id_usuario } });
    await prisma.tb_usuario.delete({ where: { id_usuario: outro.id_usuario } });
    await prisma.$disconnect();
  }
});
