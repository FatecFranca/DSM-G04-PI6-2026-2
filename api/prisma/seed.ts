import "dotenv/config";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { categoriasDoLocal } from "../src/models/categoriasComida";
import { prisma } from "../lib/prisma";

type CsvRow = Record<string, string>;

function parseCsv(content: string): CsvRow[] {
  const records: string[][] = [];
  let row: string[] = [];
  let field = "";
  let quoted = false;
  const text = content.replace(/^\uFEFF/, "");

  for (let i = 0; i < text.length; i += 1) {
    const char = text[i];
    if (char === '"') {
      if (quoted && text[i + 1] === '"') {
        field += '"';
        i += 1;
      } else quoted = !quoted;
    } else if (char === "," && !quoted) {
      row.push(field.trim());
      field = "";
    } else if ((char === "\n" || char === "\r") && !quoted) {
      if (char === "\r" && text[i + 1] === "\n") i += 1;
      row.push(field.trim());
      if (row.some((value) => value !== "")) records.push(row);
      row = [];
      field = "";
    } else field += char;
  }
  row.push(field.trim());
  if (row.some((value) => value !== "")) records.push(row);

  const headers = records.shift();
  if (!headers?.length) throw new Error("CSV sem cabeçalho ou sem registros.");
  return records.map((values, index) => {
    if (values.length !== headers.length) {
      throw new Error(`Registro ${index + 2}: esperado ${headers.length} colunas, recebido ${values.length}.`);
    }
    return Object.fromEntries(headers.map((header, column) => [header, values[column]]));
  });
}

function requiredText(row: CsvRow, column: string): string {
  const value = row[column]?.trim();
  if (!value) throw new Error(`Campo obrigatório '${column}' vazio no registro '${row.nome}'.`);
  return value;
}

function numberValue(row: CsvRow, column: string): number | null {
  const value = row[column]?.trim();
  if (!value) return null;
  // Alguns valores decimais exportados da planilha chegam com pontos de grupo
  // indevidos (por exemplo, 13.666.666.666.666.600 para 13.666666666666600).
  const normalized = value.includes(",")
    ? value.replace(/\./g, "").replace(",", ".")
    : value.includes(".")
      ? value.replace(/^(-?\d+)\.(.*)$/, (_match, integer: string, decimals: string) => `${integer}.${decimals.replace(/\./g, "")}`)
      : value;
  const parsed = Number(normalized);
  if (!Number.isFinite(parsed)) throw new Error(`Valor numérico inválido em '${column}': '${value}'.`);
  return parsed;
}

function booleanValue(row: CsvRow, column: string): boolean {
  const value = row[column]?.trim().toLowerCase();
  if (!value) return false;
  if (["1", "true", "sim"].includes(value)) return true;
  if (["0", "false", "não", "nao"].includes(value)) return false;
  throw new Error(`Valor booleano inválido em '${column}': '${value}'.`);
}

function normalize(value: string): string {
  return value.trim().toLocaleLowerCase("pt-BR");
}

async function main() {
  await prisma.tb_modelo_recomendacao.upsert({
    where: { versao: "fallback-v1" },
    create: { versao: "fallback-v1", algoritmo: "rule-based-fallback", status: "ready", trained_at: new Date() },
    update: { algoritmo: "rule-based-fallback", status: "ready" },
  });

  const csvPath = resolve(process.env.SEED_CSV_PATH ?? "prisma/seed/base_limpa - base_limpa.csv (2).csv");
  const rows = parseCsv(readFileSync(csvPath, "utf8"));
  if (rows.length === 0) throw new Error("Nenhum estabelecimento encontrado no CSV.");

  const data = rows.map((row) => {
    const avaliacao = numberValue(row, "nota");
    if (avaliacao === null) throw new Error(`Nota vazia no registro '${row.nome}'.`);
    const item = {
      nome: requiredText(row, "nome"),
      tipo: requiredText(row, "tipo"),
      faixa_preco: requiredText(row, "faixa_preco"),
      ambiente: requiredText(row, "ambiente"),
      publico: requiredText(row, "publico"),
      avaliacao,
      abre: requiredText(row, "abre"),
      fecha: requiredText(row, "fecha"),
      abre_min: numberValue(row, "abre_min"),
      fecha_min: numberValue(row, "fecha_min"),
      duracao_h: numberValue(row, "duracao_h"),
      fecha_apos_meia_noite: booleanValue(row, "fecha_apos_meia_noite"),
      aberto_manha: booleanValue(row, "aberto_manha"),
      aberto_almoco: booleanValue(row, "aberto_almoco"),
      aberto_tarde: booleanValue(row, "aberto_tarde"),
      aberto_noite: booleanValue(row, "aberto_noite"),
      aberto_madrugada: booleanValue(row, "aberto_madrugada"),
    };
    return { ...item, tags: categoriasDoLocal(item) };
  });

  // A tabela não possui uma chave única de negócio para nome. Buscar os nomes
  // atuais e atualizar por ID torna a carga repetível sem duplicar registros.
  const existing = await prisma.tb_estabelecimento.findMany({
    select: { id_estabelecimento: true, nome: true },
  });
  const existingByName = new Map(existing.map((item) => [normalize(item.nome), item.id_estabelecimento]));
  const operations = data.map((item) => {
    const id = existingByName.get(normalize(item.nome));
    return id
      ? prisma.tb_estabelecimento.update({ where: { id_estabelecimento: id }, data: item })
      : prisma.tb_estabelecimento.create({ data: item });
  });

  // Executa em lotes para manter o tamanho da transação controlado.
  const batchSize = 100;
  for (let offset = 0; offset < operations.length; offset += batchSize) {
    await prisma.$transaction(operations.slice(offset, offset + batchSize));
  }
  const updated = data.filter((item) => existingByName.has(normalize(item.nome))).length;
  console.log(`CSV importado: ${data.length - updated} inseridos, ${updated} atualizados, ${data.length} processados. Arquivo: ${csvPath}`);
}

main()
  .catch((error) => {
    console.error("Erro no seed:", error);
    process.exitCode = 1;
  })
  .finally(async () => prisma.$disconnect());
