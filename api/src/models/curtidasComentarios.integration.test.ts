import "dotenv/config";
import { test } from "node:test";
import assert from "node:assert/strict";
import { EventoComentarioSchema } from "../mensageria/contrato";

test("contrato de curtidas aceita somente primeira curtida e marcos de 50", () => {
  for (const total of [1, 50, 100, 150]) {
    const evento = { id_evento: `comentario:1:2:${total}`, tipo: "comentario.curtido", versao: 1,
      ocorrido_em: new Date().toISOString(), dados: { id_classificacao: 1, id_estabelecimento: 2, id_usuario: 3, total } };
    assert.equal(EventoComentarioSchema.safeParse(evento).success, true);
    assert.equal(EventoComentarioSchema.safeParse({ ...evento, id_evento: "outro" }).success, false);
    assert.equal(EventoComentarioSchema.safeParse({ ...evento, dados: { ...evento.dados, total: 49 } }).success, false);
  }
});

test("curtidas: concorrencia, repeticao, autoria, marcos e consumo idempotente", {
  skip: !process.env.DATABASE_URL_TESTE,
}, async () => {
  process.env.DATABASE_URL = process.env.DATABASE_URL_TESTE;
  const { prisma } = await import("../../lib/prisma");
  const { curtirComentario } = await import("./curtidasComentarios");
  const { listAvaliacoesEstabelecimento } = await import("./estabelecimentos");
  const { processarEventoMensageria } = await import("../mensageria/persistencia");
  const prefixo = `curtidas-${Date.now()}-`;
  const usuarios = await prisma.tb_usuario.createManyAndReturn({ data: Array.from({ length: 101 }, (_, i) => ({
    nome: `Teste ${i}`, email: `${prefixo}${i}@example.invalid`, hash_senha: "nao-autenticavel",
  })) });
  const autor = usuarios[0];
  const local = await prisma.tb_estabelecimento.create({ data: {
    nome: "Local teste curtidas", tipo: "bar", faixa_preco: "media", ambiente: "calmo", publico: "todos", avaliacao: 0, abre: "08:00", fecha: "18:00",
  } });
  const classificacao = await prisma.tb_classificacao.create({ data: { id_usuario: autor.id_usuario } });
  const chave = { id_classificacao: classificacao.id_classificacao, id_estabelecimento: local.id_estabelecimento };
  const prefixoEvento = `comentario:${classificacao.id_classificacao}:${local.id_estabelecimento}:`;
  try {
    await prisma.tb_classificacao_estabelecimento.create({ data: { ...chave, comentario: "Ótima experiência!" } });
    await assert.rejects(curtirComentario(chave.id_classificacao, chave.id_estabelecimento, autor.id_usuario), /próprio/);
    await assert.rejects(curtirComentario(2147483647, chave.id_estabelecimento, usuarios[1].id_usuario), /não encontrado/);
    await Promise.all(Array.from({ length: 3 }, () => curtirComentario(chave.id_classificacao, chave.id_estabelecimento, usuarios[1].id_usuario)));
    assert.equal(await prisma.tb_curtida_comentario.count({ where: chave }), 1);
    for (let i = 2; i < usuarios.length; i += 5) {
      await Promise.all(usuarios.slice(i, i + 5).map(u => curtirComentario(chave.id_classificacao, chave.id_estabelecimento, u.id_usuario)));
    }
    const eventos = await prisma.tb_evento_outbox.findMany({ where: { id_evento: { startsWith: prefixoEvento } } });
    assert.equal(eventos.length, 3);
    assert.deepEqual(eventos.map(e => EventoComentarioSchema.parse(e.conteudo).dados.total).sort((a,b) => a-b), [1, 50, 100]);
    for (const e of eventos) {
      const evento = EventoComentarioSchema.parse(e.conteudo);
      assert.equal(await processarEventoMensageria(evento), "processado");
      assert.equal(await processarEventoMensageria(evento), "duplicado");
    }
    const notificacoes = await prisma.tb_notificacao.findMany({ where: { id_estabelecimento: local.id_estabelecimento } });
    assert.equal(notificacoes.length, 3);
    assert.ok(notificacoes.every(n => n.id_usuario === autor.id_usuario));
    const lista = await listAvaliacoesEstabelecimento(local.id_estabelecimento, 1, usuarios[1].id_usuario);
    const comentario = lista.avaliacoes[0] as { total_curtidas: number; curtido: boolean; proprio: boolean };
    assert.equal(comentario.total_curtidas, 100);
    assert.equal(comentario.curtido, true);
    assert.equal(comentario.proprio, false);
  } finally {
    await prisma.tb_notificacao.deleteMany({ where: { id_estabelecimento: local.id_estabelecimento } });
    await prisma.tb_evento_processado.deleteMany({ where: { id_evento: { startsWith: prefixoEvento } } });
    await prisma.tb_evento_outbox.deleteMany({ where: { id_evento: { startsWith: prefixoEvento } } });
    await prisma.tb_classificacao_estabelecimento.deleteMany({ where: chave });
    await prisma.tb_classificacao.delete({ where: { id_classificacao: classificacao.id_classificacao } });
    await prisma.tb_estabelecimento.delete({ where: { id_estabelecimento: local.id_estabelecimento } });
    await prisma.tb_usuario.deleteMany({ where: { email: { startsWith: prefixo } } });
    await prisma.$disconnect();
  }
});
