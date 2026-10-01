# Experiência de estudo — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Entregar hero educacional, aulas verificadas, quiz individual 8 bits e Steve com IA pelo backend no projeto Estuda Aí.

**Architecture:** Catálogo único versionado alimenta Flutter e NestJS. Quizzes e aulas funcionam sem sessão; Steve usa sessão Firebase verificada, contexto curricular do servidor e cotas persistidas. Quatro planos de entrega compartilham os contratos abaixo e podem ser validados separadamente.

**Tech Stack:** Flutter 3.47.5/Dart 3.13.4, Riverpod 3.4.3, GoRouter 18.0.2, Dio 5.11.1, NestJS 11.2.6, Prisma 6.19.3, PostgreSQL, Firebase REST/Admin e OpenAI Responses por fetch Node 24.

**Spec:** [Especificação aprovada](../specs/2026-09-30-experiencia-estudo-design.md).

## Global Constraints

- Projeto exclusivo: `C:\Users\glaub\OneDrive\Documentos\ChatGPT\EstudaAi`; não modificar AlmaPet.
- Preservar Flutter/NestJS, temas, preferências e shader; não instalar a stack React da referência.
- `porcentagem`, `interpretacao-texto`, `ecologia`; dez perguntas autorais por assunto, cinco por rodada e quatro alternativas por pergunta.
- Pontuação: 100 por acerto, mais 20 por acerto anterior consecutivo, bônus máximo 80; cinco acertos seguidos = 700. Sem cronômetro obrigatório.
- Modo Estudo livre, sem goalId fictício, ranking ou XP fabricado; melhor pontuação rotulada por dispositivo/assunto.
- Hero com fotografia licenciada, título Estuda Aí e CTA Escolher meu assunto; texto a 200%, larguras 360/768/1440, movimento reduzido.
- Seis videoIds exatos da especificação; iframe por ação, pelo menos 200 × 200 px; link externo sempre disponível e fallback externo nos apps nativos.
- Tokens/senha não persistem em preferências nem no Git; sessão do cliente só em memória. API exclusivamente HTTPS, exceto loopback de desenvolvimento.
- Login/cadastro/reset: 10/minuto/IP compartilhados; refresh: 60/minuto/IP separado. Rotas públicas não desativam proteção IP.
- Steve: mensagem 1–2.000 caracteres, até oito mensagens anteriores de até 2.000 caracteres e total de histórico até 12.000; somente user/assistant; corpo HTTP 64 KiB.
- Cotas iniciais: 10/dia/usuário, 1.000/dia globais, UTC, configuráveis no servidor; 3 mensagens/minuto/usuário; uma simultânea por usuário na instância única inicial.
- Provedor: store=false, saída máxima 800 tokens, timeout 30s; recebimento do cliente 45s. Chave e modelo somente no servidor; não repetir IA automaticamente.
- Cancelamento antes de invocar transporte libera reserva uma vez; após início ou resultado incerto mantém reserva. Nunca recuperar reservas automaticamente após reinício.
- Provedores reais apenas quando configurados. Doubles exclusivamente em testes; nenhuma conversa ou identidade simulada na aplicação.
- Não alegar builds nativos, CI remoto, reprodução externa ou deploy sem execução real. Não alterar configuração global do Windows ou serviço PostgreSQL existente.

## Review Focus

1. Catálogo corrompido ou deep link desconhecido deve produzir recuperação legível, sem selecionar silenciosamente assunto diferente — A1/A3.
2. Texto 200% e teclado em 360 px devem conservar perguntas, CTA e envio alcançáveis, inclusive títulos longos — A2/B2/D2.
3. Logout durante refresh e falha 429/503 de renovação não podem ressuscitar sessão nem desconectar uma sessão ainda válida — D1.
4. Troca de assunto durante resposta, ou ida e volta ao mesmo tópico, não pode entregar conteúdo atrasado de outra geração — D2.
5. Última vaga de quota, liberação duplicada, meia-noite UTC e timeout devem conservar contagem correta sob transações reais — C2/C3.

## Entregas e ordem

1. [A — Hero, catálogo e aulas](2026-09-30-hero-aulas.md): A1 fixa o catálogo/contexto; A2 entrega Home; A3 entrega navegação e aulas reais.
2. [B — Desafios 8 bits](2026-09-30-desafios-8bits.md): B1 entrega motor e recorde; B2 entrega jogo e navegação.
3. [C — Backend do Steve](2026-09-30-steve-backend.md): C1 entrega autenticação; C2 entrega quotas; C3 entrega endpoint de IA e operação.
4. [D — Conta, Steve e verificação](2026-09-30-steve-interface.md): D1 entrega sessão; D2 entrega chat; D3 verifica experiência completa e documenta resultados.

