import { createHash } from "node:crypto";
import { EventoMensageria, EventoMensageriaSchema, ErroMensagemInvalida } from "./contrato";

export interface MensagemRecebida {
  id: string;
  data: Buffer;
  ack(): void;
  nack(): void;
}

export interface DependenciasConsumidor {
  processar(evento: EventoMensageria): Promise<"processado" | "duplicado">;
  quarentena(registro: { chave: string; id_mensagem: string; conteudo: Buffer; motivo: string }): Promise<void>;
  registrar(estado: string, id: string, erro?: unknown): void;
}

export async function consumirMensagem(mensagem: MensagemRecebida, dependencias: DependenciasConsumidor) {
  try {
    let evento: EventoMensageria;
    try {
      if (mensagem.data.length > 65536) throw new Error("Tamanho excedido");
      evento = EventoMensageriaSchema.parse(JSON.parse(mensagem.data.toString("utf8")));
    } catch {
      throw new ErroMensagemInvalida("JSON ou contrato de interacao invalido");
    }
    const estado = await dependencias.processar(evento);
    mensagem.ack();
    dependencias.registrar(estado, evento.id_evento);
  } catch (erro) {
    if (erro instanceof ErroMensagemInvalida) {
      try {
        await dependencias.quarentena({
          chave: createHash("sha256").update(mensagem.id).update(mensagem.data).digest("hex"),
          id_mensagem: mensagem.id,
          conteudo: mensagem.data,
          motivo: erro.message,
        });
      } catch (erroQuarentena) {
        mensagem.nack();
        dependencias.registrar("quarentena_indisponivel", mensagem.id, erroQuarentena);
        return;
      }
      mensagem.ack();
      dependencias.registrar("quarentena", mensagem.id);
      return;
    }
    mensagem.nack();
    dependencias.registrar("nova_tentativa", mensagem.id, erro);
  }
}
