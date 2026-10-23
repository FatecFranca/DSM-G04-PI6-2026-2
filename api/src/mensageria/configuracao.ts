import { z } from "zod";

const ConfiguracaoSchema = z.object({
  PUBSUB_ATIVO: z.enum(["true", "false"]).default("false"),
  GOOGLE_CLOUD_PROJECT: z.string().trim().min(1).optional(),
  PUBSUB_TOPICO: z.string().trim().min(1).optional(),
  PUBSUB_ASSINATURA: z.string().trim().min(1).optional(),
  PUBSUB_CONCORRENCIA: z.coerce.number().int().min(1).max(100).default(5),
});

export function lerConfiguracaoMensageria(ambiente: NodeJS.ProcessEnv = process.env) {
  const configuracao = ConfiguracaoSchema.parse(ambiente);
  if (configuracao.PUBSUB_ATIVO === "true" &&
      (!configuracao.GOOGLE_CLOUD_PROJECT || !configuracao.PUBSUB_TOPICO || !configuracao.PUBSUB_ASSINATURA)) {
    throw new Error("Configure GOOGLE_CLOUD_PROJECT, PUBSUB_TOPICO e PUBSUB_ASSINATURA para ativar o Pub/Sub");
  }
  return configuracao;
}

export function mensageriaAtiva() {
  return lerConfiguracaoMensageria().PUBSUB_ATIVO === "true";
}
