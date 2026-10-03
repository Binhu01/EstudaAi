# Rotina de estudo Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Preparar login/Steve reais e entregar painel diário e caderno de erros baseados no histórico confirmado de cada aluno.

**Architecture:** NestJS valida a identidade e o catálogo antes de registrar respostas idempotentes em PostgreSQL. Uma meta interna por área separa o histórico; Flutter reutiliza esse contexto no quiz, painel e revisão. Configuração externa e validação ao vivo ficam separadas dos testes controlados.

**Tech Stack:** Stack existente: Node 24.x, NestJS/Prisma/PostgreSQL, Flutter 3.47.5/Dart 3.13.4, Riverpod, Dio e Playwright. Sem troca de provedor ou dependência nova prevista.

**Spec:** `docs/superpowers/specs/2026-10-02-rotina-estudo-design.md`, aprovada pelo usuário em 02/10/2026.

**Execution:** Execução direta pelo implementador, com uma revisão independente do conjunto ao final, preservando a escolha anterior do usuário. Branch `codex/rotina-estudo`, baseada em `ed17772`; usar o worktree isolado existente, sem alterar a branch do PR #1.

## Global Constraints

- Dados privados sempre pertencem a `userId` + `studyGoalId`; proprietário vem da sessão verificada. Relações compostas asseguram propriedade no banco.
- Metas internas `freeStudy` e `bb2026`; fuso inicial `America/Sao_Paulo`; alvo diário padrão 10, opções 5/10/20 questões diferentes. Recordes anônimos e pontuação local não são importados.
- Catálogos atuais são a autoridade para área, módulo, versão, questão e alternativa canônica. Nenhuma alteração do conteúdo ou da pontuação 700.
- Persistir cada resposta, não somente rodadas completas. Servidor calcula acerto/horário; UUID repetido não duplica eventos. Falha de confirmação não prova que o servidor deixou de gravar.
- Caderno `pending`/`reviewed`: erro abre/reabre, acerto confirmado revisa. Histórico de versões anteriores não compõe métricas/revisões atuais. Não afirmar domínio.
- Sessão em memória; cache privado contextual; cancelamento e descarte em saída/troca de conta/meta. Sem fila offline persistente.
- Preservar texto: “Não foi possível confirmar o registro desta resposta. Tente novamente ou continue estudando.” Ações: “Tentar novamente” e “Continuar estudo”.
- Sem conta, painel/caderno oferecem login e quiz continua disponível. Usar estados reais de carregamento, ausência de dados e falha.
- Firebase/OpenAI ausentes conforme o usuário: preparar diagnóstico/roteiro, registrar validação ao vivo pendente até configuração. Segredos fora do Git, cliente e relatórios.
- Verificar 360×800, 768×1024, 1440×1000, texto a 200%, teclado, temas e navegação contextual. Preservar o PR de Concursos e o projeto AlmaPet.

## Review Focus

1. Confirmação perdida, duplo toque e reenvio depois da atualização do catálogo: devolver o evento original sem duplicar nem trocar seu horário (Tasks 1/4).
2. Troca de conta/meta durante renovação do token, seguida de retorno ao contexto inicial: cancelar e nunca enviar dados antigos com a sessão nova (Tasks 3/4).
3. Datas do servidor atravessando meia-noite UTC/São Paulo e histórico de outra versão: indicadores usam datas civis corretas e identidade completa da questão (Task 2).
4. Duas conexões gravando a mesma questão/meta: garantir idempotência, ordem transacional e transições pendente/revisado; não apagar dados antigos na migração (Tasks 1/8).
5. Configuração incompleta, porta ocupada e banco já inicializado: orientar sem revelar segredos, sobrescrever `.env` ou operar outro cluster (Task 7).

## Contratos compartilhados

Definir em `apps/api/src/study/study.models.ts`; os modelos Dart da Task 3 usam os mesmos campos JSON.

