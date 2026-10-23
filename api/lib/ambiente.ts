import { config } from "dotenv";
import { basename, resolve } from "node:path";

// Usa api/.env tanto em src/ts-node quanto no JavaScript de dist/.
// Variaveis explicitamente fornecidas pelo ambiente continuam tendo prioridade.
const pastaPai = resolve(__dirname, "..");
export const caminhoAmbiente = resolve(basename(pastaPai) === "dist" ? resolve(pastaPai, "..") : pastaPai, ".env");
config({ path: caminhoAmbiente });
