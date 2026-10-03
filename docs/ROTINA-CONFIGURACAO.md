# Configurar conta, Steve e histórico reais

Painel e caderno usam respostas confirmadas no PostgreSQL, separadas por conta e área. Os testes controlados não comprovam acesso ao Firebase/OpenAI. Nesta entrega, esses serviços permanecem **pendentes de configuração e validação real**.

## Banco local no Windows

O utilitário usa PostgreSQL18 já instalado em `C:\Program Files\PostgreSQL\18\bin`, sem instalar serviço do Windows. Na raiz do EstudaAi:

```powershell
npm run pg:local -- -Action Init
npm run pg:local -- -Action Start
```

O cluster fica em `.tooling/pg-local`, escuta somente em127.0.0.1:55433 e usa SCRAM. A senha e o `database.env` têm acesso restrito ao usuário Windows atual. Init repetido preserva dados/senha; `.env` da raiz nunca é modificado pelo utilitário.

Copie a configuração privada somente se ainda não houver `.env`:

```powershell
if (-not (Test-Path -LiteralPath '.env')) {
  Copy-Item -LiteralPath '.tooling/pg-local/database.env' -Destination '.env'
  Set-Acl -LiteralPath '.env' -AclObject (Get-Acl -LiteralPath '.tooling/pg-local/database.env')
}
node --env-file=.env node_modules/prisma/build/index.js migrate deploy --schema apps/api/prisma/schema.prisma
```

Se `.env` já existir, preencha DATABASE_URL com o valor do arquivo privado. Init não aplica migrações. As três migrações preservam metas anteriores e acrescentam histórico/caderno. Faça backup antes de migrar um banco com dados relevantes.

```powershell
npm run pg:local -- -Action Status
npm run pg:local -- -Action Stop
npm run pg:local -- -Action Start
```

Stop preserva dados. Porta ocupada, pasta fora da `.tooling` deste checkout, caminho com junction/link ou marcador incompatível fazem o comando recusar a operação. `-Port` deve repetir o valor do Init; `-DataRoot` permite outro cluster sob `.tooling`. Não altere a senha de um cluster já inicializado nem apague dados para resolver uma recusa.

`npm run test:local-postgres` cria seu próprio cluster UUID na porta55434, grava sentinela, reinicia, verifica preservação/recusas e encerra. O teste de `.env` preexistente usa uma cópia mínima isolada. `test:pg:local` usa outro banco temporário, na porta55432, para migrações/concorrência.

## Firebase: login por e-mail/senha

1. Crie o projeto no [Firebase Console](https://console.firebase.google.com/).
2. Em Authentication → Sign-in method, habilite Email/password e configure a política de senha.
3. Em Project settings, obtenha Project ID e chave Web do mesmo projeto. Preencha `FIREBASE_PROJECT_ID` e `FIREBASE_WEB_API_KEY` no `.env` do backend.
4. Em Project settings → Service accounts, gere a credencial administrativa. Salve o JSON em pasta privada fora do Git e da sincronização do OneDrive. Preencha `GOOGLE_APPLICATION_CREDENTIALS` com caminho absoluto; no Compose, `FIREBASE_ADMIN_CREDENTIALS_FILE` aponta para o mesmo arquivo no host.

O backend usa a [API REST](https://firebase.google.com/docs/reference/rest/auth) para cadastro/login/renovação e Firebase Admin para verificar identidade/revogação. Chaves Web restritas precisam permitir Identity Toolkit API e Token Service API. Este fluxo de senha não usa redirecionamento nem exige um SDK Firebase no Flutter. Consulte [autenticação por senha](https://firebase.google.com/docs/auth/web/password-auth), [chaves Firebase](https://firebase.google.com/docs/projects/api-keys) e [Admin](https://firebase.google.com/docs/admin/setup).

Nunca cole senhas, tokens ou JSON administrativo na conversa, cliente, Git ou relatório. Nesta implementação, a chave Web também permanece no servidor.

## OpenAI: Steve

Prepare acesso à API na [plataforma OpenAI](https://platform.openai.com/) e gere uma chave para o projeto. Preencha **juntos** `OPENAI_API_KEY` e `STEVE_MODEL` no backend. `gpt-4.1-mini` é um exemplo compatível com o contrato atual de texto/Responses; confira o acesso efetivo na sua conta. Referências: [guia inicial](https://developers.openai.com/api/docs/quickstart), [API](https://developers.openai.com/api/reference/overview) e [modelo](https://developers.openai.com/api/docs/models/gpt-4.1-mini).

Steve usa Responses com `store:false`, assunto e fontes do catálogo. Padrões:10 pedidos por aluno/dia UTC,1000 globais/dia, três por minuto e uma chamada simultânea por aluno. Ajuste `STEVE_DAILY_LIMIT` e `STEVE_GLOBAL_DAILY_LIMIT`. A validação ao vivo envia três perguntas e consome chamadas reais; não roda na CI comum.

## Diagnóstico e execução

O exemplo de `CORS_ORIGINS` cobre localhost/127.0.0.1 nas portas4173/4174. Para produção, use HTTPS e a origem efetiva do aplicativo.

```powershell
npm run check:config
npm run build
npm run dev:api
```

O diagnóstico não revela valores privados nem chama a IA. Verifica conexão e colunas do schema, credencial Admin/projeto e a origem de `PREVIEW_URL` (padrão `http://127.0.0.1:4174`). Firebase/Steve `configured` significa configuração plausível, sem comprovar acesso externo. Código2 indica pendências. `/health/ready` sozinho não comprova login, schema ou IA.

Abra Conta e confira cadastro/login, senha inválida, sessão e saída. Em Meu estudo, revise uma questão de cada área. Recarregar a página exige novo login, pois a sessão fica em memória.

## Roteiro ao vivo separado

Crie o arquivo ignorado `.env.live` com `LIVE_TEST_EMAIL`, `LIVE_TEST_PASSWORD` e, se necessário, `LIVE_API_ORIGIN`. Use conta dedicada aos testes. Para cadastrar um e-mail novo, acrescente `LIVE_REGISTER=1`; o padrão é entrar em conta existente.

```powershell
npm run verify:live
```

Só começa com banco/schema/CORS verificados e ambos os provedores configurados. Confere cadastro opcional, login, perfil, renovação, senha incorreta, três respostas de Steve em Estudo livre/BB2026, fontes/cota, respostas idempotentes e retomada do histórico na mesma conta. Saída descarta tokens na memória e confere recusa sem token; não promete revogação da sessão Firebase.

`artifacts/rotina-estudo/live-report.json` contém somente estado/nomes dos passos. Não registra e-mail, senha, token, conversa, HAR ou trace. Códigos:0 passou,1 falhou,2 pendente. Sem configuração, encerra antes de criar conta ou chamar provedores.

Recuperação de senha não é automática. Para solicitar explicitamente o e-mail à conta de teste definida no seu `.env.live`:

```powershell
npm run verify:live -- --password-reset
```

Confira chegada e uso do link manualmente. Um pedido aceito não comprova entrega do e-mail.