```ts
type StudyScope = 'freeStudy' | 'bb2026';
type StudyGoalContext = { id: string; scope: StudyScope; timezone: string; dailyTarget: 5|10|20 };
type StudyAnswerInput = { topicId: string; contentVersion: number; questionId: string; optionIndex: number; source: 'quiz'|'review' };
type ConfirmedAnswer = StudyAnswerInput & { answerId: string; goalId: string; correct: boolean; receivedAt: string };
type SubjectStats = { id: string; title: string; attempts: number; correct: number };
type DailyActivity = { date: string; differentQuestions: number; attempts: number; correct: number };
type StudyDashboard = { goal: StudyGoalContext; today: DailyActivity; pendingErrors: number; activity: DailyActivity[]; subjects: SubjectStats[]; resume: { topicId: string; contentVersion: number } | null };
type StudyErrorItem = { topicId: string; contentVersion: number; questionId: string; wrongCount: number; firstWrongAt: string; lastWrongAt: string; lastAnswerAt: string; lastOptionIndex: number; status: 'pending'|'reviewed'; contentStatus: 'current'|'outdated' };
type ErrorQuery = { status: 'pending'|'reviewed'; subjectId?: string; limit: number; cursor?: string };
type StudyErrorPage = { items: StudyErrorItem[]; nextCursor: string | null };
```

`date` é `YYYY-MM-DD`; horários são ISO UTC. `subjectId` é `topicId` no Estudo livre e `disciplineId` em Concursos. Cursor opaco codifica o contexto/filtro e a tupla `lastWrongAt/topicId/contentVersion/questionId`, é validado e mantém ordenação decrescente com desempate estável. Não aceitar cursor de outra meta ou filtro.

### Task 1: Persistência, metas internas e confirmação atômica

**Files:** Criar `apps/api/prisma/migrations/202610020001_study_history/migration.sql`, `apps/api/src/study/study.models.ts`, `study.service.ts`, `study.queries.ts`, `apps/api/test/helpers/study-fixture.ts`, `test-migrations.ts`, `apps/api/test/study-history.test.ts`. Modificar `apps/api/prisma/schema.prisma`, `apps/api/test/integration/quota-postgres.test.ts`.

**Interfaces:** `StudyHistoryService(database: SqlExecutor & SqlTransactionProvider, directory: StudyDirectory, clock: () => Date)`; métodos `ensureContext(userId: string, scope: StudyScope): Promise<StudyGoalContext>`, `setDailyTarget(userId: string, goalId: string, target: 5|10|20): Promise<StudyGoalContext>`, `confirmAnswer(userId: string, goalId: string, answerId: string, input: StudyAnswerInput): Promise<ConfirmedAnswer>`. SQL parametrizado fica em `study.queries.ts`; decisões de identidade/catálogo ficam no serviço. A fixture fornece banco PGlite, dois proprietários e relógio controlado. `readTestMigrations(): Promise<{name: string; sql: string}[]>`, em `test-migrations.ts`, enumera migrações ordenadas para ambos os bancos de testes.

- [x] **Step 1: Escrever testes RED de preservação, propriedade e confirmação.** Asserções literais: `ensure_twice_returns_same_goal` → mesmo ID/alvo10; `same_user_two_scopes_are_distinct` → dois IDs; `owner_cannot_write_other_goal` →404; `same_uuid_same_body_returns_original` →1 evento/mesmo horário; `changed_body_or_goal_conflicts` →409/1 evento; `wrong_correct_wrong_reopens_error` → estados pending/reviewed/pending e wrongCount2; `confirmed_retry_survives_catalog_update` → evento original; `new_old_version_is_rejected` →409/zero inserções. Inserir meta legada antes da nova migração e verificar ID/nome preservados.

```ts
// ensure_twice_returns_same_goal
const first = await service.ensureContext(userA, 'freeStudy');
assert.equal(first.dailyTarget, 10);
assert.equal((await service.ensureContext(userA, 'freeStudy')).id, first.id);
```

