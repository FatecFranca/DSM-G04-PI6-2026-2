# Frontends BoraLá

O frontend está dividido em projetos Flutter com entradas e builds independentes:

```text
app/
  web/       # Frontend para navegador
  mobile/    # Frontend Android/iOS
  shared/    # Pacote meu_app: telas, API, sessão, componentes e regras comuns
  desktop/   # Configurações desktop anteriores, preservadas separadamente
```

Cada aplicativo tem seu próprio pubspec.yaml e diretório de build. Web e Mobile
usam o pacote local `../shared`. Personalizações específicas ficam em
`web/lib/app.dart` e `mobile/lib/app.dart`; as funcionalidades comuns ficam em
`shared/lib`. As configurações nativas e os identificadores dos aplicativos foram
preservados.

## Preparar

Na raiz do repositório:

```powershell
cd app/shared
flutter pub get
cd ../web
flutter pub get
cd ../mobile
flutter pub get
```

## Executar Web

Na pasta `app/web`:

```powershell
flutter run -d chrome --web-port=5173 --dart-define=API_URL=http://localhost:8080
```

No backend, permita `http://localhost:5173` em `CORS_ORIGIN`.

## Executar Mobile

Na pasta `app/mobile`:

```powershell
flutter devices
flutter run -d <id-do-dispositivo>
```

O emulador Android usa `http://10.0.2.2:8080` por padrão. Em um celular físico,
informe a URL da máquina que executa a API na mesma rede:

```powershell
flutter run -d <id-do-dispositivo> --dart-define=API_URL=http://192.168.1.10:8080
```

iOS exige macOS/Xcode. Para preparar o backend, consulte `../api/README.md` a
partir de `app`. Credenciais de banco e de mensageria ficam somente no backend.

## Builds

Execute cada comando na pasta do respectivo projeto:

```powershell
# app/web: saída em build/web
flutter build web --dart-define=API_URL=https://sua-api.example.com

# app/mobile: saída em build/app/outputs/flutter-apk
flutter build apk --release --dart-define=API_URL=https://sua-api.example.com
```

## Testes

Os testes das funcionalidades comuns estão em `app/shared/test`:

```powershell
cd app/shared
flutter test
flutter analyze
cd ../web
flutter analyze
cd ../mobile
flutter analyze
```

O VS Code tem configurações para Web e Mobile em `.vscode/launch.json` na raiz
do repositório e em `app/.vscode/launch.json` para quem abre apenas a pasta `app`.

A antiga pasta `myApp` não é mais um projeto executável. Encerre execuções antigas
iniciadas nela e execute novamente pela pasta `web` ou `mobile`. Artefatos locais
antigos foram preservados e são ignorados pelo Git.
