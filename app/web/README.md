# BoraLá Web

Projeto Flutter para navegador. A entrada é `lib/main.dart`, com personalizações
em `lib/app.dart`. As funcionalidades comuns vêm do pacote `../shared`.

```powershell
flutter pub get
flutter run -d chrome --web-port=5173 --dart-define=API_URL=http://localhost:8080
flutter build web --dart-define=API_URL=https://sua-api.example.com
```

Para avaliar a fluidez no navegador, encerre a execução atual e rode em Release:

```powershell
flutter run -d chrome --release --web-port=5173 --dart-define=API_URL=http://localhost:8080
```

O modo debug prioriza depuração e não representa o desempenho final. No VS Code,
selecione `BoraLa Web (Release)`. Nesse modo, alterações exigem uma nova execução.
Para medir quadros no painel Performance do Chrome DevTools, use `--profile`
no lugar de `--release`.

O build fica em `build/web`. Configure `CORS_ORIGIN` na API para a origem do
navegador. Veja [a documentação dos frontends](../README.md).