- [x] **Step 2: Acrescentar e observar RED em PostgreSQL real.** No ciclo único do teste existente, usar `readTestMigrations` e preservar recusa de banco diferente de `estuda_ai_integration_test` ou não vazio. Duas conexões: ensure concorrente →uma meta; mesmo UUID →um evento/um erro; corpos distintos →um sucesso/um409; falha na gravação do caderno →nenhum evento parcial; duas metas/usuários →isolamento. Na raiz: build API e `npm run test:pg:local`; para PGlite, em `apps/api`, `node --test dist/test/study-history.test.js`. Esperar falha pela migração/comportamento novo ausente.
- [x] **Step 3: Implementar migração e os três métodos.** `StudyGoal` recebe `contextKey` nullable único por usuário e `dailyTarget` default10/check5,10,20. Criar `StudyAnswer` imutável e `StudyQuestionError` por usuário/meta/topicId/versão/questionId, com FKs compostas para a meta; índices para data, assunto e listagem. O evento recebe `ordinal` bigint gerado pelo banco, interno ao SQL, para ordenar confirmações na mesma meta mesmo com horários iguais. Validar opção0–3, versão positiva, origem e escopo. Travar a meta com `FOR UPDATE`; verificar evento existente antes de rejeitar sua versão antiga; inserir evento e atualizar caderno na mesma transação. UUID de outro corpo/meta conflita; outro proprietário nunca recebe seu evento. O relógio define a recepção de eventos novos dentro da transação; reenvio devolve o horário armazenado.
- [x] **Step 4: Verificar GREEN.** `npm run db:generate`, `npm test`, `npm run test:pg:local` na raiz; a fixture e o banco real devem confirmar rollback de evento/caderno quando a segunda gravação falha. Repetir os cenários de concorrência da Step2.
- [x] **Step 5: Commit.** Incluir somente schema/migração, domínio e testes; mensagem `feat: registrar historico de respostas por meta`.

### Task 2: Resumos, lista de erros e fronteiras HTTP

**Files:** Criar `apps/api/src/study/study.dto.ts`, `study.controller.ts`, `study.calendar.ts`, `apps/api/test/study-http.test.ts`, `study-dashboard.test.ts`. Modificar `study.service.ts`, `study.queries.ts`, `apps/api/src/contracts.ts`, `app.ts`, `main.ts`, `errors.ts`, `apps/api/test/integration/quota-postgres.test.ts`, `contracts/openapi.json`.

**Interfaces:** Acrescentar `readDashboard(userId: string, goalId: string): Promise<StudyDashboard>`, `listErrors(userId: string, goalId: string, query: ErrorQuery): Promise<StudyErrorPage>`. `AppDependencies.study?: StudyHistoryService` permite testes/geração de contrato sem iniciar serviços. `studyDates(now: Date, timezone: string): {date: string; start: Date; end: Date}[]`, em `study.calendar.ts`, produz sete datas civis terminando em hoje e seus intervalos UTC; não recebe data do cliente.

- [x] **Step 1: Escrever RED de HTTP e projeções.** Exercitar as cinco rotas da spec com Nest real e banco de teste; acrescentar contagens diárias e paginação ao ciclo PostgreSQL real existente. `two_answers_same_question_count_one_daily_question` → differentQuestions1/attempts2/correct1; `utc_midnight_keeps_sao_paulo_day` →00:01Z ainda dia anterior; `local_midnight_starts_new_day` →02:59Z/03:00Z em dias distintos; `same_qid_different_topics_are_distinct` →2; `old_version_not_in_dashboard` →zero métricas atuais; `empty_dashboard_has_seven_zero_days` →7 datas/contagens0/resume null; `equal_timestamps_resume_last_confirmed_topic` →segundo tópico inserido. Verificar filtro, cursor incompatível, limite51, propriedades extras, UUID inválido, metas cruzadas, ausência de sessão e dependência ausente.

