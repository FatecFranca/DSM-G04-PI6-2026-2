import { PubSub } from "@google-cloud/pubsub";
import { lerConfiguracaoMensageria } from "./configuracao";
import { EventoMensageria } from "./contrato";

export function criarConexaoMensageria() {
  const configuracao = lerConfiguracaoMensageria();
  if (configuracao.PUBSUB_ATIVO !== "true") throw new Error("Ative PUBSUB_ATIVO=true para iniciar o worker");
  // ADC: nenhuma chave ou token e recebido ou registrado pelo codigo.
  const cliente = new PubSub({ projectId: configuracao.GOOGLE_CLOUD_PROJECT });
  const topico = cliente.topic(configuracao.PUBSUB_TOPICO!, {
    gaxOpts: { timeout: 30000, retry: null },
  });
  const assinatura = cliente.subscription(configuracao.PUBSUB_ASSINATURA!, {
    flowControl: { maxMessages: configuracao.PUBSUB_CONCORRENCIA, allowExcessMessages: false },
  });
  return {
    assinatura,
    async publicar(evento: EventoMensageria) {
      return topico.publishMessage({ json: evento, attributes: { tipo: evento.tipo, versao: "1" } });
    },
    async fechar() {
      await assinatura.close();
      await topico.flush();
      await cliente.close();
    },
  };
}
