import express from "express";
import swaggerUi from "swagger-ui-express";
import cors from "cors";
import { openApiDocument } from "./src/docs/swagger";
import authRoutes from "./src/routes/auth";
import usuariosRoutes from "./src/routes/usuarios";
import estabelecimentosRoutes from "./src/routes/estabelecimentos";
import classificacoesRoutes from "./src/routes/classificacoes";
import classificacoesEstabelecimentosRoutes from "./src/routes/classificacoesEstabelecimentos";
import recomendacoesRoutes from "./src/routes/recomendacoes";
import interacoesRoutes from "./src/routes/interacoes";

require("dotenv").config();

const normalizeOrigin = (value: string) => value.trim().replace(/\/$/, "");
const rawCorsOrigin = process.env.CORS_ORIGIN?.trim();
const allowAllOrigins = !rawCorsOrigin || rawCorsOrigin === "*";
const allowedOrigins = (rawCorsOrigin ?? "")
  .split(",")
  .map((origin) => normalizeOrigin(origin))
  .filter(Boolean);

const corsOptions: cors.CorsOptions = {
  origin: (origin, callback) => {
    if (allowAllOrigins || !origin || origin === "null") {
      callback(null, true);
      return;
    }

    if (allowedOrigins.includes(normalizeOrigin(origin))) {
      callback(null, true);
      return;
    }

    callback(new Error(`CORS bloqueado para a origem: ${origin}`));
  },
};

const app = express();

app.use(express.json());
app.use(cors(corsOptions));
app.use(express.static("public"));

app.options("*", cors(corsOptions));
app.use((req, res, next) => {
  res.setHeader("Access-Control-Expose-Headers", "Authorization, x-access-token");
  next();
});

app.use("/auth", authRoutes);
app.use("/usuarios", usuariosRoutes);
app.use("/estabelecimentos", estabelecimentosRoutes);
app.use("/classificacoes", classificacoesRoutes);
app.use("/classificacoes-estabelecimentos", classificacoesEstabelecimentosRoutes);
app.use("/recomendacoes", recomendacoesRoutes);
app.use("/interacoes", interacoesRoutes);



app.use("/docs", swaggerUi.serve, swaggerUi.setup(openApiDocument));

app.get("/", (req, res) => {
  res.status(200).json({
    message: "API em funcionamento " + new Date().toISOString(),
    endpoints: "Acesse /docs para ver a documentacao da API",
  });
});

const hostFromEnv = process.env.HOST?.trim();
const parsedHost = hostFromEnv ? new URL(hostFromEnv) : null;
const port = Number(process.env.PORT ?? parsedHost?.port ?? 3000);
const host = hostFromEnv ?? `http://localhost:${port}`;

app.listen(port, () => {
  console.log(`\nSERVIDOR INICIADO COM SUCESSO\nURL  -> ${host}\nDOCS -> ${host}/docs\n`);
});
