import "dotenv/config";
import { test } from "node:test";
import assert from "node:assert/strict";
import express from "express";
import { AddressInfo } from "node:net";

test("favoritos: evento atomico, destinatarios, reentrega e privacidade da caixa de avisos", {
  skip: !process.env.DATABASE_URL_TESTE,
}, async () => {
  process.env.DATABASE_URL = process.env.DATABASE_URL_TESTE;
  process.env.JWT_SECRET = "segredo-exclusivo-do-teste-de-notificacoes-123456";
  const { prisma } = await import("../../lib/prisma");
  const { updateEstabelecimento } = await import("../models/estabelecimentos");
  const { processarEventoMensageria } = await import("./persistencia");
  const { EventoEstabelecimentoSchema } = await import("./contrato");
  const { generateToken } = await import("../middlewares/autentication");
  const { default: notificacoes } = await import("../routes/notificacoes");
  const { default: restaurantes } = await import("../routes/estabelecimentos");
  const usuarios = await Promise.all(["favorito", "outro", "tardio", "inativo"].map(nome =>
    prisma.tb_usuario.create({ data: { nome, email: `${nome}-${Date.now()}@example.invalid`, hash_senha: "nao-autenticavel", ativo: nome !== "inativo" } })));
  const local = await prisma.tb_estabelecimento.create({ data: {
    nome: "Restaurante teste", tipo: "bar", faixa_preco: "media", ambiente: "calmo",
    publico: "todos", avaliacao: 4, abre: "08:00", fecha: "18:00",
  } });
  let servidor: ReturnType<ReturnType<typeof express>["listen"]> | undefined;
  const eventos: string[] = [];
  try {
    for (const usuario of [usuarios[0], usuarios[3], usuarios[0]]) {
      await prisma.tb_interacao_usuario_estabelecimento.create({ data: {
        id_usuario: usuario.id_usuario, id_estabelecimento: local.id_estabelecimento,
        tipo_evento: "favorite", created_at: new Date(Date.now() - 60000),
      } });
    }
    await updateEstabelecimento(local.id_estabelecimento, { abre: "09:00" });
    const pendente = await prisma.tb_evento_outbox.findFirstOrThrow({ where: { id_evento: { startsWith: "estabelecimento:" } } });
    const evento = EventoEstabelecimentoSchema.parse(pendente.conteudo);
    eventos.push(evento.id_evento);
    assert.deepEqual(evento.dados.campos, ["abre"]);
    assert.equal((await prisma.tb_estabelecimento.findUniqueOrThrow({ where: { id_estabelecimento: local.id_estabelecimento } })).abre, "09:00");
    await updateEstabelecimento(local.id_estabelecimento, { abre: "09:00" });
    assert.equal(await prisma.tb_evento_outbox.count(), 1);
    await prisma.tb_interacao_usuario_estabelecimento.create({ data: {
      id_usuario: usuarios[2].id_usuario, id_estabelecimento: local.id_estabelecimento,
      tipo_evento: "favorite", created_at: new Date(new Date(evento.ocorrido_em).getTime() + 1000),
    } });
    const resultados = await Promise.all([processarEventoMensageria(evento), processarEventoMensageria(evento)]);
    assert.deepEqual(resultados.sort(), ["duplicado", "processado"]);
    const avisos = await prisma.tb_notificacao.findMany();
    assert.equal(avisos.length, 1);
    assert.equal(avisos[0].id_usuario, usuarios[0].id_usuario);
    assert.match(avisos[0].mensagem, /abertura/);
    assert.equal(avisos[0].lida_em, null);

    const app = express();
    app.use(express.json());
    app.use("/notificacoes", notificacoes);
    app.use("/estabelecimentos", restaurantes);
    servidor = app.listen(0, "127.0.0.1");
    await new Promise<void>(resolve => servidor!.once("listening", resolve));
    const url = `http://127.0.0.1:${(servidor.address() as AddressInfo).port}`;
    const headers = (indice: number) => ({ Authorization: `Bearer ${generateToken({ id_usuario: usuarios[indice].id_usuario })}`, "Content-Type": "application/json" });
    const caixa = await (await fetch(url + "/notificacoes", { headers: headers(0) })).json() as any;
    assert.equal(caixa.data.naoLidas, 1);
    const outra = await (await fetch(url + "/notificacoes", { headers: headers(1) })).json() as any;
    assert.deepEqual(outra.data.notificacoes, []);
    assert.equal((await fetch(`${url}/notificacoes/${avisos[0].id_notificacao}/lida`, { method: "PATCH", headers: headers(1) })).status, 404);
    assert.equal((await fetch(url + "/notificacoes")).status, 401);
    assert.equal((await fetch(`${url}/notificacoes/${avisos[0].id_notificacao}/lida`, { method: "PATCH", headers: headers(0) })).status, 200);
    const lida = await (await fetch(url + "/notificacoes", { headers: headers(0) })).json() as any;
    assert.equal(lida.data.naoLidas, 0);
    assert.ok(lida.data.notificacoes[0].lida_em);
    delete process.env.RESTAURANTES_ADMIN_IDS;
    assert.equal((await fetch(`${url}/estabelecimentos/${local.id_estabelecimento}`, { method: "PUT", headers: headers(1), body: JSON.stringify({ fecha: "20:00" }) })).status, 403);
    process.env.RESTAURANTES_ADMIN_IDS = String(usuarios[1].id_usuario);
    assert.equal((await fetch(`${url}/estabelecimentos/${local.id_estabelecimento}`, { method: "PUT", headers: headers(1), body: JSON.stringify({ fecha: "20:00" }) })).status, 200);
  } finally {
    if (servidor) await new Promise<void>((resolve, reject) => servidor!.close(erro => erro ? reject(erro) : resolve()));
    await prisma.tb_notificacao.deleteMany({ where: { id_estabelecimento: local.id_estabelecimento } });
    const novos = await prisma.tb_evento_outbox.findMany({ where: { id_evento: { startsWith: "estabelecimento:" } } });
    eventos.push(...novos.map(e => e.id_evento));
    await prisma.tb_evento_processado.deleteMany({ where: { id_evento: { in: eventos } } });
    await prisma.tb_evento_outbox.deleteMany({ where: { id_evento: { in: eventos } } });
    await prisma.tb_interacao_usuario_estabelecimento.deleteMany({ where: { id_estabelecimento: local.id_estabelecimento } });
    await prisma.tb_estabelecimento.delete({ where: { id_estabelecimento: local.id_estabelecimento } });
    await prisma.tb_usuario.deleteMany({ where: { id_usuario: { in: usuarios.map(u => u.id_usuario) } } });
    await prisma.$disconnect();
  }
});