```ts
// two_answers_same_question_count_one_daily_question, relógio 2026-10-01T12:00:00Z
assert.deepEqual(dashboard.today, {date:'2026-10-01', differentQuestions:1, attempts:2, correct:1});
assert.equal(dashboard.activity.length, 7);
```
- [x] **Step 2: Executar RED.** Build API e, em `apps/api`, `node --test dist/test/study-http.test.js dist/test/study-dashboard.test.js`; na raiz, `npm run test:pg:local`. Esperar rotas/projeções ausentes.
- [x] **Step 3: Implementar as cinco rotas exatas da spec.** Status200 em sucesso;404 para meta sem vínculo;400 para DTO/consulta inválidos;409 para conflito ou conteúdo atualizado;503 quando histórico indisponível. `HistoryConflict` e `HistoryContentChanged`, em `errors.ts`, expõem somente os códigos seguros `CONFLICT` e `CONTENT_CHANGED` no filtro/OpenAPI. Corpo de PUT contém apenas `StudyAnswerInput`; alvo contém `{dailyTarget}`; ensure valida um DTO vazio e recusa propriedades extras. Query padrão status pending/limit20, máximo50. Dashboard exclui versões antigas; lista pode indicar item antigo como outdated, sem permitir revisão pela versão atual. Resumo e seus agregados usam leitura consistente; último tópico confirmado usa o maior ordinal do contexto. Registrar serviço no bootstrap e controlador nos guards existentes.
- [x] **Step 4: Verificar GREEN.** `npm test`, `npm run openapi`, `npm run test:pg:local`. Conferir respostas/códigos, enum de identidades confiáveis e ausência de segredos. Testes existentes de autenticação/cota permanecem verdes.
- [x] **Step 5: Commit.** `feat: expor painel diario e caderno por conta`.

### Task 3: Cliente de histórico e contexto privado

**Files:** Criar `apps/client/lib/features/study_history/study_history_models.dart`, `study_history_api.dart`, `study_context_controller.dart`, `answer_submission.dart`; testes `apps/client/test/study_history_api_test.dart`, `study_history_context_test.dart`, `helpers/study_history_fixtures.dart`. Modificar `apps/client/lib/core/api_failure.dart`.

**Interfaces:** `StudyHistoryApi` usa origem validada/Dio/token, os cinco métodos da API e `CancelToken`. Cada chamada recebe `stillCurrent: bool Function()` e verifica-o antes/depois de aguardar o token e antes de aplicar a resposta. `StudyContextController.ensureActive(): Future<StudyGoalContext?>` mantém `StudyContext`, escopo, geração de sessão e seleção; observa sessão/área. `AnswerSubmissionController.submit(StudyAnswerInput)`, `retry()`, `continueStudy()`, `cancel()` expõem estado `idle/sending/confirmed/unconfirmed`, evento imutável e resposta confirmada. Gerar UUIDv4 com `Random.secure`, uma vez por toque, sem pacote novo.

- [x] **Step 1: Escrever RED.** `delayed_token_after_account_change_sends_nothing` →zero HTTP; `return_to_same_scope_does_not_accept_old_result` →resposta antiga descartada; `retry_reuses_id_and_payload` →mesmo UUID/corpo; `confirmed_old_version_ack_matches_captured_intent` →confirmação aceita após atualização do catálogo; `logout_clears_private_state` →contexto/resumos apagados; `foreign_goal_or_malformed_reply_is_rejected` →INVALID_RESPONSE;409 distingue CONFLICT/CONTENT_CHANGED. Usar transportes controlados somente nos testes e literais dos contratos, não chamadas externas.

```dart
// delayed_token_after_account_change_sends_nothing
expect(transport.sentRequests, isEmpty);
// retry_reuses_id_and_payload
expect(transport.sentRequests[1].uri, transport.sentRequests[0].uri);
expect(transport.sentRequests[1].data, transport.sentRequests[0].data);
```
- [x] **Step 2: Executar RED.** Em `apps/client`: `flutter test test/study_history_api_test.dart test/study_history_context_test.dart`; esperar recursos novos ausentes.
- [x] **Step 3: Implementar modelos e contextos.** Parsing estrito de datas, números, enumerações e relação goal/topic/version/question. Novos envios conferem o catálogo local; confirmação devolvida deve corresponder exatamente ao intento capturado, incluindo UUID/meta/opção/origem. Aceitar a confirmação de um evento antigo já salvo mesmo após atualização do catálogo, sem incluí-lo nas métricas atuais. Reutilizar `ContextGate` e gerações da sessão/seleção. Privacidade do cache por usuário/meta/recurso/filtros; limpeza na saída. Sem armazenar tokens ou respostas pendentes em disco. Mapear novos códigos sem mudar mensagens de Steve/cota.
- [x] **Step 4: Verificar GREEN.** `flutter test` e `flutter analyze`; incluir sessão expirada, dependência indisponível e resposta recebida depois de cancelamento.
- [x] **Step 5: Commit.** `feat: integrar historico com contexto autenticado`.

