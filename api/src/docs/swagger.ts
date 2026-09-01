import {
  OpenAPIRegistry,
  OpenApiGeneratorV3,
  extendZodWithOpenApi,
} from "@asteasolutions/zod-to-openapi";
import { z } from "zod";
import dotenv from "dotenv";
import { loginSchema } from "../types/authSchema";
import { UsuarioSchema, UsuarioUpdateSchema } from "../types/usuario";
import {
  EstabelecimentoSchema,
  EstabelecimentoUpdateSchema,
} from "../types/estabelecimento";
import { ClassificacaoSchema, ClassificacaoUpdateSchema } from "../types/classificacao";
import { ClassificacaoEstabelecimentoSchema } from "../types/classificacaoEstabelecimento";
import { RecomendacoesQuerySchema } from "../types/recomendacao";
import { InteracaoCreateSchema } from "../types/interacao";

extendZodWithOpenApi(z);
dotenv.config();

const registry = new OpenAPIRegistry();

const idParamSchema = z.object({
  id: z.string().regex(/^\d+$/, "ID deve ser numerico"),
});

const classificacaoEstabelecimentoParamSchema = z.object({
  id_classificacao: z.string().regex(/^\d+$/, "id_classificacao deve ser numerico"),
  id_estabelecimento: z.string().regex(/^\d+$/, "id_estabelecimento deve ser numerico"),
});

const errorResponseSchema = z.object({
  success: z.boolean().optional(),
  message: z.string().optional(),
  error: z.string().optional(),
  errors: z.any().optional(),
});

const usuarioResponseSchema = UsuarioSchema.extend({
  id_usuario: z.number().int(),
});

const estabelecimentoResponseSchema = EstabelecimentoSchema.extend({
  id_estabelecimento: z.number().int(),
});

const classificacaoResponseSchema = ClassificacaoSchema.extend({
  id_classificacao: z.number().int(),
});

const classificacaoEstabelecimentoResponseSchema = ClassificacaoEstabelecimentoSchema;

const loginSuccessSchema = z.object({
  success: z.literal(true),
  token: z.string(),
});

const singleItemResponse = (itemSchema: z.ZodTypeAny) =>
  z.object({
    success: z.boolean(),
    data: itemSchema,
  });

const listResponse = (itemSchema: z.ZodTypeAny) =>
  z.object({
    success: z.boolean(),
    data: z.array(itemSchema),
  });

const deleteSuccessResponseSchema = z.object({
  success: z.literal(true),
  message: z.string(),
});

const unauthorizedResponse = {
  description: "Nao autorizado",
  content: { "application/json": { schema: errorResponseSchema } },
};

const registerProtectedPath = (input: Parameters<typeof registry.registerPath>[0]) => {
  registry.registerPath({
    ...input,
    security: [{ bearerAuth: [] }, { xAccessToken: [] }],
  });
};

registry.registerComponent("securitySchemes", "bearerAuth", {
  type: "http",
  scheme: "bearer",
  bearerFormat: "JWT",
});

registry.registerComponent("securitySchemes", "xAccessToken", {
  type: "apiKey",
  in: "header",
  name: "x-access-token",
});

registry.registerPath({
  method: "post",
  path: "/auth/login",
  description: "Realiza autenticacao do usuario e retorna token JWT.",
  tags: ["Auth"],
  request: {
    body: {
      content: {
        "application/json": {
          schema: loginSchema,
        },
      },
    },
  },
  responses: {
    200: {
      description: "Login realizado com sucesso",
      content: { "application/json": { schema: loginSuccessSchema } },
    },
    400: {
      description: "Dados invalidos",
      content: { "application/json": { schema: errorResponseSchema } },
    },
    401: {
      description: "Credenciais invalidas",
      content: { "application/json": { schema: errorResponseSchema } },
    },
    403: {
      description: "Usuario inativo",
      content: { "application/json": { schema: errorResponseSchema } },
    },
    500: {
      description: "Erro interno",
      content: { "application/json": { schema: errorResponseSchema } },
    },
  },
});

