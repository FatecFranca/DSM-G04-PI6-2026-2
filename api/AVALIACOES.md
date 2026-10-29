# Persistência das avaliações

- `POST /interacoes` com `tipo_evento: "rating"` e `valor` entre 1 e 5 grava a nota
  individual em `tb_interacao_usuario_estabelecimento`.
- Também cria `tb_classificacao` e `tb_classificacao_estabelecimento`, vinculando
  a nota ao autor, ao local e à interação original por `id_interacao`, na mesma transação.
  As listagens públicas evitam contar essa representação da mesma avaliação duas vezes.
- Na mesma transação, a API recalcula e salva `tb_estabelecimento.avaliacao` (média)
  e `tb_estabelecimento.total_avaliacoes` (quantidade de pessoas que avaliaram).
- A média usa somente a nota mais recente de cada pessoa por estabelecimento.
  Também considera notas de `tb_classificacao_estabelecimento`, sem contar a mesma
  pessoa duas vezes. O histórico de interações continua preservado.
- Com a mensageria ativada, o evento da interação é gravado na mesma transação.
  A gravação da nota e da média funciona também com a mensageria desativada.
- O cache de recomendações é invalidado quando a média muda.

`POST /classificacoes-estabelecimentos` aceita os campos opcionais `nota` (inteiro de
1 a 5) e `comentario` (até 2000 caracteres), além dos dois IDs obrigatórios. A nota
e o comentário são persistidos, e a média é recalculada ao criar ou excluir uma nota.

As consultas de detalhes e catálogo retornam a média e a contagem salvas.
`GET /interacoes/me/avaliacoes` retorna a última nota do usuário para cada local.
`GET /estabelecimentos/:id/avaliacoes` lista notas e comentários públicos.

A migration `20261023140000_media_avaliacoes` recalcula a média das avaliações já
existentes. Estabelecimentos sem avaliações de usuários mantêm a nota cadastrada;
ao receberem avaliações, passam a exibir a média dessas notas.

Após atualizar o código, execute `npm run prisma:generate` e `npm run prisma:migrate`
e reinicie a API. Os testes em PostgreSQL descartável estão em
`src/models/avaliacoes.integration.test.ts`, incluídos em `npm run test:integration`.