### Task 4: Gravação de cada resposta no quiz

**Files:** Modificar `apps/client/lib/features/quiz/quiz_engine.dart`, `quiz_controller.dart`, `quiz_screen.dart`; testes `quiz_engine_test.dart`, `quiz_screen_test.dart`, criar `apps/client/test/quiz_history_test.dart`.

**Interfaces:** `QuizEngine.canonicalOptionIndex(displayedIndex): int` preserva o mapeamento criado no embaralhamento. `QuizController.answer(index)` envia `StudyAnswerInput` com source quiz quando autenticado; `next()` só avança após confirmação ou decisão explícita. Score/best atuais continuam independentes. Reutilizar `AnswerSubmissionController` da Task 3, sem gerar novo UUID ao tentar novamente.

- [x] **Step 1: Escrever RED.** Quatro opções identificadas por índices literais continuam correspondendo após embaralhamento; duplo toque →um evento; abandono após primeira resposta →uma resposta confirmada; confirmação perdida + retry →um evento/mesmo ID; “Continuar estudo” →sem novo envio automático; nova rodada/logout cancela envio antigo. Quiz anônimo →zero chamadas de histórico e rodada/recorde existentes preservados.

```dart
// Opções originais da fixture: ['A', 'B', 'C', 'D']; índice canônico de C = 2.
expect(engine.canonicalOptionIndex(engine.state.question.options.indexOf('C')), 2);
// double_tap_writes_one_answer
expect(transport.answerRequests.length, 1);
```
- [x] **Step 2: Executar RED.** `flutter test test/quiz_engine_test.dart test/quiz_history_test.dart`; esperar mapeamento/gravação ausentes.
- [x] **Step 3: Implementar integração.** Mostrar feedback imediatamente; bloquear avanço enquanto envia. Falha usa texto e duas ações das Global Constraints. Ao continuar, cancelar o pedido/abandonar confirmação, sem prometer rollback. Mudança de contexto cancela o envio capturado; atualizar provedores de painel/caderno somente para confirmação válida da meta ativa.
- [x] **Step 4: Verificar GREEN.** `flutter test` e `flutter analyze`; conferir rodada completa, pontuação máxima700, recordes locais e texto a200%.
- [x] **Step 5: Commit.** `feat: salvar respostas do quiz sem duplicacao`.

### Task 5: Painel diário e navegação

**Files:** Criar `apps/client/lib/features/study_history/dashboard_controller.dart`, `dashboard_screen.dart`, `study_history_widgets.dart`, `apps/client/test/dashboard_screen_test.dart`, `tools/verify-routine.mjs`. Modificar `apps/client/lib/app/app.dart`, `shell.dart`, `features/home/home_screen.dart`, `features/contests/contests_screen.dart`.

**Interfaces:** Rota `/meu-estudo`; `DashboardController.load()/retry()/setDailyTarget(5|10|20)` consome contexto/API das Tasks 2/3 e expõe `StudyDashboard`. Atalhos “Meu estudo” nas entradas existentes e na navegação desktop; celular usa acesso no cabeçalho, sem acrescentar mais um destino à barra inferior.

- [x] **Step 1: Escrever RED.** Tela sem conta →ação de login; sem histórico →orientação inicial/zero dados reais; payload com differentQuestions2/target10/attempts3/correct1 →rótulos corretos; sete dias incluem zeros; pendentes2 →link ao caderno; scope trocado →sem mostrar métricas antigas. Alvo5/10/20 enviado uma vez; falha mantém alvo confirmado anterior. Último topic/versão inválido oferece recuperação, sem criar rota quebrada.

