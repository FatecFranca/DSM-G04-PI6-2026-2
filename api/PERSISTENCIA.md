# Quando cada tabela recebe dados

Uma ação grava nas tabelas relacionadas a ela. Tabelas de erro ou de notificações
podem ficar vazias até ocorrer uma situação que gere esses registros.

| Tabela | O que gera registros |
| --- | --- |
| `tb_usuario` | Cadastro de uma conta. |
| `tb_estabelecimento` | Cadastro/importação de restaurantes; avaliações atualizam a média e a contagem. |
| `tb_interacao_usuario_estabelecimento` | Visualizações, notas, curtidas, rejeições, favoritos e visitas. |
| `tb_classificacao` | Cada avaliação enviada pelo aplicativo cria uma classificação para o autor. |
| `tb_classificacao_estabelecimento` | Nota da avaliação, vinculada à classificação, ao estabelecimento e à interação original. |
| `tb_evento_outbox` | Eventos das ações com mensageria ativada e eventos de alteração de restaurantes. |
| `tb_evento_processado` | Eventos efetivamente processados pelo consumidor. |
| `tb_mensagem_quarentena` | Apenas mensagens inválidas ou com falha permanente. Vazia significa ausência desses casos registrados. |
| `tb_modelo_recomendacao` | Metadados do algoritmo por regras utilizado, registrado ao gerar sugestões/cache. Não representa treinamento de ML. |
| `tb_usuario_feature_snapshot` | Preferências informadas e sugestões automáticas preparadas pelo consumidor. |
| `tb_recomendacao_cache` | Consultas de recomendações e sugestões preparadas pelo consumidor. Pode ser invalidada e esvaziada após novas notas. |
| `tb_notificacao` | Alterações reais de restaurantes pela API, após o consumo do evento, para usuários que já os favoritaram. |

## Avaliações

`POST /interacoes` com `tipo_evento: rating` salva a interação, a classificação,
a nota vinculada e a média do estabelecimento na mesma transação. Com a mensageria
ativa, o evento da outbox também faz parte da transação. Falhas desfazem o conjunto.
O campo único `tb_classificacao_estabelecimento.id_interacao` identifica o vínculo
e evita confundir a cópia da avaliação com uma avaliação independente.

A listagem pública mostra a avaliação somente uma vez. A média continua considerando
apenas a nota mais recente de cada pessoa por estabelecimento.

A migration `20261023150000_integrar_gravacao_avaliacoes` recupera as notas já existentes
nas interações, preservando autor, local, valor e data. Também preenche o cache com
sugestões reais já preparadas, conservando a validade original do resultado.

## Conferir no DBeaver

Atualize a aba de dados após novas ações. Para verificar todas as contagens, execute
[diagnostico_tabelas.sql](diagnostico_tabelas.sql).
O worker precisa estar executando para preencher as tabelas de processamento,
notificações e sugestões. Uma outbox sem pendências indica que seus eventos já
foram publicados; a conclusão do consumo é registrada em `tb_evento_processado`.
