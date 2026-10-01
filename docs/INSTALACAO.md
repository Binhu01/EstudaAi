# Instalação e execução local

Execute os comandos na raiz do **EstudaAi**, separada da AlmaPet. A fundação possui cliente Flutter e API NestJS; o fluxo executável do cliente é Home/Preferências. Login completo e operações de metas chegam na Fase 2. O cliente atual pode abrir sem API ou credenciais Firebase.

## Ferramentas e versões

| Ferramenta | Versão da fundação | Uso |
| --- | --- | --- |
| Node.js | 24.x (`.nvmrc`) | API e ferramentas do repositório |
| npm | Compatível com Node 24 | Workspaces; instalar na raiz pelo lockfile |
| Flutter | 3.47.5, canal stable | Cliente |
| Dart | 3.13.4, incluído no Flutter | Cliente e geração de modelos |
| Prisma | 6.19.3 | Cliente com `engineType = "client"` e adapter `@prisma/adapter-pg` |
| Firebase Admin | 14.5.0 | Identidade verificada no backend |
| PostgreSQL | 17, imagem do Compose | Banco persistente para execução real |
| Docker + Compose v2 | Necessários para a opção de containers | Ausentes no ambiente desta sessão |

O SDK local usado nesta sessão está em `.tooling/flutter`, ignorado pelo Git. Em uma nova máquina, obtenha a mesma versão pelo [arquivo oficial do Flutter](https://docs.flutter.dev/install/archive). Não é necessário instalar Dart separadamente.

Os comandos Flutter abaixo pressupõem `flutter` e o `dart` do mesmo SDK no PATH **da sessão**. No PowerShell, com o SDK local já presente:

```powershell
$env:PATH = "$((Resolve-Path '.tooling/flutter/bin').Path);$env:PATH"
flutter --version
```

No Windows desta sessão, a criação de symlinks de plugins não está autorizada. Para testes e Web, a alternativa usada foi a variável de processo `$env:FLUTTER_WINDOWS = 'false'`, antes de `flutter pub get`. Isso não altera o sistema e não verifica o aplicativo nativo Windows. Para desenvolvimento nativo, prepare uma máquina com privilégio de symlink/Developer Mode e Visual Studio com ferramentas C++; consulte o [guia Windows do Flutter](https://docs.flutter.dev/platform-integration/windows/setup).

## Instalar e verificar a API

Na raiz:

```powershell
npm ci --ignore-scripts
npm run db:generate
npm test
npm run build
npm run openapi
```

`npm ci --ignore-scripts` usa o `package-lock.json` da raiz e resolve o workspace `apps/api`, sem executar scripts de instalação de dependências, incluindo a telemetria Scarf. A geração Prisma é explícita e cria o cliente necessário ao build. `npm run openapi` atualiza o contrato a partir dos metadados Nest sem iniciar um servidor ou simular uma sessão autenticada. Os testes HTTP inicializam uma aplicação Nest real com dependências controladas; os testes SQL usam PGlite. Eles não configuram Firebase real nem demonstram integração do adapter Prisma com PostgreSQL completo.

## Instalar e abrir o cliente

```powershell
Set-Location apps/client
flutter pub get --enforce-lockfile
dart run build_runner build
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web --release --no-web-resources-cdn
flutter run -d chrome --web-port 4173
```

O último comando abre o cliente em desenvolvimento, com galeria em `/componentes`. A galeria é excluída das rotas no build de produção. Home fica em `/` e Preferências em `/preferencias`. Tokens administrativos, senhas de banco e chaves de IA não pertencem a `--dart-define` nem aos arquivos do cliente. Esta fundação ainda não usa uma variável pública de ambiente para conectar o bootstrap do cliente à API.

## Prévia do build Web e checagem visual

Após gerar o build Web acima, abra um terminal **na raiz** e inicie a prévia local:

```powershell
npm run preview
```

Abra `http://127.0.0.1:4173`. O servidor usa loopback, oferece fallback para as rotas da aplicação e serve `apps/client/build/web`. `--no-web-resources-cdn` inclui os recursos do renderizador no build, conforme a execução desta sessão. A prévia é uma ferramenta local e deve continuar aberta enquanto a checagem visual roda.

Em outro terminal na raiz, prepare o navegador de teste em uma pasta local ignorada pelo Git e execute o script mantido no projeto:

```powershell
$env:PLAYWRIGHT_BROWSERS_PATH = (Join-Path (Get-Location) '.tooling/playwright')
npx playwright install chromium
npm run test:visual
```

Use o mesmo `PLAYWRIGHT_BROWSERS_PATH` nos comandos de instalação e teste. O script verifica navegação, tema persistido, shader animado/pausado, movimento reduzido, teclado e console em viewports de 360, 768 e 1440 px. Capturas ficam em `artifacts/screenshots` e o relatório em `artifacts/web-verification.json`. `PREVIEW_PORT` altera a porta do servidor; ao usá-la, defina também `PREVIEW_URL` para o teste. Veja [Validação](VALIDACAO.md) para o resultado efetivamente obtido, separado destas instruções.

## Configurar a API real

Copie o exemplo sem sobrescrever um `.env` já configurado:

```powershell
if (-not (Test-Path -LiteralPath '.env')) {
  Copy-Item -LiteralPath '.env.example' -Destination '.env'
}
```

Preencha `DATABASE_URL`, `FIREBASE_PROJECT_ID`, `CORS_ORIGINS` e a credencial administrativa. A API usa Application Default Credentials; para execução no host, `GOOGLE_APPLICATION_CREDENTIALS` deve apontar para um arquivo existente **fora do repositório**, com acesso restrito ao operador. Em ambientes gerenciados, prefira identidade de workload. Veja a [configuração oficial do Firebase Admin](https://firebase.google.com/docs/admin/setup).

| Configuração | Aplicação |
| --- | --- |
| `DATABASE_URL` | URL PostgreSQL usada pela API/CLI Prisma no host; codifique caracteres especiais da senha |
| `FIREBASE_PROJECT_ID` | ID do projeto que emite os ID tokens aceitos pelo Admin |
| `GOOGLE_APPLICATION_CREDENTIALS` | Caminho externo da credencial para o processo Node no host |
| `FIREBASE_ADMIN_CREDENTIALS_FILE` | Caminho externo do mesmo arquivo para o secret do Compose |
| `CORS_ORIGINS` | Origens exatas, separadas por vírgula; HTTPS obrigatório com `NODE_ENV=production` |
| `PORT` | Porta do processo Node no host; padrão 3001 |
| `POSTGRES_*` e `API_PORT` | Banco e portas locais do Compose |

O Compose monta a credencial em `/run/secrets/firebase_admin` e define o caminho dentro do container. Garanta que o usuário `node` (UID 1000) consiga ler o arquivo montado sem ampliar acesso desnecessariamente; esse acesso também precisa de teste no host de containers. Ele compõe sua própria URL usando o hostname `postgres`; a URL do host usa `127.0.0.1`. Não são intercambiáveis. Os valores obrigatórios são avaliados no arquivo Compose inteiro: prepare também o caminho da credencial antes de usar seus comandos, mesmo ao iniciar apenas o banco.

## Banco e API com Compose

Esta configuração foi preparada e revisada estaticamente; **não foi executada nesta máquina porque Docker não está disponível**. Após preencher `.env` e preparar a credencial, execute na raiz:

```powershell
docker compose --env-file .env -f infra/compose.yaml config --quiet
docker compose --env-file .env -f infra/compose.yaml --profile tools build api migrate
docker compose --env-file .env -f infra/compose.yaml up -d --wait postgres
docker compose --env-file .env -f infra/compose.yaml --profile tools run --rm migrate
docker compose --env-file .env -f infra/compose.yaml up -d --wait api
```

Só prossiga para a API se o job de migração terminar com código 0. Ele executa `prisma migrate deploy`; a API não aplica migrações automaticamente. O volume `postgres_data` preserva dados entre reinícios. Mudar a senha de inicialização no `.env` não altera a senha de um banco já inicializado.

Para rodar a API diretamente no host, use um PostgreSQL configurado, aplique as migrações carregando o `.env` e depois inicie o processo:

```powershell
node --env-file=.env --run db:deploy
npm run build
npm run dev:api
```

O comando Node 24 carrega o `.env` e executa o script `db:deploy` da raiz, que encaminha à CLI Prisma no workspace. Se `DATABASE_URL` já estiver no ambiente do processo, `npm run db:deploy` também é suficiente. O script `dev:api` carrega o `.env` da raiz e executa a saída compilada; não é um watcher. Se editar TypeScript, refaça o build.

## Conferir saúde e contrato

```powershell
Invoke-RestMethod http://127.0.0.1:3001/health/live
Invoke-RestMethod http://127.0.0.1:3001/health/ready
```

`live` responde sobre o processo. `ready` verifica uma consulta ao banco; não comprova credenciais Firebase válidas, schema migrado ou login de ponta a ponta. `/v1/me` e `/v1/me/entitlements` exigem `Authorization: Bearer <ID token Firebase>`. Sem sessão válida, o acesso é recusado; a resposta autorizada usa identidade interna e plano FREE. Não grave tokens em comandos compartilhados, logs ou exemplos versionados.

O contrato está em [OpenAPI](../contracts/openapi.json). Não há uma rota Swagger pública registrada no bootstrap atual. Resultados locais e pendências por plataforma ficam em [Validação](VALIDACAO.md); preparação de ambiente não substitui essa evidência.
