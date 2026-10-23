import { test } from "node:test";
import assert from "node:assert/strict";
import { criarEventoInteracao, EventoInteracaoSchema, ErroMensagemInvalida } from "./contrato";
import { consumirMensagem, DependenciasConsumidor, MensagemRecebida } from "./consumidor";
import { publicarProximoEvento, DependenciasPublicador } from "./publicador";
import { lerConfiguracaoMensageria } from "./configuracao";

const evento = criarEventoInteracao({ id_interacao: 42, created_at: new Date("2026-10-21T12:00:00Z") });
function preparar(conteudo: Buffer = Buffer.from(JSON.stringify(evento))) {
  const passos: string[] = [];
  const mensagem: MensagemRecebida = {
    id: "mensagem-1", data: conteudo,
    ack: () => { passos.push("ack"); }, nack: () => { passos.push("nack"); },
  };
  const dependencias: DependenciasConsumidor = {
    processar: async () => { passos.push("commit"); return "processado"; },
    quarentena: async () => { passos.push("quarentena"); },
    registrar: (estado) => { passos.push(estado); },
  };
  return { mensagem, dependencias, passos };
}

test("confirma somente depois do processamento concluido", async () => {
  const contexto = preparar();
  let concluir!: () => void;
  contexto.dependencias.processar = async () => {
    await new Promise<void>((resolve) => { concluir = resolve; });
    contexto.passos.push("commit"); return "processado";
  };
  const processamento = consumirMensagem(contexto.mensagem, contexto.dependencias);
  assert.deepEqual(contexto.passos, []);
  concluir(); await processamento;
  assert.deepEqual(contexto.passos, ["commit", "ack", "processado"]);
});

test("JSON invalido vai para quarentena antes do ack", async () => {
  const contexto = preparar(Buffer.from("{invalido"));
  await consumirMensagem(contexto.mensagem, contexto.dependencias);
  assert.deepEqual(contexto.passos, ["quarentena", "ack", "quarentena"]);
});

test("contrato invalido nao executa negocio", async () => {
  const contexto = preparar(Buffer.from(JSON.stringify({ tipo: "pedido" })));
  await consumirMensagem(contexto.mensagem, contexto.dependencias);
  assert.equal(contexto.passos.includes("commit"), false);
  assert.equal(contexto.passos.includes("ack"), true);
});

test("falha temporaria pede nova entrega sem confirmar", async () => {
  const contexto = preparar();
  contexto.dependencias.processar = async () => { throw new Error("Banco indisponivel"); };
  await consumirMensagem(contexto.mensagem, contexto.dependencias);
  assert.deepEqual(contexto.passos, ["nack", "nova_tentativa"]);
});

test("falha na quarentena tambem pede nova entrega", async () => {
  const contexto = preparar(Buffer.from("null"));
  contexto.dependencias.quarentena = async () => { throw new Error("Banco indisponivel"); };
  await consumirMensagem(contexto.mensagem, contexto.dependencias);
  assert.deepEqual(contexto.passos, ["nack", "quarentena_indisponivel"]);
});

test("interacao inexistente e uma falha permanente registrada", async () => {
  const contexto = preparar();
  contexto.dependencias.processar = async () => { throw new ErroMensagemInvalida("Interacao inexistente"); };
  await consumirMensagem(contexto.mensagem, contexto.dependencias);
  assert.deepEqual(contexto.passos, ["quarentena", "ack", "quarentena"]);
});

test("entrega duplicada e confirmada sem solicitar outro efeito", async () => {
  const contexto = preparar();
  let efeitos = 0;
  const concluidos = new Set<string>();
  contexto.dependencias.processar = async (recebido) => {
    if (concluidos.has(recebido.id_evento)) return "duplicado";
    concluidos.add(recebido.id_evento); efeitos++; return "processado";
  };
  await consumirMensagem(contexto.mensagem, contexto.dependencias);
  await consumirMensagem({ ...contexto.mensagem, id: "nova-entrega" }, contexto.dependencias);
  assert.equal(efeitos, 1);
  assert.deepEqual(contexto.passos, ["ack", "processado", "ack", "duplicado"]);
});

test("identificador deve corresponder a interacao", () => {
  assert.equal(EventoInteracaoSchema.safeParse({ ...evento, id_evento: "outro" }).success, false);
});

test("rejeita versao desconhecida e identificadores numericos invalidos", () => {
  assert.equal(EventoInteracaoSchema.safeParse({ ...evento, versao: 2 }).success, false);
  assert.equal(EventoInteracaoSchema.safeParse({ ...evento, dados: { id_interacao: -1 } }).success, false);
  assert.equal(EventoInteracaoSchema.safeParse({ ...evento, dados: { id_interacao: 2147483648 } }).success, false);
});

test("mensagem grande tem tratamento explicito", async () => {
  const contexto = preparar(Buffer.alloc(65537));
  await consumirMensagem(contexto.mensagem, contexto.dependencias);
  assert.equal(contexto.passos[0], "quarentena");
});