registerProtectedPath({
  method: "post",
  path: "/usuarios",
  description: "Cria um usuario.",
  tags: ["Usuarios"],
  request: {
    body: { content: { "application/json": { schema: UsuarioSchema } } },
  },
  responses: {
    201: {
      description: "Usuario criado com sucesso",
      content: { "application/json": { schema: singleItemResponse(usuarioResponseSchema) } },
    },
    400: {
      description: "Erro de validacao ou regra de negocio",
      content: { "application/json": { schema: errorResponseSchema } },
    },
    500: {
      description: "Erro interno",
      content: { "application/json": { schema: errorResponseSchema } },
    },
    401: unauthorizedResponse,
  },
});

registerProtectedPath({
  method: "get",
  path: "/usuarios",
  description: "Lista usuarios.",
  tags: ["Usuarios"],
  responses: {
    200: {
      description: "Usuarios listados com sucesso",
      content: { "application/json": { schema: listResponse(usuarioResponseSchema) } },
    },
    500: {
      description: "Erro interno",
      content: { "application/json": { schema: errorResponseSchema } },
    },
    401: unauthorizedResponse,
  },
});

registerProtectedPath({
  method: "get",
  path: "/usuarios/{id}",
  description: "Busca usuario por ID.",
  tags: ["Usuarios"],
  request: { params: idParamSchema },
  responses: {
    200: {
      description: "Usuario encontrado",
      content: { "application/json": { schema: singleItemResponse(usuarioResponseSchema) } },
    },
    400: {
      description: "ID invalido",
      content: { "application/json": { schema: errorResponseSchema } },
    },
    404: {
      description: "Registro nao encontrado",
      content: { "application/json": { schema: errorResponseSchema } },
    },
    500: {
      description: "Erro interno",
      content: { "application/json": { schema: errorResponseSchema } },
    },
    401: unauthorizedResponse,
  },
});

registerProtectedPath({
  method: "put",
  path: "/usuarios/{id}",
  description: "Atualiza usuario por ID.",
  tags: ["Usuarios"],
  request: {
    params: idParamSchema,
    body: { content: { "application/json": { schema: UsuarioUpdateSchema } } },
  },
  responses: {
    200: {
      description: "Usuario atualizado com sucesso",
      content: { "application/json": { schema: singleItemResponse(usuarioResponseSchema) } },
    },
    400: {
      description: "Erro de validacao ou ID invalido",
      content: { "application/json": { schema: errorResponseSchema } },
    },
    404: {
      description: "Registro nao encontrado",
      content: { "application/json": { schema: errorResponseSchema } },
    },
    500: {
      description: "Erro interno",
      content: { "application/json": { schema: errorResponseSchema } },
    },
    401: unauthorizedResponse,
  },
});

registerProtectedPath({
  method: "delete",
  path: "/usuarios/{id}",
  description: "Remove usuario por ID.",
  tags: ["Usuarios"],
  request: { params: idParamSchema },
  responses: {
    200: {
      description: "Usuario removido com sucesso",
      content: { "application/json": { schema: deleteSuccessResponseSchema } },
    },
    400: {
      description: "ID invalido",
      content: { "application/json": { schema: errorResponseSchema } },
    },
    404: {
      description: "Registro nao encontrado",
      content: { "application/json": { schema: errorResponseSchema } },
    },
    500: {
      description: "Erro interno",
      content: { "application/json": { schema: errorResponseSchema } },
    },
    401: unauthorizedResponse,
  },
});

registerProtectedPath({
  method: "post",
  path: "/estabelecimentos",
  description: "Cria um estabelecimento.",
  tags: ["Estabelecimentos"],
  request: {
    body: { content: { "application/json": { schema: EstabelecimentoSchema } } },
  },
  responses: {
    201: {
      description: "Estabelecimento criado com sucesso",
      content: { "application/json": { schema: singleItemResponse(estabelecimentoResponseSchema) } },
    },
    400: {
      description: "Erro de validacao",
      content: { "application/json": { schema: errorResponseSchema } },
    },
    500: {
      description: "Erro interno",
      content: { "application/json": { schema: errorResponseSchema } },
    },
    401: unauthorizedResponse,
  },
});

registerProtectedPath({
  method: "get",
  path: "/estabelecimentos",
  description: "Lista estabelecimentos.",
  tags: ["Estabelecimentos"],
  responses: {
    200: {
      description: "Estabelecimentos listados com sucesso",
      content: { "application/json": { schema: listResponse(estabelecimentoResponseSchema) } },
    },
    500: {
      description: "Erro interno",
      content: { "application/json": { schema: errorResponseSchema } },
    },
    401: unauthorizedResponse,
  },
});

