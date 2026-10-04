# Operação e preparação de deploy

**Nenhum deploy público foi feito.** Firebase e histórico foram validados com serviços reais no ambiente local; a OpenAI foi adiada pelo usuário. O banco PostgreSQL18 local preserva os dados de estudo. Imagens, HTTPS, migrações e credenciais precisam ser conferidos no destino antes de liberar tráfego. Este guia descreve esse procedimento e distingue preparo de publicação efetiva.

## Imagem e migração

O Dockerfile usa Node 24 em Linux, instala dependências pelo lockfile da raiz com `npm ci --ignore-scripts`, gera Prisma explicitamente e compila o workspace. A instalação não executa scripts de dependências nem telemetria Scarf. O target `runtime` mantém somente dependências de produção e a saída da API; roda como usuário `node`. O target `migration` conserva a CLI Prisma para o job explícito. O `.dockerignore` limita o contexto aos arquivos necessários da API e exclui ambiente/SDK/cliente.

Execute o roteiro local de [Instalação](INSTALACAO.md) em um host com Docker antes de usar a imagem em outro ambiente. No destino, prepare banco isolado, credenciais externas à imagem, origens HTTPS e `NODE_ENV=production`. Em serviços gerenciados, forneça `DATABASE_URL` apontando para o banco real e use identidade de workload compatível com Firebase Admin; não leve a URL do serviço `postgres` do Compose.

Para cada versão, a sequência de operação é:

1. Gerar imagem identificada por versão/commit e executar os testes disponíveis.
2. Fazer backup do banco de destino e verificar uma restauração antes de alterações relevantes.
3. Executar um único job `npm run db:deploy`, usando o target `migration`, a imagem da mesma versão e a URL do banco de destino.
4. Conferir código de saída 0 e histórico de migrações; interromper a atualização em caso de falha.
5. Iniciar a API com o target `runtime`; conferir saúde e contrato autenticado usando identidades de teste do ambiente.
6. Liberar tráfego somente após verificar autorização, Firebase real e comportamento de falha.

