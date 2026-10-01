# Conta, Steve e verificação — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Conectar cadastro/login e Steve real à interface, com contexto isolado e verificação completa da experiência.

**Architecture:** Cliente usa contratos de C1/C3 pela origem API configurada, mantém sessão somente em memória e coordena refresh por geração. Controller de chat por tópico cancela resultados atrasados e oferece estados explícitos de indisponibilidade, recusa e resposta incompleta.

**Tech Stack:** Flutter/Riverpod/GoRouter/Dio existentes, Playwright existente para Web, gateway Firebase e provider Responses de C.

**Spec:** [Especificação](../specs/2026-09-30-experiencia-estudo-design.md), [contratos globais](2026-09-30-experiencia-estudo.md).

## Global Constraints

Todas as restrições do índice. Token/refresh só em memória e login novamente após recarregar. Renovação temporariamente indisponível não encerra sessão válida; logout cancela e invalida geração. Steve usa tópico real/Estudo livre, até oito mensagens anteriores e 12.000 caracteres; pergunta2.000, recebimento45s, uma pendência e sem retry automático. Não mostrar doubles como produto nem conteúdo de outro assunto. Textos pt-BR, controles48px e reflow200% em360/768/1440.

## Review Focus

Refresh simultâneo compartilha uma chamada; logout no meio dele não restaura token. 429/503 preserva credencial em memória sem enviar token vencido. Troca de assunto/conta ou ida e volta não insere mensagem antiga. Falha de API deixa aulas/quiz disponíveis. Fontes nunca viram HTML executável.

### Task 1: D1 — Cliente de auth, sessão e formulário

**Files:** Criar `apps/client/lib/features/auth/auth_api.dart`, `session_controller.dart`, `account_screen.dart`, `auth_models.dart`, `core/api_origin.dart`; modificar `main.dart`, `core/api_client.dart`, `app/app.dart`, `app/shell.dart`; criar `test/auth_api_test.dart`, `session_test.dart`, `account_screen_test.dart`, modificar `api_client_test.dart`.

**Interfaces:** Consome AuthSessionResponse, quatro endpoints C1 e UserProfile existente. Produz AuthSession.fromJson com campos idToken/refreshToken/expiresInSeconds e `Future<AuthSession> AuthApi.register(String email,String password)`, `login(String email,String password)`, `refresh(String refreshToken)`, `Future<void> resetPassword(String email)` via Dio; `Future<void> SessionController.register(String email,String password)`, `Future<void> login(String email,String password)`, `Future<void> resetPassword(String email)`, `Future<String?> accessToken()`, `void signOut()`. SessionState expõe status=`signedOut|authenticating|authenticated|refreshUnavailable`, UserProfile? e erro seguro; credenciais privadas em memória. `sessionProvider`; apiClientProvider injeta accessToken na ApiClient existente. Origem via dart-define API_ORIGIN, default apenas loopback de desenvolvimento; HTTPS para origem externa e sem redirects.

- [ ] Escrever testes Dio com adapter controlado: sessão válida parseada, corpo malformado/validade inválida rejeitado, password-reset genérico e limites de campos preservados. Tokens não vão para prefs/logs. Dois accessToken próximos do vencimento chamam refresh uma única vez e recebem mesmo token renovado.
- [ ] Testar sequência logout enquanto refresh está pendente: resultado atrasado descartado e state permanece signedOut. 429/503/rede mantém token ainda válido e refresh em memória; se ID token já venceu, accessToken falha com indisponibilidade sem mandar bearer expirado. Credencial definitivamente inválida limpa tudo. Rodar `flutter test test/auth_api_test.dart test/session_test.dart` e observar falhas anteriores ao código.
- [ ] Implementar modelos estritos/AuthApi e SessionController com expiresAt calculado do expiresInSeconds, refresh preventivo30s, Future compartilhado e geração. Depois de login/register buscar readMe para identidade interna; sem perfil validado não apresentar aluno conectado. Falha temporária conserva credencial de auth para tentar concluir perfil; rejeição de identidade limpa sessão. Nunca armazenar senha no estado da sessão.
- [ ] Formulário `/conta`: Entrar/Criar conta/Recuperar senha, labels associados, validação/erros em português, ocultação da senha, loading e prevenção de duplicados; informar que fechar/recarregar exige novo login. Limpar senha após operação/saída e dispose de controllers. Falha do backend mostra recuperação útil sem pedir chaves API ao aluno.
- [ ] Testar widget submit/login/erro e recuperação, teclado/Enter, texto200% e feedback sem revelar conta existente. Integrar Conta/Entrar/Sair e provedores, sem mudar origem segurança da ApiClient; `flutter analyze` e commit `feat: conectar conta e sessão em memória`.

### Task 2: D2 — Cliente e chat Steve contextual

**Files:** Criar `apps/client/lib/features/steve/steve_api.dart`, `steve_models.dart`, `steve_controller.dart`, `steve_screen.dart`, `steve_message.dart`; modificar `app/app.dart`, `app/shell.dart`, `features/home/home_screen.dart`, `features/learning/learning_screen.dart`; criar `test/steve_api_test.dart`, `steve_context_test.dart`, `steve_screen_test.dart`.

**Interfaces:** Consome SteveReply/ChatMessage de C3, sessionProvider, learningProvider e PixelAvatar. Produz `Future<SteveReply> SteveApi.send({required String topicId,required String message,required List<ChatMessage> history,required CancelToken cancelToken})`, `SteveController.send(String text)`, `newConversation()`, `dispose`; steveProvider family por tópico e sessão interna; `SteveScreen(topicId:String)` e rota `/steve/:topicId`. Histórico é a sequência de pares concluídos; entrada atual separada não se duplica no histórico enviado.

