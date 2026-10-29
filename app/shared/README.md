# BoraLá: pacote compartilhado

O pacote Dart `meu_app` reúne as funcionalidades comuns das versões
[Web](../web/README.md) e [Mobile](../mobile/README.md).

- `lib/borala.dart`: interface pública para inicializar a sessão e montar o app.
- `lib/pages`: login, cadastro, catálogo, detalhes, avaliações, histórico e perfil.
- `lib/services`: integração com a API, sessão persistente e recomendações.
- `lib/components`: componentes comuns, notificações e sugestões automáticas.
- `lib/router`: rotas e proteção por autenticação.
- `lib/theme`: tema e cores.
- `test`: testes de contratos, sessão e interface com respostas simuladas.

```powershell
flutter pub get
flutter test
flutter analyze
```

Para executar ou gerar um build, use `../web` ou `../mobile`. Ambos dependem deste
pacote por `path: ../shared`; não é necessário publicá-lo.

A URL da API é definida por `--dart-define=API_URL=...` no projeto executável.
O padrão é `http://10.0.2.2:8080` no Android e `http://localhost:8080` no navegador
e demais plataformas. Credenciais de banco, JWT e Google Cloud ficam no backend.

As versões preservam o catálogo, as avaliações e a média pública, as notificações
de favoritos e as sugestões preparadas pela mensageria. A sessão usa
`flutter_secure_storage`, e as chamadas HTTP usam os contratos da API existente.