registerProtectedPath({
  method: "get",
  path: "/estabelecimentos/{id}",
  description: "Busca estabelecimento por ID.",
  tags: ["Estabelecimentos"],
  request: { params: idParamSchema },
  responses: {
    200: {
      description: "Estabelecimento encontrado",
      content: { "application/json": { schema: singleItemResponse(estabelecimentoResponseSchema) } },
    },
    400: {
      description: "ID invalido",
      content: { "application/json": { schema: errorResponseSchema } },
    },
    404: {
      description: "Registro nao encontrado",
      content: { "application/json": { schema: errorResponseSchema } },
    },
    500: {
      description: "Erro interno",
      content: { "application/json": { schema: errorResponseSchema } },
    },
    401: unauthorizedResponse,
  },
});

registerProtectedPath({
  method: "put",
  path: "/estabelecimentos/{id}",
  description: "Atualiza estabelecimento por ID.",
  tags: ["Estabelecimentos"],
  request: {
    params: idParamSchema,
    body: { content: { "application/json": { schema: EstabelecimentoUpdateSchema } } },
  },
  responses: {
    200: {
      description: "Estabelecimento atualizado com sucesso",
      content: { "application/json": { schema: singleItemResponse(estabelecimentoResponseSchema) } },
    },
    400: {
      description: "Erro de validacao ou ID invalido",
      content: { "application/json": { schema: errorResponseSchema } },
    },
    404: {
      description: "Registro nao encontrado",
      content: { "application/json": { schema: errorResponseSchema } },
    },
    500: {
      description: "Erro interno",
      content: { "application/json": { schema: errorResponseSchema } },
    },
    401: unauthorizedResponse,
  },
});

registerProtectedPath({
  method: "delete",
  path: "/estabelecimentos/{id}",
  description: "Remove estabelecimento por ID.",
  tags: ["Estabelecimentos"],
  request: { params: idParamSchema },
  responses: {
    200: {
      description: "Estabelecimento removido com sucesso",
      content: { "application/json": { schema: deleteSuccessResponseSchema } },
    },
    400: {
      description: "ID invalido",
      content: { "application/json": { schema: errorResponseSchema } },
    },
    404: {
      description: "Registro nao encontrado",
      content: { "application/json": { schema: errorResponseSchema } },
    },
    500: {
      description: "Erro interno",
      content: { "application/json": { schema: errorResponseSchema } },
    },
    401: unauthorizedResponse,
  },
});

registerProtectedPath({
  method: "post",
  path: "/classificacoes",
  description: "Cria uma classificacao.",
  tags: ["Classificacoes"],
  request: {
    body: { content: { "application/json": { schema: ClassificacaoSchema } } },
  },
  responses: {
    201: {
      description: "Classificacao criada com sucesso",
      content: { "application/json": { schema: singleItemResponse(classificacaoResponseSchema) } },
    },
    400: {
      description: "Erro de validacao",
      content: { "application/json": { schema: errorResponseSchema } },
    },
    500: {
      description: "Erro interno",
      content: { "application/json": { schema: errorResponseSchema } },
    },
    401: unauthorizedResponse,
  },
});

registerProtectedPath({
  method: "get",
  path: "/classificacoes",
  description: "Lista classificacoes.",
  tags: ["Classificacoes"],
  responses: {
    200: {
      description: "Classificacoes listadas com sucesso",
      content: { "application/json": { schema: listResponse(classificacaoResponseSchema) } },
    },
    500: {
      description: "Erro interno",
      content: { "application/json": { schema: errorResponseSchema } },
    },
    401: unauthorizedResponse,
  },
});

registerProtectedPath({
  method: "get",
  path: "/classificacoes/{id}",
  description: "Busca classificacao por ID.",
  tags: ["Classificacoes"],
  request: { params: idParamSchema },
  responses: {
    200: {
      description: "Classificacao encontrada",
      content: { "application/json": { schema: singleItemResponse(classificacaoResponseSchema) } },
    },
    400: {
      description: "ID invalido",
      content: { "application/json": { schema: errorResponseSchema } },
    },
    404: {
      description: "Registro nao encontrado",
      content: { "application/json": { schema: errorResponseSchema } },
    },
    500: {
      description: "Erro interno",
      content: { "application/json": { schema: errorResponseSchema } },
    },
    401: unauthorizedResponse,
  },
});

