# Estuda Aí — Especificação da Fase 1: Fundação

Data: 29/09/2026. Estado: proposta para revisão, ainda não implementada.

## 1. Objetivo e entendimento

Construir uma base durável para uma plataforma de aprendizagem adaptativa comercial, em português, com metas de estudo independentes e distribuição futura em Android, iOS, Web e Windows.

O usuário já definiu produto, tecnologias, linguagem visual e ordem do MVP. Esta especificação detalha a primeira fase, sem substituir os [requisitos originais](../../REQUISITOS-ORIGINAIS.txt).

A separação da AlmaPet foi confirmada. O projeto reside em `C:\Users\glaub\OneDrive\Documentos\ChatGPT\EstudaAi`.

Sucesso da Fase 1 significa ter uma aplicação e uma API executáveis em ambiente de desenvolvimento, contratos claros, tema consistente, proteção inicial testada e documentação reproduzível. Não significa produto pronto para venda.

## 2. Alternativas consideradas

| Abordagem | Benefício | Custo ou problema | Decisão proposta |
| --- | --- | --- | --- |
| Flutter + NestJS modular + PostgreSQL/Prisma em projeto próprio | Segue as tecnologias pedidas, centraliza regras e permite entregas por fase | Exige preparar Flutter e infraestrutura local | Recomendada |
| Reutilizar a aplicação Next.js/Supabase da AlmaPet | Aproveita ferramentas já disponíveis | Mistura produtos, identidade e modelos; não entrega Flutter | Descartada |
| Separar desde o início serviços de IA, conteúdo, cobrança e planejamento | Permite operação independente de cada serviço | Introduz coordenação distribuída e infraestrutura antes de haver demanda medida | Adiar essa separação |

NestJS começa como monólito modular. Módulos podem evoluir separadamente sem depender de HTTP entre serviços internos. Processamento assíncrono será introduzido quando uma fase realmente precisar de trabalhos longos.

## 3. Escopo da fundação

### Incluído

- Monorepositório independente com configurações próprias e dependências fixadas por arquivos de lock.
- Cliente Flutter com Material 3, Riverpod, GoRouter e Dio.
- Modelos de transporte com Freezed/json_serializable quando houver contrato consumido.
- Design System com temas claro/escuro, componentes básicos e galeria interna de desenvolvimento.
- Estrutura responsiva com navegação mobile e sidebar desktop.
- Configuração validada de ambientes, tratamento de falhas e estados de carregamento/vazio/erro.
- API NestJS/TypeScript com versionamento, validação de entrada, proteção por padrão, limites de requisições e logs redigidos.
- Prisma/PostgreSQL com migração mínima de identidade e metas, necessária aos testes de autorização.
- Verificação de identidade por adaptador Firebase Admin no servidor; doubles apenas em testes.
- Contrato central de entitlement com FREE como estado padrão.
- Contrato de cache que inclui usuário e meta; implementação inicial de preferências locais sem armazenar credenciais em SQLite.
- Docker Compose para API/banco, health checks e exemplos de ambiente sem segredos.
- CI, testes focados e documentação de instalação, arquitetura, API e operação.

### Fora da primeira entrega executável

Cadastro e login completos na interface, CRUD de metas, cadastro de matérias, banco de questões, missão adaptativa, bibliotecas de conteúdo, revisões, dashboards calculados, simulados, chamadas de IA, cobranças, notificações remotas e publicação nas lojas.

Esses itens seguem no MVP e serão implementados nas fases correspondentes. A autenticação de ponta a ponta será concluída antes de liberar dados pessoais e metas na Fase 2.

Não criar controles aparentemente funcionais para recursos ausentes. A tela inicial usa estado vazio e navegação funcional para preferências; a galeria de componentes é de desenvolvimento e fica fora do build de produção.

## 4. Estrutura e fronteiras

```text
apps/client/lib/
  app/                  # Bootstrap, configuração, router e navegação
  core/                 # HTTP, falhas, sessão e contexto de meta
  design_system/        # Tokens, temas e componentes
  features/
    home/
    settings/
  data/local/           # Preferências e contrato do cache

apps/api/src/
  config/
  common/               # Filtros, pipes, identificadores de requisição
  auth/
  users/
  goals/                # Repositório e política de acesso; CRUD na Fase 2
  entitlements/
  health/
  database/

apps/api/prisma/
contracts/
infra/
docs/
.github/workflows/
```

No Flutter, widgets consomem controladores/providers; providers usam repositórios; repositórios ocultam rede e armazenamento. O domínio não depende de widgets ou Dio.

No NestJS, controllers validam transporte; serviços executam casos de uso; repositórios usam Prisma com escopo explícito. Um módulo não altera tabelas de outro módulo diretamente.