Execução nativa segue essa ordem. Se escolhidos agentes, A2/A3/B e C podem avançar após A1 estabilizar contratos, com arquivos de cada tarefa exclusivos; integração em `app.dart`, `shell.dart` e `app.ts` fica com o responsável pela tarefa proprietária, sem edições simultâneas.

## Contratos compartilhados

Catálogo canônico: `apps/client/assets/study/catalog.json`. Raiz: `schemaVersion: 1`, `catalogVersion: 1`, `topics`. Tópico: `id`, `title`, `subject`, `level`, `summary`, `notes`, `sources`, `lessons`, `questions`. Fonte: `{title,url}`. Aula: `{id,title,channel,description,level,videoId}`. Pergunta: `{id,prompt,options:string[4],correctIndex:0..3,explanation}`. IDs são únicos, textos não vazios; URL de fonte usa HTTPS, videoId corresponde a onze caracteres `[A-Za-z0-9_-]`.

Dart: `StudyTopic`, `StudyLesson`, `StudyQuestion`, `StudySource`, `LearningCatalog.fromJson(Map<String,dynamic>)`, `StudyTopic? LearningCatalog.find(String id)`, `Future<LearningCatalog> loadCatalog(AssetBundle bundle)`. `catalogProvider` é FutureProvider do loader, com override para widget tests; `LearningController.selectTopic(String topicId)` só aceita tópico existente e incrementa geração quando o assunto muda. O default válido é porcentagem. Rotas usam o tópico validado da URL; sincronização do contexto ocorre no ciclo de vida do adapter, sem escrever providers durante build.

TypeScript: `StudyCatalog` valida a mesma estrutura; `loadStudyCatalog(): StudyCatalog`, `StudyTopic | undefined StudyCatalog.find(id: string)`. JSON empacotado em `apps/api/dist/src/catalog/catalog.json`, lido por `__dirname`. Nada busca automaticamente documentos/vídeos externos durante execução.

Sessão HTTP: `AuthSessionResponse={idToken:string,refreshToken:string,expiresInSeconds:number}`. Cliente obtém identidade interna por `/v1/me`. DTOs públicos auth só recebem email/password ou refreshToken; reset recebe email. Resposta de reset: `{accepted:true}`; erro sempre seguro. O formato foi alinhado ao OpenAPI e ao cliente/servidor verificados, preservando a confirmação genérica da especificação.

Steve HTTP: entrada `SteveInput={topicId:string,message:string,history:ChatMessage[]}` com `ChatMessage={role:'user'|'assistant',text:string}`. Retorno `SteveReply={topicId,status:'completed'|'refused'|'incomplete',text,sources:StudySource[],quota:{remaining:number,resetAt:string},requestId:string}`. Estado incompleto/recusado tem apresentação própria. Fontes vêm do catálogo do servidor, sem executar links/HTML gerados pelo modelo.

## Verificação e preflight

- Antes de executar, ler os quatro planos e a especificação; inspecionar instruções e status Git. Aplicar using-git-worktrees quando isolamento for necessário, com repo EstudaAi explícito: a ferramenta da conversa não deve criar checkout da AlmaPet.
- SDK Flutter ignorado já instalado em `.tooling/flutter`; comandos a partir de `apps/client` usam `../../.tooling/flutter/bin/flutter.bat`. Windows: `$env:FLUTTER_WINDOWS='false'` para análise, testes e build Web, sem Developer Mode global.
- Não executar testes ou instalar dependências durante a fase de aprovação deste plano. Na execução, instalar somente web 1.1.1 e url_launcher 6.3.2 no cliente e fixar resolução no lock; API usa fetch nativo, sem nova dependência de provedor.
- Unitários/API: `npm test`; Flutter: `flutter test` e `flutter analyze`; release: `flutter build web --release --no-web-resources-cdn`.
- PostgreSQL 18.4 instalado tem binários locais; usar cluster temporário exclusivo em `.tooling/pg-integration/<run-id>` e porta própria, sem conectar ao serviço/bancos existentes. C2 define script e verificações de isolamento. CI terá PostgreSQL 17 próprio para integração; execução remota é evidência separada.
- Atualizar preview e testes Playwright existentes, preservar evidência em artifacts; nenhum servidor de teste de IA vira servidor de produção ou login de demonstração.

## Auto-revisão do plano

Cobertura: seções 1–2 da spec → contratos e A1; 3 → A2/A3; 4 → B1/B2; 5 → A1/A3; 6 → C1/D1; 7 → C2/C3/D2; 8–9 → D3; 10 → referências nos planos. Os cinco itens de Review Focus têm testes nomeados nas tarefas proprietárias. Valores e contratos têm uma definição comum; cada plano aponta para este índice. Não há decisões de produto pendentes.

Estado: implementação A1–D2 concluída e verificada; D3 em verificação final. Evidências e fronteiras não verificadas estão em [Validação](../../VALIDACAO.md).
