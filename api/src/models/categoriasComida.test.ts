import { test } from "node:test";
import assert from "node:assert/strict";
import { categoriasSalvas, correspondeCategoria } from "./categoriasComida";

test("pizza e massas excluem restaurante generico e japones", () => {
  for (const categoria of ["Pizza", "Massas"]) {
    assert.equal(correspondeCategoria({ nome: "TutiYa Sushi Bar - Comida Japonesa", tipo: "restaurante" }, categoriasSalvas(categoria)), false);
    assert.equal(correspondeCategoria({ nome: "Local generico", tipo: "restaurante" }, categoriasSalvas(categoria)), false);
  }
  assert.equal(correspondeCategoria({ nome: "Mozzarella", tipo: "pizzaria" }, ["pizza"]), true);
  assert.equal(correspondeCategoria({ nome: "Cantina da Nonna", tipo: "restaurante" }, ["massas"]), true);
  assert.equal(correspondeCategoria({ nome: "Local", tipo: "restaurante", tags: ["massas"] }, ["massas", "pizza"]), true);
});