registerProtectedPath({
  method: "put",
  path: "/classificacoes/{id}",
  description: "Atualiza classificacao por ID.",
  tags: ["Classificacoes"],
  request: {
    params: idParamSchema,
    body: { content: { "application/json": { schema: ClassificacaoUpdateSchema } } },
  },
  responses: {
    200: {
      description: "Classificacao atualizada com sucesso",
      content: { "application/json": { schema: singleItemResponse(classificacaoResponseSchema) } },
    },
    400: {
      description: "Erro de validacao ou ID invalido",
      content: { "application/json": { schema: errorResponseSchema } },
    },
    404: {
      description: "Registro nao encontrado",
      content: { "application/json": { schema: errorResponseSchema } },
    },
    500: {
      description: "Erro interno",
      content: { "application/json": { schema: errorResponseSchema } },
    },
    401: unauthorizedResponse,
  },
});

registerProtectedPath({
  method: "delete",
  path: "/classificacoes/{id}",
  description: "Remove classificacao por ID.",
  tags: ["Classificacoes"],
  request: { params: idParamSchema },
  responses: {
    200: {
      description: "Classificacao removida com sucesso",
      content: { "application/json": { schema: deleteSuccessResponseSchema } },
    },
    400: {
      description: "ID invalido",
      content: { "application/json": { schema: errorResponseSchema } },
    },
    404: {
      description: "Registro nao encontrado",
      content: { "application/json": { schema: errorResponseSchema } },
    },
    500: {
      description: "Erro interno",
      content: { "application/json": { schema: errorResponseSchema } },
    },
    401: unauthorizedResponse,
  },
});

registerProtectedPath({
  method: "post",
  path: "/classificacoes-estabelecimentos",
  description: "Cria o relacionamento entre classificacao e estabelecimento.",
  tags: ["ClassificacoesEstabelecimentos"],
  request: {
    body: {
      content: {
        "application/json": {
          schema: ClassificacaoEstabelecimentoSchema,
        },
      },
    },
  },
  responses: {
    201: {
      description: "Relacionamento criado com sucesso",
      content: {
        "application/json": {
          schema: singleItemResponse(classificacaoEstabelecimentoResponseSchema),
        },
      },
    },
    400: {
      description: "Erro de validacao",
      content: { "application/json": { schema: errorResponseSchema } },
    },
    500: {
      description: "Erro interno",
      content: { "application/json": { schema: errorResponseSchema } },
    },
    401: unauthorizedResponse,
  },
});

registerProtectedPath({
  method: "get",
  path: "/classificacoes-estabelecimentos",
  description: "Lista relacionamentos entre classificacoes e estabelecimentos.",
  tags: ["ClassificacoesEstabelecimentos"],
  responses: {
    200: {
      description: "Relacionamentos listados com sucesso",
      content: {
        "application/json": {
          schema: listResponse(classificacaoEstabelecimentoResponseSchema),
        },
      },
    },
    500: {
      description: "Erro interno",
      content: { "application/json": { schema: errorResponseSchema } },
    },
    401: unauthorizedResponse,
  },
});

registerProtectedPath({
  method: "get",
  path: "/classificacoes-estabelecimentos/{id_classificacao}/{id_estabelecimento}",
  description: "Busca relacionamento por chave composta.",
  tags: ["ClassificacoesEstabelecimentos"],
  request: { params: classificacaoEstabelecimentoParamSchema },
  responses: {
    200: {
      description: "Relacionamento encontrado",
      content: {
        "application/json": {
          schema: singleItemResponse(classificacaoEstabelecimentoResponseSchema),
        },
      },
    },
    400: {
      description: "IDs invalidos",
      content: { "application/json": { schema: errorResponseSchema } },
    },
    404: {
      description: "Registro nao encontrado",
      content: { "application/json": { schema: errorResponseSchema } },
    },
    500: {
      description: "Erro interno",
      content: { "application/json": { schema: errorResponseSchema } },
    },
    401: unauthorizedResponse,
  },
});

