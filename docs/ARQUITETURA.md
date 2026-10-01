# Arquitetura da fundação

O EstudaAi tem repositório, SDK local, dependências e histórico próprios. Nenhum código da AlmaPet participa da aplicação.

| Área | Responsabilidade implementada |
| --- | --- |
| `apps/client/lib/app` | Bootstrap de preferências, GoRouter, shell responsivo e temas |
| `core` | Perfil Freezed/JSON, fronteira Dio, chave composta de cache e invalidação/cancelamento de contexto |
| `design_system` | Tokens, Material 3, componentes, galeria de desenvolvimento e shader GLSL |
| `features/home` e `settings` | Home sem metas fictícias; tema e movimento persistidos |
| `apps/api/src/auth` | Guard global e verificação Firebase Admin com checagem de revogação |
| `database` e `goals` | Prisma adapter-pg e consultas SQL parametrizadas com proprietário e meta explícitos |
| `entitlements` | Plano FREE e capacidades Premium desativadas no servidor |
| `contracts/openapi.json` | Contrato gerado de saúde, perfil, benefícios e erros seguros |

O cliente atual abre independentemente da API: cadastro/login e CRUD de metas pertencem à próxima fase. `ApiClient` é uma fronteira preparada e testada; o bootstrap ainda não a liga a uma sessão. Não há dados de estudo reais para sincronizar, banco Drift, login simulado ou token salvo em preferências.

Na API, a sequência privada é limite por IP → validação de identidade → resolução idempotente do usuário interno → limite agregado por usuário → handler. Headers enviados pelo cliente não escolhem proprietário ou plano. Exceções públicas são metadata dos handlers de saúde. A memória do rate limiter é adequada à instância única desta fundação; várias réplicas exigem armazenamento compartilhado.

O banco inicial contém `User` e `StudyGoal`. As consultas de meta exigem simultaneamente `userId` e `goalId`, inclusive na atualização. A chave única `(userId,id)` prepara relações compostas para dados privados nas próximas fases. O repositório ainda não é exposto por rotas de CRUD.

`StudyContext.cacheKey` serializa usuário, meta, recurso e parâmetros ordenados sem colisões por separadores. `ContextGate` registra uma geração por ativação; troca de meta/logout dispara os cancelamentos registrados e descarta resultados/erros antigos, inclusive ao voltar à mesma meta. Um futuro repositório pode passar `cancel: cancelToken.cancel` e encaminhar esse token ao Dio. Não há cache global de conteúdo compartilhado entre contas.

O cliente aceita HTTPS e HTTP exclusivamente em loopback local. Requisições não seguem redirects com o bearer token, usam prazo de conexão de 10 s e devolvem falhas tipadas. Não há logger de token ou payload. As preferências de tema/movimento são atualizadas em fila para preservar mudanças simultâneas.

O shader é decorativo, isolado por `RepaintBoundary`, sem semântica interativa e com scrim de leitura. Veja [Shader](SHADER.md) para a correspondência com a referência. Os resultados e limites operacionais estão em [Validação](VALIDACAO.md).