Não use `prisma db push` para substituir migrações versionadas no destino. `migrate deploy` aplica as migrações pendentes e precisa ser executado explicitamente. Veja a [documentação Prisma de deploy](https://www.prisma.io/docs/orm/prisma-migrate/workflows/development-and-production#production-and-testing-environments).

O Compose é um ponto de partida local de instância única: portas ficam em loopback, o banco tem volume persistente e a API aguarda o healthcheck do PostgreSQL. O secret Firebase é montado somente na API como arquivo; ele não é incorporado no build. Esses comportamentos seguem os guias de [ordem de inicialização](https://docs.docker.com/compose/how-tos/startup-order/) e [secrets](https://docs.docker.com/compose/how-tos/use-secrets/). Compose local não é cofre de segredos nem estratégia de alta disponibilidade.

## Pendências antes de expor a API

- Configurar domínio e terminação HTTPS; CORS exige origens exatas, sem wildcard.
- Configurar `TRUSTED_PROXY_CIDRS` somente com os IPs/CIDRs dos proxies que conectam diretamente à API. O padrão vazio ignora headers encaminhados; wildcards, nomes e quantidade de saltos são recusados. Os testes HTTP comprovam separação por IP com peer confiável e recusa de header forjado em peer não confiável. Nunca confiar em toda a rede por conveniência.
- Manter uma instância enquanto o rate limiter usar memória. Armazenamento compartilhado e testes de múltiplas réplicas são pré-requisitos para escala horizontal.
- Ensaiar o job de migração e a versão PostgreSQL do destino; o teste local usa18 e a CI preparada usa17. Configurar e validar credenciais Firebase e provedor/modelo Steve.
- Verificar token inválido, expirado, revogado e de outro projeto com o serviço Firebase real, sem registrar tokens.
- Definir backups, retenção, restauração, rotação de credenciais e monitoramento de indisponibilidade.

`/health/live` e `/health/ready` são públicos. Readiness executa `SELECT 1`, portanto não verifica Firebase ou presença das tabelas. O monitoramento deve incluir também um teste privado controlado após migrações. Logs da API contêm request ID, rota, método, status e duração; não acrescente credenciais ou payloads pessoais ao coletor.

## HTTPS com o stack atual

O arquivo [infra/Caddyfile](../infra/Caddyfile) serve o build Web e encaminha `/v1/*` e `/health/*` à API em `127.0.0.1:3001`, no mesmo domínio. Configure `ESTUDA_AI_DOMAIN` com o host, sem protocolo, e `ESTUDA_AI_WEB_ROOT` com o caminho absoluto do build. Compile Flutter com `API_ORIGIN=https://seu-dominio.example` e use essa mesma origem em `CORS_ORIGINS` e `PREVIEW_URL` do diagnóstico de produção.

DNS A/AAAA deve apontar para o servidor; portas 80/443 precisam ser acessíveis e o armazenamento de certificados do Caddy deve permanecer persistente. Valide com `caddy validate --config infra/Caddyfile --adapter caddyfile` antes de iniciar o serviço. O job da CI valida o arquivo com domínio de exemplo; isso não emite nem comprova certificado público. Veja [HTTPS automático](https://caddyserver.com/docs/automatic-https) e [reverse proxy](https://caddyserver.com/docs/caddyfile/directives/reverse_proxy).

Se Caddy e Node estiverem no mesmo host, os peers de loopback podem ser configurados como `127.0.0.1/32,::1/128`. Se a API estiver em container, descubra o endereço real que chega pelo mapeamento de portas e configure somente esse peer; não suponha que seja loopback e não use contagem de saltos. Mantenha a API/banco em loopback, sem expor as portas diretamente à internet. A validação do proxy deve ocorrer no destino antes de alunos reais.

Backup e ensaio de restauração: siga [BACKUP.md](BACKUP.md). Guarde cópia diária privada, antes de migrações e fora do host de produção, com retenção definida pelo operador. O utilitário não envia dados para um serviço remoto nem remove cópias antigas. Agendamento e destino externo dependem da hospedagem escolhida. Confira o ensaio e a integridade antes de confiar na cópia.

## Cliente Web

O build `flutter build web --release --no-web-resources-cdn --dart-define=API_ORIGIN=https://seu-dominio.example` gera `apps/client/build/web` com renderizador local e origem pública da API. Confira `npm run preview`, `npm run test:visual` e `npm run test:study`, seguindo [Instalação](INSTALACAO.md). Configure HTTPS e fallback `index.html`. Home, aulas e quiz são públicos; conta e Steve usam a API. Firebase Email/Password deve estar habilitado; configure o par chave/modelo exclusivamente no backend. Login fica apenas em memória e requer novo acesso ao recarregar.

A CI verifica API, PostgreSQL17 isolado, restauração de backup, Flutter Web e fluxos Chromium, disponibilizando build/capturas como artefatos. O cliente17 de backup vem do repositório apt do PostgreSQL, seguindo as [instruções oficiais para Ubuntu](https://www.postgresql.org/download/linux/ubuntu/), para acompanhar a versão do serviço. A [execução 37209591233](https://github.com/Binhu01/EstudaAi/actions/runs/37209591233), no commit `75a1070` do PR#3, aprovou os três jobs, incluindo as imagens runtime/migration, ambos os catálogos dentro da imagem e a validação do Caddyfile. Ela não publica, emite certificado público, migra banco remoto nem fornece credenciais de produção. O ensaio no destino continua necessário antes de liberar tráfego.

As actions foram fixadas por SHA após consulta das tags oficiais em 30/09/2026: [checkout v7](https://github.com/actions/checkout/tree/v7), [setup-node v7](https://github.com/actions/setup-node/tree/v7), [upload-artifact v7](https://github.com/actions/upload-artifact/tree/v7) e [flutter-action v2](https://github.com/subosito/flutter-action/tree/v2). A existência dessas referências não confirma uma execução da CI.

## Plataformas nativas e release

Os diretórios Android/iOS/Windows foram gerados pelo SDK. Sua presença não demonstra compilação ou homologação. A CI desta fase não contém jobs nativos. A extensão futura deve usar os executores e ferramentas abaixo, seguindo a [orientação de entrega contínua do Flutter](https://docs.flutter.dev/deployment/cd):

| Plataforma | Ambiente necessário | Primeira verificação proposta |
| --- | --- | --- |
| Windows | Windows, Visual Studio/C++, symlinks autorizados | `flutter build windows --release` |
| Android | SDK Android e JDK compatível (scaffold usa Java 17) | `flutter build apk --debug` |
| iOS | macOS, Xcode e dependências nativas | `flutter build ios --debug --no-codesign` |

Os comandos dessa tabela não foram executados nesta sessão. O uso local de `FLUTTER_WINDOWS=false` viabiliza Web/testes sem mudar o sistema, mas não valida Windows nativo. Os identificadores de plataforma ainda são de scaffold e a configuração Android usa assinatura de debug; não tratá-los como escolhas comerciais aprovadas. Assinaturas finais, contas de lojas, privacidade, certificados, ícones e submissões pertencem à Fase 12.

## Falhas, rollback e dados

Se a migração falhar, mantenha a versão anterior e investigue o histórico antes de tentar novamente. Não repita migrações concorrentes, apague volume ou execute limpeza de banco como correção automática. Voltar a imagem da API não reverte schema; avalie compatibilidade e uma migração corretiva ou restauração testada. O procedimento de rollback ainda precisa de ensaio real.

Para encerrar containers locais preservando o volume:

```powershell
docker compose --env-file .env -f infra/compose.yaml down
```

Não acrescente `--volumes` a esse comando se houver dados a preservar. A evidência das verificações executadas e suas limitações está em [Validação](VALIDACAO.md).
