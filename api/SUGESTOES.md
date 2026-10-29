# Sugestões automáticas por mensageria

Ao avaliar um local no aplicativo, a API salva a nota e o evento da interação na
mesma transação. O worker publica na infraestrutura Google Pub/Sub existente.
O consumidor invalida o cache e prepara até dez sugestões para a pessoa que avaliou.

A lista é persistida em `tb_usuario_feature_snapshot`, com
`model_version = sugestoes-automaticas-v1`, e também em `tb_recomendacao_cache`.
Os metadados do algoritmo por regras são registrados em `tb_modelo_recomendacao`.
A preparação da lista e o registro do
evento processado são confirmados na mesma transação. Em caso de falha, ambos são
desfeitos e a mensagem pode ser entregue novamente. Reentregas não geram outro efeito.
Entregas de eventos diferentes para a mesma conta são serializadas; o cálculo usa
o histórico atual, evitando que eventos antigos restaurem preferências ultrapassadas.

## Critérios

- Notas 4 e 5 favorecem perfis semelhantes ao estabelecimento avaliado.
- Notas 1 e 2 reduzem a preferência por essas características.
- Nota 3 é neutra. A opinião mais recente prevalece, incluindo likes, dislikes e
  a desmarcação (`neutral`). Só é considerada uma opinião por pessoa e local.
- O cálculo usa tipo de estabelecimento, faixa de preço, ambiente, preferências
  informadas e avaliação pública. É um ranking por regras, sem treinamento de modelo.
- Lugares já avaliados ou com histórico de opinião são excluídos das sugestões
  automáticas. Estabelecimentos inativos são filtrados também na consulta.
- São considerados até 250 candidatos ativos e até 300 registros recentes de cada
  origem de avaliação. A lista pode ter menos de dez opções se houver poucos locais.

Notas cadastradas ou excluídas em classificações também geram
`preferencias.atualizadas`. Os comentários sem nota não alteram as sugestões.
As preferências da tela Avaliar são aprendidas diretamente pela nota, sem gravar
uma curtida ou rejeição auxiliar.

## Consulta e aplicativo

`GET /recomendacoes/automaticas` exige Bearer JWT e retorna somente a lista da conta
autenticada, com `source: "mensageria"`, `atualizado_em` e `data`.

O catálogo exibe a seção “Sugestões com base nas suas avaliações” quando há opções
preparadas. A seção consulta a lista a cada 15 segundos enquanto a tela está visível
e o aplicativo está ativo, sem exigir que o usuário atualize a página. Também consulta
ao retomar o aplicativo e ao voltar dos detalhes abertos por uma sugestão.

Até o primeiro evento ser processado, a lista fica vazia. Se o worker estiver parado,
os eventos ficam na outbox e a última lista preparada permanece disponível. O prazo
para aparecerem novas sugestões depende do processamento, além do intervalo de consulta.
Avaliações antigas, anteriores a este recurso, passam a ser consideradas quando uma
nova avaliação ou opinião da pessoa dispara o processamento.

## Executar e verificar

Reinicie API e worker após atualizar o código. O worker é iniciado com
`npm run worker:dev`, usando a configuração Pub/Sub existente (`PUBSUB_ATIVO=true`
e credenciais ADC). Assinaturas com filtros devem aceitar `interacao.registrada`,
`estabelecimento.atualizado` e `preferencias.atualizadas`.
Não é necessária nova migration para este recurso.

`npm test` verifica contratos e pontuação. `npm run test:integration` inclui o fluxo
com banco descartável via `DATABASE_URL_TESTE`, com notas altas e baixas, reentregas,
eventos fora de ordem e notas em classificações. Os testes Flutter verificam a
atualização periódica, troca dos cartões, encerramento da consulta ao sair e falhas.
