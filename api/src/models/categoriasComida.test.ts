import { test } from "node:test";
import assert from "node:assert/strict";
import { categoriasSalvas, correspondeCategoria } from "./categoriasComida";
import { PreferenciasUsuarioSchema } from "../types/usuario";

test("pizza e massas excluem restaurante generico e japones", () => {
  for (const categoria of ["Pizza", "Massas"]) {
    assert.equal(correspondeCategoria({ nome: "TutiYa Sushi Bar - Comida Japonesa", tipo: "restaurante" }, categoriasSalvas(categoria)), false);
    assert.equal(correspondeCategoria({ nome: "Local generico", tipo: "restaurante" }, categoriasSalvas(categoria)), false);
  }
  assert.equal(correspondeCategoria({ nome: "Mozzarella", tipo: "pizzaria" }, ["pizza"]), true);
  assert.equal(correspondeCategoria({ nome: "Cantina da Nonna", tipo: "restaurante" }, ["massas"]), true);
  assert.equal(correspondeCategoria({ nome: "Local", tipo: "restaurante", tags: ["massas"] }, ["massas", "pizza"]), true);
});

test("preferencias aceitam listas e continuam lendo formato antigo", () => {
  const base = { categoria: "Pizza", sabor: "Salgado", faixa_preco: "Medio", quantidade_pessoas: "1 pessoa", restricao_alimentar: "Nenhuma", modalidade_consumo: "Entrega" };
  assert.deepEqual(PreferenciasUsuarioSchema.parse(base).categoria, ["Pizza"]);
  const varias = PreferenciasUsuarioSchema.parse({ ...base, categoria: ["Pizza", "Massas"], restricao_alimentar: ["Sem lactose", "Sem gl?ten"] });
  assert.equal(varias.categoria.length, 2);
  assert.equal(varias.restricao_alimentar.length, 2);
  assert.equal(PreferenciasUsuarioSchema.safeParse({ ...base, categoria: [] }).success, false);
  assert.equal(PreferenciasUsuarioSchema.safeParse({ ...base, restricao_alimentar: ["Nenhuma", "Vegana"] }).success, false);
});