```dart
// dashboard_uses_confirmed_distinct_questions, fixture 2/10 e 1 acerto em 3 tentativas
expect(find.text('2 de 10 questões diferentes'), findsOneWidget);
expect(find.text('1 acerto em 3 tentativas'), findsOneWidget);
```

- [x] **Step 2: Executar RED.** `flutter test test/dashboard_screen_test.dart`; acrescentar ao `verify-routine.mjs` login gate/painel vazio/painel confirmado/alvo/troca de conta e executar contra build Web da Task4. Esperar tela/navegação novas ausentes antes da Step3. Fixtures de rede só dentro do teste, com relatório identificando transporte controlado.
- [x] **Step 3: Implementar painel.** Seleção de área atualiza `learningProvider`; garantir catálogo/contexto antes de carregar. Mostrar os seis elementos da spec. Retomar via `StudyRoutes`, conferindo versão e existência; primeiro estudo usa a seleção válida existente. Carregamento, vazio e erro separados; métricas vêm do servidor, não de bestScore. Componentes semânticos do design system, sem gráfico que dependa apenas de cor.
- [x] **Step 4: Verificar GREEN.** `flutter test` e `flutter analyze`; testes em360/768/1440, texto200%, teclado e temas; entrada/retorno para conta preservam contexto.
- [x] **Step 5: Commit.** `feat: mostrar rotina diaria com dados reais`.

### Task 6: Caderno e prática de revisão

**Files:** Criar `apps/client/lib/features/study_history/errors_controller.dart`, `errors_screen.dart`, `error_review_screen.dart`, `apps/client/test/errors_screen_test.dart`, `error_review_test.dart`. Modificar `apps/client/lib/app/app.dart`, `tools/verify-routine.mjs` e reutilizar `study_history_widgets.dart`.

**Interfaces:** Rotas `/meus-erros` e `/meus-erros/:topicId/:contentVersion/:questionId`; `ErrorsController.load(ErrorQuery)/nextPage()/retry()` usa a meta ativa, padrão pending/20. A revisão resolve a questão no catálogo e usa `AnswerSubmissionController` com source review. Não criar endpoint para marcar resolvido.

- [x] **Step 1: Escrever RED.** Gabarito/comentário ocultos antes da escolha; uma revisão errada permanece pending, correta confirmada vira reviewed; falha não altera estado por otimismo; item outdated/questão removida não gera PUT e oferece conteúdo atual; filtros/paginação não duplicam itens, distinguem scopes e descartam páginas antigas. Todos os atalhos de material/aulas/Steve conservam o módulo; material só aparece se existir.

```dart
// review_hides_feedback_until_answer, comentário literal da fixture
expect(find.text('Comentário da questão'), findsNothing); // antes de responder
expect(find.text('Comentário da questão'), findsOneWidget); // depois de responder
```

- [x] **Step 2: Executar RED.** `flutter test test/errors_screen_test.dart test/error_review_test.dart`; estender `tools/verify-routine.mjs` com quiz errado→caderno→revisão correta→revisado e confirmação perdida→retry. Rodar contra build da Task5 antes da Step3; esperar caderno/revisão ausentes.
- [x] **Step 3: Implementar lista/revisão.** Separar visualmente itens outdated e impedir sua prática pelo conteúdo novo. Rótulo “Revisado” nunca “Dominado”. Exibir questão canônica, escolha travada, comentário pós-resposta e as mesmas ações de confirmação do quiz. Filtros enumerados a partir do catálogo do escopo; limpar paginação quando mudam. Login requerido sem bloquear conteúdos públicos.
- [x] **Step 4: Verificar GREEN.** `flutter test`, `flutter analyze`; texto200%, teclado, lista vazia/erro, respostas longas e entrada direta por link em outra área.
- [x] **Step 5: Commit.** `feat: revisar erros por materia e contexto`.

### Task 7: Ambiente local e roteiro de serviços reais

