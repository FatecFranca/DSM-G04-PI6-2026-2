# BoraLá Mobile

Projeto Flutter para Android/iOS. A entrada é `lib/main.dart`, com personalizações
em `lib/app.dart`. As funcionalidades comuns vêm do pacote `../shared`.

```powershell
flutter pub get
flutter devices
flutter run -d <id-do-dispositivo>
flutter build apk --release --dart-define=API_URL=https://sua-api.example.com
```

No emulador Android, a API padrão é `http://10.0.2.2:8080`. Em dispositivos físicos,
informe `--dart-define=API_URL=http://<ip-da-maquina>:8080` no desenvolvimento.
iOS exige macOS/Xcode. A assinatura release Android deve ser configurada antes de
distribuir o aplicativo. Veja [a documentação dos frontends](../README.md).