Fluxo previsto:

```text
Interface Flutter
  → estado vinculado a usuário + meta
  → repositório
  → cliente HTTP autenticado
  → guard de identidade
  → política de acesso à meta
  → caso de uso
  → PostgreSQL
```

Firebase identifica o usuário. PostgreSQL guarda a identidade interna e será a fonte de verdade de metas, estudo e benefícios.

## 5. Identidade e isolamento das metas

### Modelo mínimo

- `User`: ID interno imutável, identificador externo único, timestamps.
- `StudyGoal`: ID, usuário proprietário, nome, categoria, data de prova opcional, fuso horário e timestamps.
- Restrição única composta para `StudyGoal(userId, id)`, usada como destino de relações de propriedade.
- Índice de listagem por proprietário e ordenação estável.

Esse schema mínimo permite testar isolamento na fundação; não antecipa as APIs de cadastro de metas.

Nas fases seguintes, todo registro privado de estudo terá `userId` e `studyGoalId`. Filhos referenciarão o contexto composto do pai. Uma tentativa deverá referenciar uma questão da mesma meta; conferir apenas que ambos pertencem ao usuário é insuficiente.

### Regras obrigatórias

1. O backend deriva `userId` da identidade validada; não aceita propriedade enviada pelo cliente.
2. A meta é explícita na rota e no caso de uso. Não existe uma variável global de “meta atual” no servidor.
3. Recursos inacessíveis retornam 404 sem confirmar sua existência.
4. Todas as leituras, gravações, agregações e tarefas assíncronas carregam contexto autorizado.
5. A Home geral lista resumos identificados por meta; recomendações nunca combinam contextos.
6. Referências de conteúdo compartilhado, se introduzidas, não compartilham tentativas, domínio, agenda ou recomendações.
7. Remoção e exportação de dados precisam manter o vínculo com o proprietário.

Cache: chave composta por `userId/studyGoalId/recurso/parâmetros`. Ao trocar de meta, cancelar requisições e descartar respostas cujo contexto já não corresponde ao ativo. Ao sair da conta, limpar dados pessoais em memória e armazenamento local.

## 6. Autenticação e segurança

### Fundação

Definir `IdentityVerifier` como contrato. O adaptador de produção usa Firebase Admin para validar tokens; testes substituem o verificador por um double explicitamente injetado. Não haverá usuário fixo, autenticação simulada ou bypass selecionável em produção.

A API verifica validade e projeto do token e recusa tokens expirados/inválidos. Rotas privadas usam proteção global; exceções públicas são explícitas. Sem configuração obrigatória, a inicialização falha com mensagem segura.

`GET /v1/me` é o primeiro contrato protegido. O perfil interno é provisionado de forma idempotente a partir da identidade validada, sem confiar em IDs fornecidos na requisição.

A API não depende de acesso direto do aplicativo ao PostgreSQL. Credenciais administrativas e futuras chaves de IA permanecem no backend. Os arquivos de configuração pública do cliente não conterão segredos.

### Integração de login posterior

A Fase 2 precisa entregar login/logout/recuperação e renovação de sessão antes de expor metas. O Firebase permanece a preferência do pedido, mas o Windows não deve usar o plugin beta como base comercial.

