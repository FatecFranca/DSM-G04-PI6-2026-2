# Floter mobile

Aplicativo Flutter do projeto DSM-G04-PI6-2026-2. A estrutura existente foi mantida:
Dart, Material 3, GoRouter, http e tema escuro com destaque rosa. Não foi criado
outro app React Native nem duplicado o backend.

## Funcionalidades

- Login e cadastro integrados à API Express existente.
- Sessão persistida com flutter_secure_storage 10.0.0, expiração local, logout e
  proteção de rotas. A API continua responsável por validar a assinatura do JWT.
- Descoberta com recomendações reais, catálogo de locais ativos, busca por nome,
  tipo ou região, recarregamento e estados de erro/vazio.
- Detalhes do estabelecimento, horário informado, localização, tags e avaliação pública.
- Registro de view, like, dislike, favorite, visitado e rating usando POST /interacoes.
  Favoritar registra o evento; não existe endpoint de desfavoritar nem lista de favoritos.
- Questionário de preferências com restauração dos dados salvos e resultados reais
  de GET /recomendacoes. Foram removidos os resultados simulados e o botão de pedido fictício.
- Avaliação de 1 a 5, histórico e edição do perfil. Nenhum checkout ou pedido foi inventado.
- Tratamento de timeout, rede indisponível, JSON inválido e sessão expirada, sem
  repetir automaticamente chamadas de escrita.

## Estrutura

- lib/pages: login, cadastro, descoberta, detalhes, questionário, resultados, avaliação,
  histórico e perfil.
- lib/services/api.dart: cliente HTTP compartilhado, contratos e tratamento de respostas.
- lib/services/sessao.dart: armazenamento seguro, expiração e notificações de autenticação.
- lib/services/floter_service.dart: resultados do ranking real da API.
- lib/router/app_router.dart: navegação e redirecionamento de rotas privadas.
- lib/components: navegação inferior, estados reutilizáveis e opções do questionário.
- test: contratos HTTP, sessão e fluxos de interface com clientes e armazenamento falsos.

## Preparação e execução

Requer Flutter compatível com Dart 3.11 ou superior. O ambiente de validação utilizou
Flutter 3.47.2 / Dart 3.13.2. Para Android, instale o SDK pelo Android Studio,
configure um dispositivo/emulador e execute flutter doctor. minSdk: Android 23.
No Windows, ative o Modo de Desenvolvedor caso o Flutter solicite suporte a symlinks.
Não é necessário React Native, Expo ou npm para executar o app Flutter.

    cd C:\p.i\DSM-G04-PI6-2026-2\app\myApp
    flutter pub get
    flutter devices
    flutter run -d <id-do-dispositivo>

O backend precisa estar em execução e com um banco contendo estabelecimentos.
Para prepará-lo, consulte ../../api/README.md. Não coloque senha de banco,
JWT_SECRET ou credenciais Google Cloud no app.

### URL da API

Por padrão: emulador Android usa http://10.0.2.2:8080; web e demais plataformas
usam http://localhost:8080. Em um celular físico, localhost é o próprio celular.
Use o IP da máquina do backend, na mesma rede, configurando API_URL:

    flutter run --dart-define=API_URL=http://192.168.1.10:8080

Para executar no navegador:

    flutter run -d chrome --dart-define=API_URL=http://localhost:8080

Configure CORS_ORIGIN no backend para a origem web usada no teste. Para uma porta fixa:

    flutter run -d chrome --web-port=5173 --dart-define=API_URL=http://localhost:8080

No backend, permita http://localhost:5173. Android nativo não usa CORS.
O Android permite HTTP somente no manifesto debug. Em release use uma API HTTPS:

    flutter build apk --release --dart-define=API_URL=https://sua-api.example.com

A assinatura release do template ainda utiliza a chave de desenvolvimento; configure
uma chave de publicação antes de distribuir em loja. Não foi gerada uma chave nova.
iOS exige macOS/Xcode, equipe de assinatura e provisioning próprios. O nome de exibição
e os entitlements do Keychain foram preparados; a compilação iOS não foi feita no Windows.
No iPhone físico prefira uma API HTTPS. O aplicativo solicita acesso à rede local quando necessário.

## Sessão e segurança