test("outbox aguarda confirmacao do transporte antes de marcar envio", async () => {
  const passos: string[] = [];
  let concluir!: (id: string) => void;
  const dependencias: DependenciasPublicador = {
    reservar: async () => ({ id_evento: evento.id_evento, conteudo: evento, tentativas: 1 }),
    publicar: async () => new Promise<string>((resolve) => { concluir = resolve; }),
    confirmar: async (id, mensagem) => { assert.equal(id, evento.id_evento); assert.equal(mensagem, "google-1"); passos.push("confirmado"); },
    reagendar: async () => { assert.fail("Nao deve reagendar"); }, registrar: () => {},
  };
  const publicacao = publicarProximoEvento(dependencias);
  await new Promise((resolve) => setImmediate(resolve));
  assert.deepEqual(passos, []);
  concluir("google-1"); await publicacao;
  assert.deepEqual(passos, ["confirmado"]);
});

test("falha de publicacao preserva id e reagenda com espera", async () => {
  let reagendou = false;
  await publicarProximoEvento({
    reservar: async () => ({ id_evento: evento.id_evento, conteudo: evento, tentativas: 3 }),
    publicar: async () => { throw new Error("Pub/Sub indisponivel"); },
    confirmar: async () => { assert.fail("Nao pode confirmar"); },
    reagendar: async (id, data) => { assert.equal(id, evento.id_evento); assert.ok(data.getTime() > Date.now()); reagendou = true; },
    registrar: () => {},
  });
  assert.equal(reagendou, true);
});

test("falha ao marcar envio permite reenvio seguro do mesmo evento", async () => {
  let reagendou = false;
  await publicarProximoEvento({
    reservar: async () => ({ id_evento: evento.id_evento, conteudo: evento, tentativas: 1 }),
    publicar: async () => "google-2",
    confirmar: async () => { throw new Error("Falha de commit"); },
    reagendar: async (id) => { assert.equal(id, evento.id_evento); reagendou = true; }, registrar: () => {},
  });
  assert.equal(reagendou, true);
});

test("outbox vazia nao publica", async () => {
  const resultado = await publicarProximoEvento({
    reservar: async () => null,
    publicar: async () => { assert.fail("Sem evento"); },
    confirmar: async () => {}, reagendar: async () => {}, registrar: () => {},
  });
  assert.equal(resultado, false);
});

test("configuracao exige recursos ao ativar e e opcional quando desativada", () => {
  assert.equal(lerConfiguracaoMensageria({}).PUBSUB_ATIVO, "false");
  assert.throws(() => lerConfiguracaoMensageria({ PUBSUB_ATIVO: "true" }));
  assert.equal(lerConfiguracaoMensageria({ PUBSUB_ATIVO: "true", GOOGLE_CLOUD_PROJECT: "projeto", PUBSUB_TOPICO: "topico", PUBSUB_ASSINATURA: "assinatura" }).PUBSUB_CONCORRENCIA, 5);
});


import { ocultarCredenciais, serializarErro, registrarMensageria } from "./log";

test("log preserva mensagem, codigo e stack da falha real", () => {
  const erro = Object.assign(new Error("A tabela tb_evento_outbox nao existe"), { code: "P2021" });
  const registro = serializarErro(erro, {});
  assert.equal(registro.codigo, "P2021");
  assert.match(registro.mensagem, /tb_evento_outbox/);
  assert.match(registro.stack!, /Error:/);
});

test("log oculta URL de banco, senha codificada, token e segredo do ambiente", () => {
  const ambiente = { DATABASE_URL: "postgresql://usuario:senha%40teste@localhost/banco", JWT_SECRET: "segredo-de-teste" };
  const erro = new Error("Falha postgresql://usuario:senha%40teste@localhost/banco senha@teste senha%40teste segredo-de-teste Bearer abc.def.ghi");
  const registro = JSON.stringify(serializarErro(erro, ambiente));
  for (const segredo of [ambiente.DATABASE_URL, "senha@teste", "senha%40teste", ambiente.JWT_SECRET, "abc.def.ghi"]) {
    assert.equal(registro.includes(segredo), false);
  }
  assert.match(registro, /OCULTO/);
});

test("log protege credenciais desconhecidas em URLs e campos JSON", () => {
  const texto = ocultarCredenciais('postgresql://alice:senha-ficticia@localhost/db {"password":"valor-ficticio","token":"outro-segredo"} senha=mais-um', {});
  for (const segredo of ["alice", "senha-ficticia", "valor-ficticio", "outro-segredo", "mais-um"]) {
    assert.equal(texto.includes(segredo), false);
  }
});

test("log registra causas encadeadas sem anexar metadados ou payload", () => {
  const causa = Object.assign(new Error("Conexao interrompida"), { code: "ECONNRESET" });
  const erro = Object.assign(new Error("Transacao falhou"), { cause: causa, payload: { senha: "nao-deve-aparecer" } });
  const registro = serializarErro(erro, {});
  assert.equal((registro.causa as { codigo: string }).codigo, "ECONNRESET");
  assert.equal(JSON.stringify(registro).includes("nao-deve-aparecer"), false);
});

test("logger emite JSON com o erro sanitizado e mantem estados de sucesso", () => {
  const original = console.error;
  let emitido = "";
  try {
    console.error = (texto: string) => { emitido = texto; };
    registrarMensageria("falha_outbox", "worker", Object.assign(new Error("Falha de teste"), { code: "P2021" }));
  } finally { console.error = original; }
  const registro = JSON.parse(emitido);
  assert.equal(registro.estado, "falha_outbox");
  assert.equal(registro.erro.codigo, "P2021");
  assert.match(registro.erro.stack, /Falha de teste/);
});
