import "dotenv/config";
import { test } from "node:test";
import assert from "node:assert/strict";
import { criarEventoInteracao } from "./contrato";

// Exclusivamente um PostgreSQL descartavel, com migrations ja aplicadas.
test("PostgreSQL: outbox atomica, rollback e idempotencia concorrente", {
  skip: !process.env.DATABASE_URL_TESTE,
}, async () => {
  process.env.DATABASE_URL = process.env.DATABASE_URL_TESTE;
  process.env.PUBSUB_ATIVO = "true";
  process.env.GOOGLE_CLOUD_PROJECT = "teste-local";
  process.env.PUBSUB_TOPICO = "teste-local";
  process.env.PUBSUB_ASSINATURA = "teste-local";
  const { prisma } = await import("../../lib/prisma");
  const { createInteracao } = await import("../models/interacoes");
  const { processarEventoInteracao, reservarEventoPendente, registrarQuarentena } = await import("./persistencia");
  let idUsuario: number | undefined;
  let idEstabelecimento: number | undefined;
  let idInteracao: number | undefined;
  const idInexistente = "interacao:2147483647";
  try {
    const usuario = await prisma.tb_usuario.create({ data: {
      nome: "Teste mensageria", email: "mensageria-" + Date.now() + "@example.invalid", hash_senha: "teste-nao-autenticavel",
    } });
    idUsuario = usuario.id_usuario;
    const local = await prisma.tb_estabelecimento.create({ data: {
      nome: "Teste", tipo: "teste", faixa_preco: "teste", ambiente: "teste", publico: "teste", avaliacao: 4, abre: "08:00", fecha: "18:00",
    } });
    idEstabelecimento = local.id_estabelecimento;
    const interacao = await createInteracao(usuario.id_usuario, { id_estabelecimento: local.id_estabelecimento, tipo_evento: "like" });
    idInteracao = interacao.id_interacao;
    const evento = criarEventoInteracao(interacao);
    assert.ok(await prisma.tb_evento_outbox.findUnique({ where: { id_evento: evento.id_evento } }));
    const modelo = await prisma.tb_modelo_recomendacao.create({ data: { versao: "teste-" + Date.now(), algoritmo: "teste", status: "ready" } });
    try {
      const dadosCache = { id_usuario: usuario.id_usuario, model_version: modelo.versao, context_hash: "teste", ranking_json: [], expires_at: new Date(Date.now() + 60000) };
      await prisma.tb_recomendacao_cache.create({ data: dadosCache });
      const resultados = await Promise.all([processarEventoInteracao(evento), processarEventoInteracao(evento)]);
      assert.deepEqual(resultados.sort(), ["duplicado", "processado"]);
      assert.equal(await prisma.tb_recomendacao_cache.count({ where: { id_usuario: usuario.id_usuario, model_version: modelo.versao } }), 0);
      await prisma.tb_recomendacao_cache.create({ data: dadosCache });
      assert.equal(await processarEventoInteracao(evento), "duplicado");
      assert.equal(await prisma.tb_recomendacao_cache.count({ where: { id_usuario: usuario.id_usuario, model_version: modelo.versao } }), 1);
      await assert.rejects(processarEventoInteracao({ ...evento, id_evento: idInexistente, dados: { id_interacao: 2147483647 } }));
      assert.equal(await prisma.tb_evento_processado.findUnique({ where: { id_evento: idInexistente } }), null);
      const antes = await prisma.tb_interacao_usuario_estabelecimento.count({ where: { id_usuario: usuario.id_usuario } });
      await assert.rejects(createInteracao(usuario.id_usuario, { id_estabelecimento: -1, tipo_evento: "like" }));
      assert.equal(await prisma.tb_interacao_usuario_estabelecimento.count({ where: { id_usuario: usuario.id_usuario } }), antes);
      // Forca falha na insercao da outbox e verifica rollback da interacao.
      const sequencia = await prisma.$queryRaw<{ id: bigint }[]>
        `SELECT nextval(pg_get_serial_sequence('tb_interacao_usuario_estabelecimento', 'id_interacao')) AS id`;
      const proximoId = Number(sequencia[0].id) + 1;
      const idConflitante = "interacao:" + proximoId;
      await prisma.tb_evento_outbox.create({ data: { id_evento: idConflitante, conteudo: {}, publicado_em: new Date() } });
      try {
        await assert.rejects(createInteracao(usuario.id_usuario, { id_estabelecimento: local.id_estabelecimento, tipo_evento: "like" }));
        assert.equal(await prisma.tb_interacao_usuario_estabelecimento.findUnique({ where: { id_interacao: proximoId } }), null);
      } finally {
        await prisma.tb_evento_outbox.delete({ where: { id_evento: idConflitante } });
      }
      const registro = { chave: "quarentena-teste-" + idInteracao, id_mensagem: "teste", conteudo: Buffer.from("invalido"), motivo: "Contrato invalido" };
      try {
        await registrarQuarentena(registro);
        await registrarQuarentena(registro);
        const registros = await prisma.tb_mensagem_quarentena.findMany({ where: { chave: registro.chave } });
        assert.equal(registros.length, 1);
        assert.equal(Buffer.from(registros[0].conteudo).toString(), "invalido");
      } finally {
        await prisma.tb_mensagem_quarentena.deleteMany({ where: { chave: registro.chave } });
      }
      const reservas = await Promise.all([reservarEventoPendente(), reservarEventoPendente()]);
      assert.equal(reservas.filter(Boolean).length, 1);
    } finally {
      await prisma.tb_recomendacao_cache.deleteMany({ where: { id_usuario: usuario.id_usuario } });
      await prisma.tb_modelo_recomendacao.delete({ where: { versao: modelo.versao } });
    }
  } finally {
    if (idInteracao) {
      await prisma.tb_evento_outbox.deleteMany({ where: { id_evento: "interacao:" + idInteracao } });
      await prisma.tb_evento_processado.deleteMany({ where: { id_evento: "interacao:" + idInteracao } });
      await prisma.tb_interacao_usuario_estabelecimento.delete({ where: { id_interacao: idInteracao } });
    }
    if (idEstabelecimento) await prisma.tb_estabelecimento.delete({ where: { id_estabelecimento: idEstabelecimento } });
    if (idUsuario) {
      await prisma.tb_usuario_feature_snapshot.deleteMany({ where: { id_usuario: idUsuario } });
      await prisma.tb_usuario.delete({ where: { id_usuario: idUsuario } });
    }
    await prisma.$disconnect();
  }
});