**Files:** Criar `tools/local-postgres.ps1`, `tools/check-local-config.mjs`, `tools/test/local-config.test.mjs`, `tools/test-local-postgres.ps1`, `tools/verify-live-study.mjs`, `docs/ROTINA-CONFIGURACAO.md`. Modificar `.env.example`, `package.json`, `docs/INSTALACAO.md`.

**Interfaces:** `local-postgres.ps1 -Action Init|Start|Status|Stop -Port 55433 [-DataRoot <caminho>]`: cluster padrão em `.tooling/pg-local`; DataRoot opcional deve estar sob `.tooling` no worktree e sem reparse points. Loopback, SCRAM, senha local com ACL restrita, sem sobrescrever `.env` existente. O teste usa `.tooling/pg-local-test/<UUID>` próprio e confirma caminho/identidade antes de qualquer limpeza. `checkLocalConfig(env, probe): Promise<ConfigReport>`; `ConfigReport` possui database/firebase/steve/cors, cada qual `{status: 'missing'|'invalid'|'configured'|'verified', issues: string[]}`, e `readyForLiveTest: boolean`. `probe` verifica conectividade/schema do banco e compatibilidade da credencial Firebase com o projeto, sem imprimir argumentos. Firebase/OpenAI completos recebem configured; a comprovação externa exige o roteiro real. readyForLiveTest exige banco/schema e CORS verificados e provedores configured. CLI `node --env-file-if-exists=.env tools/check-local-config.mjs` não envia perguntas à IA. `verify-live-study.mjs` exige configuração e conta de teste fornecida por ambiente local; não contém credenciais literais e não roda na CI comum.

- [x] **Step 1: Escrever RED.** Configuração vazia lista pendências, sem fabricar ready; segredos sentinela não aparecem em stdout/erro/relatório; SELECT1 com tabelas ausentes não certifica schema; projeto Firebase divergente e modelo/chave com formato inválido são recusados; prévia4174 fora de CORS é indicada. Teste operacional: init/start/escrever sentinela/stop/start →sentinela preservada; init repetido não troca senha/dados; porta ocupada/cluster alheio/DataRoot fora de .tooling recusados; `.env` preexistente preservado.

```js
// missing_services_do_not_claim_readiness
assert.equal(report.firebase.status, 'missing');
assert.equal(report.steve.status, 'missing');
assert.equal(report.readyForLiveTest, false);
```
- [x] **Step 2: Executar RED.** `node --test tools/test/local-config.test.mjs` e `powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools/test-local-postgres.ps1`; esperar utilitários ausentes. O teste usa cluster temporário próprio, nunca o cluster persistente de estudo.
- [x] **Step 3: Implementar operação e guia.** Reutilizar verificações de caminhos/identidade de `tools/test-postgres.ps1`; usar PostgreSQL18 instalado, sem instalar serviço do Windows. Init não aplica migração automaticamente. Documentar migração explícita, Firebase e-mail/senha/credencial Admin, OpenAI modelo/chave e configuração no `.env` local. Acrescentar CORS localhost/127.0.0.1 nas portas4173/4174. Consultar documentação oficial atual antes de escrever os passos dos provedores externos.
- [x] **Step 4: Preparar roteiro real separado.** Sem configuração, encerrar como pendente antes de criar conta/chamar serviços. Quando configurado, conferir cadastro/login/perfil/renovação/senha incorreta/saída; três perguntas ao Steve em ambos os contextos, fontes/cota; gravação de histórico e retomada na mesma conta. Sem HAR/trace/captura de senhas, tokens ou conversas; relatório sanitizado. Recuperação de senha fica explicitamente acionada pelo operador para seu e-mail de teste, sem envio automático.
- [x] **Step 5: Verificar GREEN e registrar o limite real.** Testes de diagnóstico/operação, `npm test`, geração/migrações no banco local próprio e preservação após reinício. Sem Firebase/OpenAI, registrar live login/IA como pendentes; não substituir por demonstração no produto.
- [x] **Step 6: Commit.** `chore: preparar configuracao e validacao dos servicos reais`.

### Task 8: PostgreSQL real, percursos e revisão final

