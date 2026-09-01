# Backend Base

API REST em Node.js, Express, TypeScript e Prisma com autenticacao JWT, documentacao Swagger e CRUDs para organizacoes, cargos, permissoes, usuarios, logs e vinculos entre cargos/permissoes.

## Stack

- Node.js + Express
- TypeScript
- Prisma ORM com PostgreSQL
- Zod para validacao
- Swagger UI em `/docs`
- JWT para autenticacao

## Estrutura

- `app.ts`: bootstrap da API e registro das rotas
- `src/routes`: definicao dos endpoints
- `src/controllers`: validacao de entrada e respostas HTTP
- `src/models`: acesso aos dados via Prisma
- `src/types`: schemas Zod e contratos de entrada
- `src/docs/swagger.ts`: documento OpenAPI servido no Swagger UI
- `prisma/schema.prisma`: schema do banco
- `prisma/seed.ts`: carga inicial de dados

## Requisitos

- Node.js 20+
- Banco PostgreSQL acessivel pela `DATABASE_URL`

## Variaveis de ambiente

Crie um arquivo `.env` com pelo menos:

```env
DATABASE_URL=postgresql://usuario:senha@localhost:5432/banco
JWT_SECRET=uma-chave-segura
HOST=http://localhost:
PORT=3000
CORS_ORIGIN=http://localhost:3000
```

Observacoes:

- `HOST` e `PORT` sao usados na mensagem inicial da aplicacao e na URL base do Swagger.
- `CORS_ORIGIN` aceita `*`, uma origem unica ou varias separadas por virgula (ex.: `http://localhost:3000,http://localhost:5173`).
- O projeto falha ao iniciar se `DATABASE_URL` nao estiver configurada.
- Se `JWT_SECRET` nao for informado, a aplicacao usa um valor padrao apenas para desenvolvimento.

## Instalacao e execucao

```bash
npm install
npm run prisma:generate
npm run build
npm run dev
```

Para aplicar migrations existentes:

```bash
npm run prisma:migrate
```

Para popular o banco:

```bash
npx prisma db seed
```

## Endpoints

Base URL local padrao: `http://localhost:3000`

- `GET /`: healthcheck simples
- `POST /auth/login`: gera token JWT
- `POST|GET|PUT|DELETE /usuarios`
- `POST|GET|PUT|DELETE /organizacoes`
- `POST|GET|PUT|DELETE /cargos`
- `POST|GET|PUT|DELETE /permissoes`
- `POST|GET|PUT|DELETE /cargo-permissoes`
- `POST|GET|PUT|DELETE /logs`
- `POST|GET|PUT|DELETE /itens`

Documentacao interativa:

- `GET /docs`

## Autenticacao e permissao

O middleware de autenticacao espera o header:

```http
Authorization: Bearer <token>
```

Todas as rotas de CRUD usam autenticacao JWT e validacao de permissao por padrao.

As permissoes seguem o padrao `create_<recurso>`, `read_<recurso>`, `update_<recurso>` e `delete_<recurso>`.

Permissoes atualmente verificadas:

- `create_item`
- `read_item`
- `update_item`
- `delete_item`

O token JWT expira em 1 minuto (`JWT_EXPIRES_IN = "1m"` no middleware atual).

As rotas privadas usam expiracao deslizante por inatividade:
- Cada requisicao autenticada renova a sessao.
- A API devolve um token renovado nos headers `Authorization` e `x-access-token`.
- O middleware aceita `Authorization: Bearer <token>` e `x-access-token`.
- Sem atividade por mais de 1 minuto, a sessao expira.

## Comportamento atual importante

- O CRUD de `itens` esta roteado e documentado, mas a persistencia ainda nao existe no schema Prisma atual. O model em [`src/models/itens.ts`](/c:/Projetos/backend_base/src/models/itens.ts) retorna array vazio no `GET` e lanca erro nas operacoes de escrita.
- As rotas de usuarios retornam o campo `hash_senha` nas respostas porque os models devolvem o registro bruto do Prisma. Isso esta documentado porque faz parte do comportamento atual, mas vale tratar como melhoria de seguranca.
- O login aceita contas com senha legacy em texto puro e migra para bcrypt apos autenticacao bem-sucedida.

## Banco de dados

Entidades presentes no schema Prisma:

- `tb_organizacao`
- `tb_cargos`
- `tb_permissoes`
- `tb_cargo_permissoes`
- `tb_usuario`
- `tb_logs`

Relacionamentos principais:

- usuario pertence a uma organizacao e a um cargo
- cargo pertence a uma organizacao
- cargo possui varias permissoes via `tb_cargo_permissoes`
- log pertence a um usuario

## Seed

O seed atual cria:

- 10 organizacoes
- 10 cargos
- 10 permissoes
- 10 vinculos cargo/permissao
- 10 usuarios
- 10 logs

Senha padrao dos usuarios de seed: `123456`

## Observacoes de manutencao

- A documentacao Swagger em [`src/docs/swagger.ts`](/c:/Projetos/backend_base/src/docs/swagger.ts) foi ajustada para refletir o comportamento real do projeto em vez do comportamento idealizado.
- Existem comentarios e textos com problema de codificacao em alguns arquivos (`autenticacao`, `app.ts` e seed), mas isso nao impede o funcionamento da API.
