# Operação e preparação de deploy

**Nenhum deploy foi feito.** Docker/Compose, integração Firebase real e adapter Prisma/PostgreSQL não foram executados nesta sessão. Este guia define o procedimento a validar em ambiente separado. A fundação não está homologada para operação comercial.

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
- Implementar e testar confiança em proxies conhecidos no backend antes de depender de IP encaminhado. O código atual não configura `trust proxy`; atrás de um proxy, o limite por IP pode agrupar clientes pelo endereço do proxy.
- Manter uma instância enquanto o rate limiter usar memória. Armazenamento compartilhado e testes de múltiplas réplicas são pré-requisitos para escala horizontal.
- Validar o adapter Prisma com PostgreSQL real, o job de migração e as credenciais Firebase; PGlite/doubles não cobrem essas integrações.
- Verificar token inválido, expirado, revogado e de outro projeto com o serviço Firebase real, sem registrar tokens.
- Definir backups, retenção, restauração, rotação de credenciais e monitoramento de indisponibilidade.

`/health/live` e `/health/ready` são públicos. Readiness executa `SELECT 1`, portanto não verifica Firebase ou presença das tabelas. O monitoramento deve incluir também um teste privado controlado após migrações. Logs da API contêm request ID, rota, método, status e duração; não acrescente credenciais ou payloads pessoais ao coletor.

## Cliente Web

O build `flutter build web --release --no-web-resources-cdn` gera `apps/client/build/web` com os recursos do renderizador locais. Confira a saída com `npm run preview` e `npm run test:visual`, seguindo a preparação Playwright em [Instalação](INSTALACAO.md). Publique essa pasta somente depois de validação visual e testes do ambiente. Configure o host para devolver `index.html` ao navegar diretamente para rotas do aplicativo e sirva por HTTPS. A Home e Preferências não dependem de login nesta entrega; o bootstrap ainda não integra autenticação ou conexão à API.

A CI preparada em `.github/workflows/ci.yml` verifica API e Flutter Web no Ubuntu e disponibiliza o build Web como artefato. Ela não publica imagens, sites ou apps, não executa migração em banco remoto e não fornece credenciais de produção. **O workflow ainda não foi executado no GitHub; não há resultado remoto verde declarado.**

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