**Files:** Modificar `.github/workflows/ci.yml`, `package.json`, `README.md`, `docs/VALIDACAO.md`, `tools/verify-routine.mjs`; criar `docs/ROTINA-ESTUDO.md`. Atualizar os checkboxes deste plano conforme evidências. Os testes PostgreSQL e navegador foram criados antes dos recursos nas Tasks1/2/5/6.

**Interfaces:** `npm run test:routine` executa `tools/verify-routine.mjs` com `PREVIEW_URL`; relata viewports/flows/internalErrors e mantém fixtures de conta/backend controladas exclusivamente no teste. Roteiro real continua em `verify-live-study.mjs`, separado e sem credenciais da CI.

- [x] **Step 1: Conferir evidências RED→GREEN das Tasks1/2/5/6.** O mesmo banco dedicado testa quota/histórico em um ciclo, sem disputa por schema. Conferir migrações aplicadas, concorrência/rollback, tempos/filtros e recusa de banco errado/não vazio. SQL de contagem usa `count(*)::int` para oráculos numéricos.

```ts
// same_uuid_on_two_connections_creates_one_event, rows vem do PostgreSQL real
assert.equal(rows[0].count, 1);
```

- [x] **Step 2: Executar os percursos completos.** Navegador nos três tamanhos: login gate, painel vazio/real, alvo, quiz errado→caderno→revisão correta→revisado, falha de confirmação→retry, logout/conta diferente, troca de área e continuidade livre/Concurso. Executar a UI release real, conferir requests/resultados, teclado, capturas e erros internos. Relatórios identificam fixtures controladas e não afirmam autenticação/IA ao vivo.
- [x] **Step 3: Verificar suíte/builds completos.** `npm test`, `npm run test:pg:local`, testes tools, verificador integral do catálogo, `npm run openapi`; no cliente, geração de modelos quando aplicável, format check, `flutter analyze`, `flutter test`, build Web release. Na prévia: `test:visual`, `test:study`, `test:contests`, `test:routine`. Windows usa `FLUTTER_WINDOWS=false` no processo, como na base. Conferir diff/hash de catálogos: esta entrega não muda conteúdo.
- [x] **Step 4: Atualizar CI e evidências.** CI roda testes de configuração e `test:routine`; mantém integração PostgreSQL e nunca injeta credenciais reais em fixtures públicas. Documentar comandos, resultados, limites do ambiente, migração, funcionamento do painel/caderno e pendência de serviços externos. Atualizar README com a evidência remota anterior e esta fase, sem repetir a afirmação histórica de que nenhuma CI foi executada.
- [x] **Step 5: Fazer uma revisão independente do conjunto.** Usar o fluxo de revisão previsto para execução direta; verificar privacidade, relógio, UUID/embaralhamento, migração, falhas e critérios da spec. Confirmar achados antes de corrigir e registrar decisões/limites. Não criar uma revisão nova por tarefa.
- [x] **Step 6: Fechar com evidência.** Repetir apenas checks afetados por correções e os checks obrigatórios do fluxo. Registrar execução ao vivo como pendente se ainda faltarem serviços. Manter a branch de Concursos/PR1 intacta; apresentar o resultado concreto e a decisão de integração ao final. Commit `test: verificar rotina de estudo de ponta a ponta`.

## Autorrevisão e revisão do usuário

Cobertura conferida: identidade/metas/SQL →Task1; métricas/tempo/HTTP →Task2; contexto/cliente →Task3; quiz →Task4; painel →Task5; caderno →Task6; configuração/validação ao vivo →Task7; PostgreSQL/navegador/CI/documentação/revisão →Task8. Os cinco riscos do Review Focus possuem testes nos responsáveis. Os contratos de entrada/saída são únicos e reaproveitados, sem proprietário ou horário definidos pelo cliente.

Plano aprovado pelo usuário; implementação, verificação e revisão final concluídas. Método de execução direta e envio de branch/Pull Request já escolhidos; não solicitar novamente essas escolhas. As credenciais ausentes limitam somente a comprovação ao vivo, não os testes e a implementação do histórico. Revisão, decisões e ajuste menor adiado em `docs/ROTINA-REVISAO.md`.
