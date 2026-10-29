import { EventoMensageria } from "./contrato";

export interface EventoPendente {
  id_evento: string;
  conteudo: EventoMensageria;
  tentativas: number;
}

export interface DependenciasPublicador {
  reservar(): Promise<EventoPendente | null>;
  publicar(evento: EventoMensageria): Promise<string>;
  confirmar(idEvento: string, idMensagem: string): Promise<void>;
  reagendar(idEvento: string, proximaTentativa: Date): Promise<void>;
  registrar(estado: string, id: string, erro?: unknown): void;
}

export async function publicarProximoEvento(dependencias: DependenciasPublicador): Promise<boolean> {
  const pendente = await dependencias.reservar();
  if (!pendente) return false;
  try {
    const idMensagem = await dependencias.publicar(pendente.conteudo);
    await dependencias.confirmar(pendente.id_evento, idMensagem);
    dependencias.registrar("publicado", pendente.id_evento);
  } catch (erro) {
    dependencias.registrar("falha_publicacao", pendente.id_evento, erro);
    const espera = Math.min(300000, 1000 * 2 ** Math.min(pendente.tentativas, 8));
    await dependencias.reagendar(pendente.id_evento, new Date(Date.now() + espera));
    dependencias.registrar("publicacao_reagendada", pendente.id_evento);
  }
  return true;
}