O JWT é persistido pelo armazenamento seguro de plataforma. A leitura local de exp e
id_usuario não substitui a validação do servidor. Ao receber 401, o cliente limpa a sessão
e o roteador leva ao login; 403 preserva a sessão. Respostas antigas não encerram uma
sessão nova. Headers de renovação são aproveitados se forem fornecidos; o backend atual
não tem endpoint de refresh, então após expirar é preciso fazer login novamente.
Não são guardadas senhas nem registrados tokens nos logs. Se o armazenamento seguro
estiver indisponível, o login funciona apenas em memória, sem persistência entre aberturas.
Na web, o plugin exige HTTPS ou localhost.

## Mensageria

O mobile chama apenas a API. POST /interacoes pode disparar a outbox/Pub/Sub configurada
no backend; nenhuma biblioteca, assinatura ou credencial do Google Cloud vai para o celular.
O worker é iniciado separadamente no backend. O app recarrega recomendações após sair
dos detalhes e solicita atualização no ranking. A invalidação na nuvem continua eventual.

## Limites do contrato atual

O ranking atual utiliza preferências de categoria/preço e interações de like/dislike.
Outras respostas do questionário são persistidas, mas não há garantia de filtragem por
restrição alimentar, sabor, tamanho de porção ou modalidade. Confirme opções alimentares
diretamente com o estabelecimento. Não há endpoint de pedidos, checkout, upload de foto
ou gerenciamento de favoritos completos; esses recursos não foram simulados.
Na tela Avaliar, a nota pode originar também um like/dislike, conforme o comportamento
existente. Se somente o feedback auxiliar falhar, a nota já salva não é reenviada.

## Testes e validação

    flutter analyze
    flutter test
    flutter build web --dart-define=API_URL=http://localhost:8080

Os testes usam MockClient e armazenamento em memória: não chamam API, banco ou Pub/Sub
reais e não precisam de conta de usuário. Cobrem autenticação, persistência, expiração,
contratos, indisponibilidade, timeout, navegação protegida, telas pequenas, busca,
questionário, histórico e envio de interações.

Roteiro manual com backend de desenvolvimento:
1. Inicie API, banco e, para observar mensageria, o worker.
2. Cadastre uma conta no app, preencha preferências e abra os resultados.
3. Explore os locais, faça buscas e abra os detalhes.
4. Registre like/dislike, favorito ou visita; avalie de 1 a 5.
5. Confira o histórico e edite nome/e-mail/senha no perfil.
6. Feche e abra o app dentro da validade do JWT para testar restauração.
7. Saia da conta e confirme que as rotas privadas exigem novo login.
8. Interrompa a API e verifique mensagens de falha e tentativa novamente.

Referências: https://docs.flutter.dev/cookbook/networking/fetch-data e
https://github.com/juliansteenbakker/flutter_secure_storage.

## Resultado da validação nesta implementação

- flutter analyze --no-pub: nenhum problema encontrado.
- flutter test --no-pub: 31 testes aprovados.
- flutter build web --no-pub: compilação aprovada.
- Android SDK ausente nesta máquina: APK e execução Android não validados.
- iOS preparado, mas exige validação em macOS/Xcode.
- Plugins instalados; preparação nativa no Windows exige Modo de Desenvolvedor para symlinks.
- Contratos testados com clientes falsos; login e cadastro no backend real devem ser conferidos pelo roteiro manual.


## Home de restaurantes

A primeira tela apos o login agora e uma home de exploracao. Abre o catalogo completo
de estabelecimentos ativos por padrao, mantendo Para voce como opcao de recomendacoes.
Inclui categorias derivadas da API, busca sem diferenciar acentos, ordenacao por nome
ou avaliacao, notas reais, regiao e horario informado. Os cards abrem os detalhes existentes.
O grid adapta-se para uma, duas ou tres colunas e permite rolagem e atualizacao por gesto.
As ilustracoes dos cards sao icones de categoria, nao fotos dos estabelecimentos.
Os dados vem de GET /estabelecimentos; nenhum restaurante ou nota foi inventado no app.
Se o banco estiver vazio, a home informa isso. O cadastro de locais continua no backend.
Rotas: /home (atalho) e /sugestoes (endereco preservado).

Validação da home: 39 testes Flutter aprovados (incluindo 8 específicos do catálogo)
e análise estática sem problemas. Foram conferidos 299 estabelecimentos ativos
no banco por consulta somente de leitura; a home não cadastra dados fictícios.
