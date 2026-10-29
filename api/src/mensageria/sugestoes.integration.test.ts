import "dotenv/config";
import { test } from "node:test";
import assert from "node:assert/strict";

test("consumidor gera sugestoes por nota, atualiza apos nova nota e ignora reentrega", {
  skip: !process.env.DATABASE_URL_TESTE,
}, async () => {
  process.env.DATABASE_URL = process.env.DATABASE_URL_TESTE;
  process.env.PUBSUB_ATIVO = "true";
  process.env.GOOGLE_CLOUD_PROJECT = "teste";
  process.env.PUBSUB_TOPICO = "teste";
  process.env.PUBSUB_ASSINATURA = "teste";
  const { prisma } = await import("../../lib/prisma");
  const { createInteracao } = await import("../models/interacoes");
  const { processarEventoMensageria } = await import("./persistencia");
  const { criarEventoInteracao, EventoMensageriaSchema } = await import("./contrato");
  const { listarSugestoesAutomaticas, VERSAO_SUGESTOES } = await import("../models/sugestoesAutomaticas");
  const { createClassificacaoEstabelecimento } = await import("../models/classificacoesEstabelecimentos");
  const usuario = await prisma.tb_usuario.create({ data: {
    nome: "Pessoa sugestoes", email: `sugestoes-${Date.now()}@example.invalid`, hash_senha: "teste-nao-autenticavel",
  } });
  const locais: { id_estabelecimento: number }[] = [];
  for (const [nome, tipo, ambiente, faixa_preco] of [
    ["Pizza avaliada", "pizza", "familiar", "media"],
    ["Outra pizzaria", "pizza", "familiar", "media"],
    ["Outro perfil", "cafe", "silencioso", "barata"],
  ]) locais.push(await prisma.tb_estabelecimento.create({ data: {
    nome, tipo, ambiente, faixa_preco, publico: "todos", abre: "08:00", fecha: "18:00", avaliacao: 4,
  } }));
  const eventos: string[] = [];
  let idClassificacao: number | undefined;
  try {
    assert.deepEqual((await listarSugestoesAutomaticas(usuario.id_usuario)).sugestoes, []);
    const salvar = async (valor: number) => {
      const interacao = await createInteracao(usuario.id_usuario, { id_estabelecimento: locais[0].id_estabelecimento, tipo_evento: "rating", valor });
      const evento = criarEventoInteracao(interacao);
      eventos.push(evento.id_evento);
      assert.ok(await prisma.tb_evento_outbox.findUnique({ where: { id_evento: evento.id_evento } }));
      return evento;
    };
    const bom = await salvar(5);
    assert.deepEqual((await listarSugestoesAutomaticas(usuario.id_usuario)).sugestoes, []);
    await processarEventoMensageria(bom);
    const cache = await prisma.tb_recomendacao_cache.findUniqueOrThrow({ where: {
      id_usuario_model_version_context_hash: { id_usuario: usuario.id_usuario, model_version: VERSAO_SUGESTOES, context_hash: "automaticas-v1" },
    } });
    assert.ok(Array.isArray(cache.ranking_json));
    const modelo = await prisma.tb_modelo_recomendacao.findUniqueOrThrow({ where: { versao: VERSAO_SUGESTOES } });
    assert.equal(modelo.algoritmo, "ranking-por-regras");
    assert.equal(modelo.trained_at, null);
    let ranking = (await listarSugestoesAutomaticas(usuario.id_usuario)).sugestoes as any[];
    assert.equal(ranking[0].id_estabelecimento, locais[1].id_estabelecimento);
    assert.equal(ranking.some(item => item.id_estabelecimento === locais[0].id_estabelecimento), false);
    const ruim = await salvar(1);
    await processarEventoMensageria(ruim);
    ranking = (await listarSugestoesAutomaticas(usuario.id_usuario)).sugestoes as any[];
    assert.equal(ranking[0].id_estabelecimento, locais[2].id_estabelecimento);
    assert.equal(await processarEventoMensageria(bom), "duplicado");
    assert.equal(await prisma.tb_usuario_feature_snapshot.count({ where: { id_usuario: usuario.id_usuario, model_version: VERSAO_SUGESTOES } }), 1);
    const antigo = await salvar(1);
    const recente = await salvar(5);
    await processarEventoMensageria(recente);
    await processarEventoMensageria(antigo);
    ranking = (await listarSugestoesAutomaticas(usuario.id_usuario)).sugestoes as any[];
    assert.equal(ranking[0].id_estabelecimento, locais[1].id_estabelecimento);
    // Nota cadastrada por classificacao tambem publica e altera as sugestoes.
    const classificacao = await prisma.tb_classificacao.create({ data: { id_usuario: usuario.id_usuario } });
    idClassificacao = classificacao.id_classificacao;
    await createClassificacaoEstabelecimento({ id_classificacao: idClassificacao, id_estabelecimento: locais[0].id_estabelecimento, nota: 5 });
    const pendentes = await prisma.tb_evento_outbox.findMany({ where: { id_evento: { startsWith: "preferencias:" } } });
    for (const pendente of pendentes) {
      const evento = EventoMensageriaSchema.parse(pendente.conteudo);
      if (evento.tipo === "preferencias.atualizadas" && evento.dados.id_usuario === usuario.id_usuario) {
        eventos.push(evento.id_evento);
        await processarEventoMensageria(evento);
      }
    }
    ranking = (await listarSugestoesAutomaticas(usuario.id_usuario)).sugestoes as any[];
    assert.equal(ranking[0].id_estabelecimento, locais[1].id_estabelecimento);
    await prisma.tb_estabelecimento.update({ where: { id_estabelecimento: locais[1].id_estabelecimento }, data: { ativo: false } });
    ranking = (await listarSugestoesAutomaticas(usuario.id_usuario)).sugestoes as any[];
    assert.equal(ranking.some(item => item.id_estabelecimento === locais[1].id_estabelecimento), false);
  } finally {
    await prisma.tb_recomendacao_cache.deleteMany({ where: { id_usuario: usuario.id_usuario } });
    await prisma.tb_evento_processado.deleteMany({ where: { id_evento: { in: eventos } } });
    await prisma.tb_evento_outbox.deleteMany({ where: { id_evento: { in: eventos } } });
    await prisma.tb_usuario_feature_snapshot.deleteMany({ where: { id_usuario: usuario.id_usuario } });
    const classificacoes = await prisma.tb_classificacao.findMany({ where: { id_usuario: usuario.id_usuario }, select: { id_classificacao: true } });
    await prisma.tb_classificacao_estabelecimento.deleteMany({ where: { id_classificacao: { in: classificacoes.map(item => item.id_classificacao) } } });
    await prisma.tb_classificacao.deleteMany({ where: { id_usuario: usuario.id_usuario } });
    idClassificacao = undefined;
    await prisma.tb_interacao_usuario_estabelecimento.deleteMany({ where: { id_usuario: usuario.id_usuario } });
    if (idClassificacao) {
      await prisma.tb_classificacao_estabelecimento.deleteMany({ where: { id_classificacao: idClassificacao } });
      await prisma.tb_classificacao.delete({ where: { id_classificacao: idClassificacao } });
    }
    await prisma.tb_estabelecimento.deleteMany({ where: { id_estabelecimento: { in: locais.map(local => local.id_estabelecimento) } } });
    await prisma.tb_usuario.delete({ where: { id_usuario: usuario.id_usuario } });
    await prisma.$disconnect();
  }
});