A API REST oficial de autenticação é uma alternativa técnica a avaliar para o adaptador Windows, incluindo armazenamento seguro, renovação, revogação e encaminhamento pelo backend quando houver chave a proteger. Sua existência não constitui homologação da integração. [Referência REST](https://firebase.google.com/docs/reference/rest/auth).

Essa decisão de integração tem seu próprio aceite antes da Fase 2; não impede testar a fronteira de identidade na fundação. A documentação oficial do Firebase alerta sobre o uso de Windows em produção. [Matriz de plataformas](https://firebase.google.com/docs/flutter/setup).

### API

- DTOs com whitelist e rejeição de campos desconhecidos; limites de tamanho.
- CORS com origens explícitas; HTTPS em produção.
- Limites iniciais por IP e proteção adicional por usuário para operações autenticadas; limites específicos de IA entram na Fase 9.
- Proxy confiável configurado explicitamente; não confiar indiscriminadamente em cabeçalhos de IP.
- Logs com request ID, rota normalizada, status e duração. Excluir tokens, senhas, corpos privados e dados de saúde/estudo desnecessários.
- Erro padronizado com código, mensagem segura e request ID; stack trace apenas no ambiente de desenvolvimento.
- SQL parametrizado via Prisma; autorização repetida em operações de escrita.
- Rate limiting em memória apenas no desenvolvimento e na execução de instância única; múltiplas réplicas exigem armazenamento compartilhado antes do deploy.

## 7. Entitlement

Um único serviço responde se o usuário pode executar uma capacidade. O cliente pode usar o resultado para orientar a interface; a API decide o acesso real.

Na Fase 1:

- Usuários têm plano FREE.
- Capacidades Premium retornam indisponíveis.
- Nenhum parâmetro da requisição, configuração local ou botão pode conceder Premium.
- Ainda não há compra, cobrança ou integração de assinatura.

A Fase 10 adicionará fonte verificada de assinatura, expiração, cancelamento, reembolso, restauração e processamento idempotente de eventos. Não persistir “isPremium” como decisão confiável tomada pelo aplicativo.

## 8. Design System e experiência

### Tokens

Criar `AppColors`, `AppTypography`, `AppSpacing`, `AppRadius`, `AppElevation`, `AppShadows`, `AppIcons` e `AppAnimations`.

Cores hexadecimais ficam exclusivamente nas definições de tokens. `ThemeData` e extensões expõem papéis semânticos. A paleta inicial vem integralmente dos requisitos: azul principal, verde progresso, amarelo atenção, laranja desafios e vermelho erro.

Criar pares explícitos de fundo/texto para cada estado. A paleta base não implica que texto branco sobre amarelo ou laranja tenha contraste suficiente. A implementação deve medir esses pares e ajustar tons sem mudar seus significados.

Tema escuro terá tokens próprios para superfícies, bordas, texto e estados; não será uma inversão automática.

### Componentes da primeira fase

`PrimaryButton`, `SecondaryButton`, `AccentButton`, `StudyCard`, `EmptyState`, `ErrorState`, `LoadingState`, `Skeleton`, `Modal`, `BottomSheet`, `Snackbar`, `Chip`, `Badge`, `ProgressBar`, `CircularProgress`, `Tab` e `NavigationItem`.

Os demais cards definidos nos requisitos serão compostos a partir dessas primitivas na fase de sua funcionalidade: `GoalCard` na Fase 2, `QuestionCard` na Fase 3, `MissionCard` na Fase 4 etc. Essa ordem evita componentes sem contrato de dados ou interação definida.

### Navegação e acessibilidade

- Largura inferior a 600 px: navegação inferior e conteúdo em coluna.
- De 600 a 1023 px: navegação lateral compacta e adaptação progressiva.
- A partir de 1024 px: sidebar azul e área de conteúdo limitada para preservar leitura.
- Os pontos de corte são decisões iniciais a verificar com texto ampliado, e não detecção do tipo de dispositivo.
- Home abre no estado real disponível; preferências permitem alternar Sistema/Claro/Escuro.
- Ícones Material consistentes, rótulos claros, semântica de leitor de tela e foco visível.
- Estados de sucesso/atenção/erro usam texto e ícone além da cor.
- Alvos de toque de pelo menos 48 unidades lógicas nos controles principais.
- Verificar texto a 200%, navegação por teclado e ausência de corte horizontal.
- Animações discretas e desativáveis pela preferência de movimento reduzido.
- Nada de progresso, XP, sequência ou datas fictícias no fluxo real.

## 9. Contratos iniciais da API

| Método e rota | Acesso | Comportamento |
| --- | --- | --- |
| `GET /health/live` | Público | Informa que o processo está atendendo, sem detalhes internos |
| `GET /health/ready` | Público | 200 se dependências essenciais estão prontas; 503 em indisponibilidade |
| `GET /v1/me` | Autenticado | Identidade interna e plano FREE, sem token ou segredo |
| `GET /v1/me/entitlements` | Autenticado | Capacidades conhecidas e disponibilidade efetiva |

Documentar respostas e erros em OpenAPI. Não criar endpoints para funcionalidades posteriores que retornem resultados simulados.

Rotas futuras de estudo seguirão `/v1/goals/:goalId/...`, com paginação limitada, ordenação estável e validação de contexto no servidor.

## 10. Dados locais, rede e falhas

Dio terá timeout, cancelamento e tratamento único de falhas. Retry automático somente para operações idempotentes, com limite. Renovação de sessão não pode gerar loops ou múltiplas renovações concorrentes.

Na fundação, persistir apenas preferências. Drift será adotado para o cache de estudo quando os primeiros recursos da Fase 2 tiverem contrato de sincronização definido. Tokens não serão armazenados no banco de estudo.

Sem conexão, mostrar estado explícito e ação de tentar novamente. Quando cache de dados existir, informar atualização pendente. Não afirmar suporte offline completo até implementar sincronização, conflitos e fila de escritas.

Datas de prova usam data civil; eventos usam timestamp UTC. Planejamento diário considera o fuso da meta/usuário. “Hoje” não será determinado apenas pelo relógio do servidor.

## 11. Infraestrutura e distribuição

- Ambientes de desenvolvimento, teste e produção separados.
- Docker Compose com PostgreSQL e API, volume persistente e health checks.
- Migrações versionadas e execução explícita em deploy; evitar schema push destrutivo em produção.
- `.env.example` documentado, validação de configuração e exclusão de segredos do Git.
- Dependências e SDKs com versões registradas após resolver e verificar compatibilidade.
- Pipeline executa geração de código, formatação, análise estática, testes e builds compatíveis com o executor.
- Build Web inicial; Windows validado em executor Windows; Android em ambiente com SDK Android; iOS em macOS/Xcode.
- Falha de SDK ou credencial deve ser registrada como verificação pendente, não mascarada com sucesso.
- Identificadores finais, certificados, ícones de distribuição e contas das lojas pertencem à preparação de release da Fase 12.

A máquina inspecionada tem Node/npm/Git. Flutter/Dart/Docker ainda precisam ser localizados ou preparados. Não há build Flutter verificado neste momento.

## 12. Critérios de aceite e evidência

| Área | Evidência exigida |
| --- | --- |
| Reprodutibilidade | Instalação a partir dos arquivos de lock e instruções de bootstrap |
| Cliente | Análise estática, widget tests e build Web concluídos |
| Design System | Galeria com claro/escuro, estados de interação e pares de contraste medidos |
| Responsividade | Verificação em 360 px e 1440 px, além de texto ampliado |
| Acessibilidade | Leitura semântica, foco/teclado, rótulos e movimento reduzido |
| API | Build TypeScript e testes HTTP reais do aplicativo Nest |
| Autenticação | Sem token, token inválido, expirado e projeto incorreto recusados |
| Metas | Dois usuários e duas metas do mesmo usuário; leituras e escritas cruzadas recusadas |
| Banco | Migração aplicada em banco de teste; restrições compostas verificadas |
| Entitlement | FREE por padrão e impossibilidade de autoconcessão de Premium |
| Falhas | Banco indisponível sinaliza 503; erros não revelam segredos |
| Isolamento de UI | Resposta antiga descartada após mudança do contexto |
| CI | Workflow executável; só declarar CI verde quando houver execução real |
| Documentação | Comandos conferidos e estado de validação registrado por plataforma |

Doubles de autenticação só comprovam comportamento do consumidor; verificação Firebase real precisa de teste com emulador ou ambiente configurado e será identificada separadamente.

Para cada implementação significativa: implementar → testar → revisar → refatorar quando necessário → testar o trecho alterado. Não repetir toda a suíte após uma revisão sem alteração.

## 13. Continuidade do produto

| Fase | Resultado principal |
| --- | --- |
| 1 — Fundação | Base descrita neste documento |
| 2 — Metas | Login completo, criação/edição/seleção de metas, matérias e contexto persistido |
| 3 — Questões | Respostas, explicações, tentativas e caderno de erros |
| 4 — Missão do Dia | DailyStudyPlanner determinístico, contextual e testado |
| 5 — Multimodal | Vídeos, mapas mentais, flashcards e materiais licenciados |
| 6 — Revisões | Agendamento e retomada por desempenho |
| 7 — Dashboard | Métricas calculadas, domínio e fraquezas por meta |
| 8 — Simulados | Provas, tempo, correção e análise |
| 9 — IA | Geração e explicações via backend, limites e contexto autorizado |
| 10 — Premium | Assinaturas verificadas e entitlement central |
| 11 — Qualidade | Auditoria integrada de segurança, UX, acessibilidade e desempenho |
| 12 — Publicação | Builds assinados, documentação de privacidade e submissões |

DailyStudyPlanner será uma função de domínio testável, com relógio injetável, desempate estável, limite de minutos e proibição de cruzar metas. Dificuldade, urgência da prova, revisões vencidas, desempenho e disponibilidade de conteúdo comporão a política na Fase 4.

As entidades restantes serão introduzidas com a funcionalidade correspondente. A fundação não deve criar duas dezenas de tabelas vazias apenas para aparentar cobertura do produto.

## 14. Revisão desta proposta

Verificações de consistência realizadas:

- A aplicação de estudos e a loja têm diretórios e dependências próprios.
- O recorte da Fase 1 é explícito e distingue autenticação de API de login de ponta a ponta.
- A seleção de meta não é tratada como autorização.
- A fundação não promete suporte Firebase de produção no Windows.
- Componentes dependentes de funcionalidades futuras têm fase de entrega.
- Nenhum teste ou build do Estuda Aí é apresentado como já executado.
- Identificadores comerciais e publicação não são inventados.
- O roadmap mantém as doze fases fornecidas.

A próxima entrega de planejamento transforma os critérios acima em tarefas implementáveis, após a revisão desta especificação.