registerProtectedPath({
  method: "delete",
  path: "/classificacoes-estabelecimentos/{id_classificacao}/{id_estabelecimento}",
  description: "Remove relacionamento por chave composta.",
  tags: ["ClassificacoesEstabelecimentos"],
  request: { params: classificacaoEstabelecimentoParamSchema },
  responses: {
    200: {
      description: "Relacionamento removido com sucesso",
      content: { "application/json": { schema: deleteSuccessResponseSchema } },
    },
    400: {
      description: "IDs invalidos",
      content: { "application/json": { schema: errorResponseSchema } },
    },
    404: {
      description: "Registro nao encontrado",
      content: { "application/json": { schema: errorResponseSchema } },
    },
    500: {
      description: "Erro interno",
      content: { "application/json": { schema: errorResponseSchema } },
    },
    401: unauthorizedResponse,
  },
});

registerProtectedPath({
  method: "get",
  path: "/recomendacoes",
  description: "Lista recomendacoes personalizadas (cache ou ranking fallback por preferencias de like/dislike).",
  tags: ["Recomendacoes"],
  request: { query: RecomendacoesQuerySchema },
  responses: {
    200: {
      description: "Recomendacoes retornadas",
      content: { "application/json": { schema: errorResponseSchema } },
    },
    400: {
      description: "Parametros invalidos",
      content: { "application/json": { schema: errorResponseSchema } },
    },
    401: unauthorizedResponse,
    500: {
      description: "Erro interno",
      content: { "application/json": { schema: errorResponseSchema } },
    },
  },
});

registerProtectedPath({
  method: "get",
  path: "/recomendacoes/ia-sugestoes",
  description: "Sugestoes por IA baseadas nos estabelecimentos que o usuario curtiu (semelhanca de perfil).",
  tags: ["Recomendacoes"],
  request: {
    query: z.object({
      limit: z.coerce.number().int().min(1).max(50).optional(),
    }),
  },
  responses: {
    200: {
      description: "Sugestoes geradas",
      content: { "application/json": { schema: errorResponseSchema } },
    },
    401: unauthorizedResponse,
    500: {
      description: "Erro interno",
      content: { "application/json": { schema: errorResponseSchema } },
    },
  },
});

registerProtectedPath({
  method: "post",
  path: "/interacoes",
  description: "Registra interacao do usuario com estabelecimento (view, like, dislike, etc.).",
  tags: ["Interacoes"],
  request: {
    body: { content: { "application/json": { schema: InteracaoCreateSchema } } },
  },
  responses: {
    201: {
      description: "Interacao criada",
      content: { "application/json": { schema: errorResponseSchema } },
    },
    400: {
      description: "Dados invalidos",
      content: { "application/json": { schema: errorResponseSchema } },
    },
    401: unauthorizedResponse,
    500: {
      description: "Erro interno",
      content: { "application/json": { schema: errorResponseSchema } },
    },
  },
});

registerProtectedPath({
  method: "get",
  path: "/interacoes/me",
  description: "Lista interacoes do usuario autenticado.",
  tags: ["Interacoes"],
  request: {
    query: z.object({
      limit: z.coerce.number().int().min(1).max(300).optional(),
    }),
  },
  responses: {
    200: {
      description: "Lista de interacoes",
      content: { "application/json": { schema: errorResponseSchema } },
    },
    401: unauthorizedResponse,
    500: {
      description: "Erro interno",
      content: { "application/json": { schema: errorResponseSchema } },
    },
  },
});

const generator = new OpenApiGeneratorV3(registry.definitions);

const hostFromEnv = process.env.HOST?.trim();
const parsedHost = hostFromEnv
  ? (() => {
      try {
        return new URL(hostFromEnv);
      } catch {
        return null;
      }
    })()
  : null;
const port = Number(process.env.PORT ?? parsedHost?.port ?? 3000);
const serverUrl =
  hostFromEnv && parsedHost
    ? `${parsedHost.protocol}//${parsedHost.hostname}:${port}`
    : `http://localhost:${port}`;

export const openApiDocument = generator.generateDocument({
  openapi: "3.0.0",
  info: {
    title: "API Backend Base",
    version: "1.0.0",
    description: "Documentacao da API",
  },
  servers: [{ url: serverUrl }],
});
