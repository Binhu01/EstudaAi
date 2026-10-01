# Arquitetura

O EstudaAi tem repositório, SDK local, dependências e histórico próprios. Nenhum código da AlmaPet participa da aplicação.

| Área | Responsabilidade implementada |
| --- | --- |
| `apps/client/lib/app` | Bootstrap de preferências, GoRouter, shell responsivo e temas |
| `core` | Perfil Freezed/JSON, fronteira Dio, chave composta de cache e invalidação/cancelamento de contexto |
| `design_system` | Tokens, Material 3, componentes, galeria de desenvolvimento e shader GLSL |
| `features/home`, `learning`, `quiz` e `settings` | Hero, catálogo, players sob escolha, quiz local; tema e movimento persistidos |
| `features/auth` e `steve` | Sessão em memória, refresh compartilhado, chat cancelável por assunto/conta/geração |
| `apps/api/src/auth` | Guard global e verificação Firebase Admin com checagem de revogação |
| `apps/api/src/catalog` e `steve` | Catálogo confiável, tutor Responses e cota persistida/transacional |
| `database` e `goals` | Prisma adapter-pg e consultas SQL parametrizadas com proprietário e meta explícitos |
| `entitlements` | Plano FREE e capacidades Premium desativadas no servidor |
| `contracts/openapi.json` | Contrato gerado de saúde, perfil, benefícios e erros seguros |

Home, aulas e quiz abrem independentemente da API. Cadastro/login obtêm sessão Firebase pelo backend e validam `/v1/me` antes de liberar Steve. ID token, refresh token e conversa permanecem em memória; logout cancela chamadas e troca a geração. Refreshes simultâneos compartilham uma única chamada. Falhas temporárias preservam a conta confirmada, mas um token expirado nunca é enviado. Não há login simulado nem token salvo em preferências. CRUD de metas e sincronização de estudo ainda não são expostos.

Na API, a sequência privada é limite por IP → validação de identidade → resolução idempotente do usuário interno → limite agregado por usuário → handler. Headers enviados pelo cliente não escolhem proprietário ou plano. Saúde e autenticação são handlers públicos com metadata explícita; autenticação tem budget próprio. Os limites por minuto e a exclusão de chamadas simultâneas do Steve são por instância; várias réplicas exigem armazenamento compartilhado.

O banco contém `User`, `StudyGoal`, `AiDailyUsage` e `AiQuotaReservation`. As consultas de meta exigem simultaneamente `userId` e `goalId`, inclusive na atualização; o repositório ainda não é exposto por rotas de CRUD. A cota diária do Steve bloqueia global → usuário → reserva na mesma transação, impedindo ultrapassar limites com conexões concorrentes. A reserva só é devolvida se a chamada ao provedor ainda não começou; timeout ou cancelamento posterior não garantem ausência de cobrança. Renovação ocorre à meia-noite UTC. Não se grava o conteúdo do chat nas tabelas de cota.

`StudyContext.cacheKey` serializa usuário, meta, recurso e parâmetros ordenados sem colisões por separadores. `ContextGate` registra uma geração por ativação; troca de meta/logout dispara os cancelamentos registrados e descarta resultados/erros antigos, inclusive ao voltar à mesma meta. Um futuro repositório pode passar `cancel: cancelToken.cancel` e encaminhar esse token ao Dio. Não há cache global de conteúdo compartilhado entre contas.

O cliente aceita HTTPS e HTTP exclusivamente em loopback local. Requisições não seguem redirects com o bearer token, usam prazo de conexão de 10 s e devolvem falhas tipadas. Não há logger de token ou payload. As preferências de tema/movimento são atualizadas em fila para preservar mudanças simultâneas.

O catálogo canônico é `apps/client/assets/study/catalog.json`, carregado pelo Flutter e copiado byte a byte ao build da API. IDs, versões, fontes, questões e alternativas são validados. Cada rodada sorteia cinco questões e embaralha alternativas preservando o gabarito; o melhor resultado é local por assunto/versão. Players YouTube só são criados após escolher a aula, sem autoplay; há link externo em Web/nativos.

Steve recebe somente tópico, pergunta e até oito mensagens de pares concluídos, com cada mensagem até 2.000 e total até 12.000 caracteres. O servidor injeta notas/FAQ/fontes confiáveis; o cliente não injeta instruções privilegiadas. A família do chat inclui usuário interno, assunto e gerações; trocar assunto, sair, nova conversa ou dispose cancela a chamada e descarta respostas antigas. Texto é renderizado sem executar HTML/Markdown; links são ações separadas do catálogo. `completed`, `refused` e `incomplete` têm estados distintos.

O adaptador Responses usa `store:false`, limite de 800 tokens, timeout de 30 s e nenhuma repetição automática. Não envia ID/e-mail ao provedor. `store:false` não equivale a uma promessa geral de ausência de retenção pelo provedor. O cliente espera no máximo 45 s. Credencial e modelo são configuração exclusiva do backend; sem configuração, há falha segura.

O shader é decorativo, isolado por `RepaintBoundary`, sem semântica interativa e com scrim de leitura. Pausa quando o detalhe sai da tela, em movimento reduzido ou pela preferência do usuário. Veja [Shader](SHADER.md), [Experiência](EXPERIENCIA-ESTUDO.md) e [Validação](VALIDACAO.md).
