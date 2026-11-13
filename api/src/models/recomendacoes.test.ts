import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { recomendar } from "./recomendacoes";

const arquivo = (nome: string) => {
  const caminhos = [resolve(__dirname, "../../..", nome), resolve(__dirname, "../..", nome)];
  const caminho = caminhos.find(candidato => { try { readFileSync(candidato); return true; } catch { return false; } });
  if (!caminho) throw new Error(`Arquivo ausente: ${nome}`);
  return JSON.parse(readFileSync(caminho, "utf8"));
};

test("resposta do motor TypeScript reproduz o exemplo de resposta", () => {
  const entrada = arquivo("exemplo_requisicao.json");
  const esperado = arquivo("exemplo_resposta.json");
  assert.deepEqual(recomendar(entrada.respostas, entrada.k, entrada.agora_min), esperado);
});

test("valida opcoes do modelo e filtra periodo e horario selecionados", () => {
  assert.throws(() => recomendar({ tipo: ["tipo-inexistente"] }, 5), /Valores inválidos/);
  const resultado = recomendar({ tipo: ["pizzaria"], periodo: ["noite"] }, 10, 12 * 60);
  assert.ok(resultado.length > 0);
  assert.ok(resultado.every(item => item.aberto_agora === true || item.fora_do_filtro));
});

test("resposta vazia ordena pela qualidade minerada", () => {
  const resultado = recomendar({}, 3, null, false);
  const modelo = arquivo("modelo_recomendacao.json");
  const qualidades = [...modelo.estabelecimentos].sort((a: any, b: any) => b.qualidade - a.qualidade || a.id - b.id);
  assert.deepEqual(resultado.map(item => item.id), qualidades.slice(0, 3).map((item: any) => item.id));
});
