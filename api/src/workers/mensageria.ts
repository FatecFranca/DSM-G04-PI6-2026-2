import "../../lib/ambiente";
import { registrarMensageria } from "../mensageria/log";
import { setTimeout as esperar } from "node:timers/promises";
import { Message } from "@google-cloud/pubsub";
import { prisma } from "../../lib/prisma";
import { criarConexaoMensageria } from "../mensageria/cliente";
import { consumirMensagem } from "../mensageria/consumidor";
import { publicarProximoEvento } from "../mensageria/publicador";
import { confirmarPublicacao, processarEventoMensageria, reagendarPublicacao,
  registrarQuarentena, reservarEventoPendente } from "../mensageria/persistencia";

async function iniciar() {
  // Falha cedo se o banco ou as migrations nao estiverem prontos, antes de consumir.
  await prisma.$connect();
  await Promise.all([
    prisma.tb_evento_outbox.findFirst({ select: { id_evento: true } }),
    prisma.tb_evento_processado.findFirst({ select: { id_evento: true } }),
    prisma.tb_mensagem_quarentena.findFirst({ select: { chave: true } }),
    prisma.tb_notificacao.findFirst({ select: { id_notificacao: true } }),
  ]);
  registrarMensageria("banco_verificado", "worker");
  const conexao = criarConexaoMensageria();
  const tarefas = new Set<Promise<void>>();
  let encerrando = false;
  let encerramento: Promise<void> | undefined;
  const registrar = registrarMensageria;
  const aoReceber = (mensagem: Message) => {
    if (encerrando) { mensagem.nack(); return; }
    const tarefa = consumirMensagem(mensagem, {
      processar: processarEventoMensageria, quarentena: registrarQuarentena, registrar,
    });
    tarefas.add(tarefa);
    void tarefa.finally(() => tarefas.delete(tarefa)).catch((erro) => registrar("falha_consumidor", mensagem.id, erro));
  };
  conexao.assinatura.on("message", aoReceber);
  const publicacao = (async () => {
    while (!encerrando) {
      try {
        const publicou = await publicarProximoEvento({
          reservar: reservarEventoPendente, publicar: conexao.publicar,
          confirmar: confirmarPublicacao, reagendar: reagendarPublicacao, registrar,
        });
        if (!publicou) await esperar(1000);
      } catch (erro) {
        registrar("falha_outbox", "worker", erro);
        await esperar(5000);
      }
    }
  })();
  function encerrar() {
    if (encerramento) return encerramento;
    encerrando = true;
    // Se uma chamada externa travar, o supervisor pode reiniciar o processo.
    // Eventos sem commit/ack e leases vencidos serao retomados.
    const prazo = setTimeout(() => process.exit(1), 90000);
    prazo.unref();
    encerramento = (async () => {
      await publicacao;
      await Promise.allSettled([...tarefas]);
      await conexao.fechar();
      await prisma.$disconnect();
      clearTimeout(prazo);
    })();
    return encerramento;
  }
  process.once("SIGINT", () => void encerrar().catch(() => process.exit(1)));
  process.once("SIGTERM", () => void encerrar().catch(() => process.exit(1)));
  conexao.assinatura.on("error", (erro) => {
    registrar("falha_assinatura", "worker", erro);
    process.exitCode = 1;
    void encerrar().catch(() => process.exit(1));
  });
  registrar("iniciado", "worker");
}

void iniciar().catch(async (erro) => {
  registrarMensageria("falha_inicializacao", "worker", erro);
  await prisma.$disconnect();
  process.exitCode = 1;
});