- [ ] Escrever testes de cliente: header bearer correto, recebimento45s, parsing/status/quota/resetAt/requestId e fontes HTTPS conhecidos; corpo inválido rejeitado, 401 exige acesso, 429 informa espera/limite, 503 informa indisponibilidade sem resposta simulada. Novo envio corta histórico aos últimos oito e, se necessário, remove mensagens antigas inteiras até≤12.000 caracteres.
- [ ] Testar gerações com Futures controlados: enviar em porcentagem, trocar para ecologia, concluir resposta antiga → nenhuma mensagem antiga; ida e volta também descarta; logout/troca de conta/nova conversa abortam CancelToken e limpam histórico; dispose não atualiza state. Asserções: `expect(controller.state.messages, isEmpty); expect(cancelToken.isCancelled, isTrue);`. Rodar os novos testes antes de implementar.
- [ ] Implementar controller com uma chamada pendente, validação2.000, CancelToken e snapshot `(internalUserId,topicId,generation)`. Guardar histórico somente em memória por conversa. Ouvir contexto/sessão e invalidar família/cancelamento no ciclo de vida; newConversation incrementa geração. Quota exibida é a retornada pelo backend, jamais calculada como entitlement concedido pelo cliente.
- [ ] Implementar tela com nome Steve, avatar pixel, assunto/Estudo livre, sugestões autorais e campo/envio. Sem sessão, mostrar entrar na conta. Renderizar resposta como Text seguro, links do catálogo em ações separadas. completed/refused/incomplete têm texto de estado distinto; incompleta não entra no histórico como explicação completa. Erro conserva pergunta para edição/tentativa manual e não grava resposta vazia.
- [ ] Integrar Steve nas três navegações, hero e ação Perguntar ao Steve na aula com mesmo tópico. Verificar quiz→aula→Steve e trocas rápidas; erro/ausência de API não bloqueia aulas/quiz. Rodar testes, análise, texto200%/teclado e commit `feat: entregar chat do Steve por assunto`.

### Task 3: D3 — Experiência completa, revisão e documentação

**Files:** Modificar `tools/verify-web.mjs`, `README.md`, `docs/INSTALACAO.md`, `docs/ARQUITETURA.md`, `docs/VALIDACAO.md`, `docs/DEPLOY.md`, `.github/workflows/ci.yml`; criar `docs/EXPERIENCIA-ESTUDO.md`, `tools/verify-study.mjs`, `apps/client/test/study_flow_test.dart`; manter relatório/capturas em `artifacts/` ignorado e checkboxes dos planos.

**Interfaces:** Consome rotas e contratos A–D. Produz preview com build real, evidência por plataforma e guia de configuração; nenhum endpoint ou identidade de demonstração.

- [ ] Escrever teste de fluxo widget com dependências de transporte explicitamente de teste: assunto→aulas→quiz de cinco questões→resultado→Steve sem sessão→conta; verificar assunto em todos os passos. O produto não recebe esse transporte. Rodar teste e corrigir somente falhas da integração.
- [ ] Atualizar verify-web: heading Home novo, seleção por prefixo de rotas, shader clip estável no detalhe visível; conservar temas, persistência, teclado, reducedMotion e verificação pixel de shader. Criar verify-study para três viewports, escolher cada assunto, iniciar rodada, selecionar uma resposta, conferir feedback, chegar ao resultado e voltar às aulas; localizar iframe pelo videoId e confirmar watch link. Capturar estados hero/quiz/Steve indisponível sem alegar autenticação real.
- [ ] Executar `npm test`, `npm run test:pg:local`, `npm run openapi`; no cliente, format, analyze, todos os testes e build release `--no-web-resources-cdn`. Copiar build para preview do checkout correto ou iniciar preview nele, sem mover silenciosamente app para outro projeto. Rodar `npm run test:visual` e novo `npm run test:study`; inspecionar capturas e console, corrigir falhas.
- [ ] Verificar YouTube no navegador: reprodução quando permitida e fallback em bloqueio/indisponibilidade. Separar erros externos do player dos erros próprios da aplicação no relatório, sem ocultar exceções internas. Tests podem constatar iframe/link sem afirmar playback. Confirmar link externo em gesto de usuário e player só após escolha.
- [ ] Se Firebase/PG/provedor/modelo estiverem configurados, verificar conta real e três perguntas simples: 20% de150=30, diferença entre compreensão e interpretação com evidência textual, fluxo de energia versus reciclagem de matéria. Se não estiverem, registrar fronteira não verificada e estado real503; não pedir segredo no chat nem usar double para declarar IA real. Não invocar provider real só para provar SDK ou custo sem configuração fornecida.
- [ ] Documentar comandos, env/key/model, login só em memória, banco/quota UTC, recorde dispositivo, fontes/créditos, disponibilidade variável de vídeos e matriz Web/nativos. Atualizar textos fase futura e OpenAPI; nenhum deploy/CI remoto alegado. Conferir catálogo no bundle e igualdade com JSON da API.
- [ ] Fazer revisão independente final conforme modo escolhido e skills de revisão, corrigir achados com regressões relevantes. Marcar tarefas somente com evidência; commitar `test: validar experiência de estudo e documentar integração` e entregar URL local, captura representativa e limitações reais.

Referências: especificação e contratos do índice, [Dio](https://pub.dev/packages/dio), [Firebase REST](https://firebase.google.com/docs/reference/rest/auth), [OpenAI API](https://developers.openai.com/api/reference/overview).
