# Hero e videoaulas — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Entregar a Home educacional e aulas incorporadas, com catálogo único e seleção por assunto.

**Architecture:** Flutter carrega o catálogo como asset e mantém contexto de Estudo livre. Uma fotografia local otimizada recebe texto/controles Flutter; o player Web é isolado por imports condicionais e a mídia nativa usa URL externa.

**Tech Stack:** Flutter/Riverpod/GoRouter/Dio existentes; web 1.1.1, url_launcher 6.3.2; script Node 24 para empacotamento do catálogo.

**Spec:** [Especificação](../specs/2026-09-30-experiencia-estudo-design.md), [contratos e restrições globais](2026-09-30-experiencia-estudo.md).

## Global Constraints

Aplicam-se todas as restrições do índice. Catálogo: três IDs exatos, dez questões/assunto, duas aulas/assunto, schemaVersion=1/catalogVersion=1. Hero: Estuda Aí, fotografia Zoshua Colah, CTA Escolher meu assunto, preservar shader e movimento reduzido. Web iframe sem autoplay, mínimo 200 × 200; apps nativos com link externo. Layout a 360/768/1440 e texto 200%.

## Review Focus

Catálogo inválido deve falhar com estado de recuperação; tópico de URL desconhecido não ativa outro contexto. Fotografia ausente não remove CTA. Mudança de aula remove iframe anterior; título longo e 200% não encobrem navegação.

### Task 1: A1 — Catálogo comum e contexto validado

**Files:** Criar `apps/client/assets/study/catalog.json`, `apps/client/lib/features/learning/study_catalog.dart`, `learning_controller.dart`, `topic_scope.dart`, `tools/package-catalog.mjs`, `apps/api/src/catalog/study-catalog.ts`; modificar `apps/client/pubspec.yaml`, `apps/api/package.json`, `.dockerignore`, `apps/api/Dockerfile`; testar `apps/client/test/catalog_test.dart`, `learning_context_test.dart`, `apps/api/test/catalog.test.ts`.

**Interfaces:** Consome os JSON/types do índice. Produz os loaders Dart/TS, `catalogProvider`, `LearningController.selectTopic(String)`, `learningProvider`, `TopicScope(topicId:String,child:Widget)` e catálogo empacotado baseado em __dirname. `LearningState` expõe `topicId:String` e `generation:int`; não usa goalId.

- [x] Escrever testes: IDs exatamente os três aprovados; 10 perguntas/4 opções/1 correctIndex válido por assunto; seis videoIds exatos; IDs/opções duplicados, fonte HTTP e JSON sem fields obrigatórios falham. Exemplo Dart: `expect(catalog.find('ecologia')!.questions.length, 10); expect(() => LearningCatalog.fromJson({'topics': []}), throwsFormatException);`.
- [x] Rodar os novos testes para observar falha pela implementação ausente: `flutter test test/catalog_test.dart test/learning_context_test.dart` e `npm test -w apps/api`.
- [x] Criar catálogo autoral e classes immutable com parsing estrito; validar fontes HTTPS e IDs. Implementar loaders e contexto que rejeita IDs desconhecidos, aumenta geração na troca e não inventa meta. TopicScope atualiza contexto em init/didUpdate após frame, com mounted guard; sua tela usa imediatamente o tópico da URL validada.
- [x] Implementar `tools/package-catalog.mjs`: valida catálogo e copia bytes para `dist/src/catalog/catalog.json`; configurar build API após tsc e Docker para incluir somente source/script adicionais. Não manter cópia editável nem importar JSON fora do rootDir TS. Incluir asset Flutter; instalar dependências de mídia aprovadas nessa tarefa quando necessárias aos próximos imports, atualizar lock sem scripts npm extras.
- [x] Executar os testes e igualdade dos bytes fonte/empacotado. Teste de contexto: trocar porcentagem→ecologia aumenta geração uma vez; seleção inválida mantém estado; loader não depende do cwd do processo.
- [x] Revisar os 30 enunciados e explicações à luz das três fontes educacionais da spec; registrar curadoria e commit `feat: adicionar catálogo e contexto de estudo livre`.

### Task 2: A2 — Hero educacional e Home utilizável

**Files:** Criar `apps/client/assets/images/study-hero.webp`, `apps/client/lib/features/home/education_hero.dart`, `word_reveal.dart`, `topic_picker.dart`, `docs/MIDIA.md`; modificar `home_screen.dart`, `design_system/tokens.dart`, `pubspec.yaml`; testar `apps/client/test/hero_test.dart`, modificar `app_test.dart`.

**Interfaces:** Consome catalogProvider/learningProvider. Produz `EducationHero(onChooseTopic:VoidCallback,animate:bool,visible:bool)`, `TopicPicker(topics:List<StudyTopic>,selectedId:String,onSelected:ValueChanged<String>)`. O picker atualiza contexto; a ação Aprender será ligada à rota A3.

- [x] Escrever widget tests do CTA rolando até seleção, escolha atual indicada, fallback de imagem com CTA preservado e 360 px/textScaler=2 sem overflow. Asserções: `expect(find.text('Escolher meu assunto'), findsOneWidget); expect(tester.takeException(), isNull);`. Movimento reduzido impede animação de palavras; desmontagem não deixa timers/tickers ativos.
- [x] Rodar `flutter test test/hero_test.dart test/app_test.dart` e observar falhas do novo comportamento antes de substituir a Home.
- [x] Obter fotografia licenciada da página específica da spec, inspecionar imagem, salvar versão otimizada com até 1920px e alvo até 500KiB, registrar crédito/URL/licença em MIDIA. Imagem é asset do produto; não baixar vídeos. Declarar asset e verificar bundle. Se a origem impedir obtenção, reportar limitação e corrigir seleção de mídia com usuário antes de afirmar aceitação do hero.
- [x] Implementar hero imersivo com fotografia, scrim legível, marca grande inferior e shader como detalhe. Copiar literalmente os três textos de apoio/descrição/CTA da spec. WordReveal usa AnimationController curto e Semantics de texto integral; respeita animate/reducedMotion/visibilidade/lifecycle. Sem fontSize calculado diretamente pelo viewport.
- [x] Substituir Home vazia por hero e seleção funcional; manter Preferências e marca. Não exibir estatísticas ou botões para rotas ainda não entregues. Rodar testes, `flutter analyze`; verificar contraste e reflow com temas e texto 200%.
- [x] Commit `feat: adaptar hero educacional ao Flutter` com apenas os arquivos da tarefa.

### Task 3: A3 — Aulas, player Web e rotas reais

**Files:** Criar `apps/client/lib/features/learning/learning_screen.dart`, `topic_not_found.dart`, `lesson_player.dart`, `lesson_player_web.dart`, `lesson_player_native.dart`, `external_links.dart`; modificar `app/app.dart`, `app/shell.dart`, `features/home/home_screen.dart`; testar `apps/client/test/learning_screen_test.dart`, `media_test.dart`.

**Interfaces:** Consome StudyTopic/StudyLesson/TopicScope. Produz `LearningScreen(topicId:String)`, `LessonPlayer(lesson:StudyLesson)`, `Future<bool> openStudyLink(Uri url)` e rotas `/aprender/:topicId`. Import condicional usa `dart.library.js_interop` para a implementação Web; plataforma nativa não importa package:web.

- [x] Escrever testes: três tópicos mostram duas aulas corretas; deeplink inválido exibe Assunto não encontrado e retorno; escolher aula muda título/videoId; falha ao abrir link exibe recuperação. Antes de selecionar aula, não existe player. Títulos longos/reflow a 200% preservam botão externo.
- [x] Rodar `flutter test test/learning_screen_test.dart test/media_test.dart` e confirmar falhas anteriores à implementação.
- [x] Implementar tela e rotas com IDs validados e seleção por ação. Quadro com altura mínima 200 e proporção 16:9 quando couber; HtmlElementView.fromTagName cria iframe `https://www.youtube.com/embed/<id>?autoplay=0&rel=0`, title e fullscreen, sem JavaScript bridge desnecessária. Chave do player muda com aula; remover elemento anterior ao trocar/desmontar. Não detectar disponibilidade pelo evento load como se fosse reprodução bem-sucedida.
- [x] Implementar abertura HTTPS externa por url_launcher, iniciada diretamente no gesto do usuário e com mensagem em retorno false/erro; não usar canLaunchUrl para bloquear links válidos. Native mostra ação Abrir no YouTube; Web conserva essa ação junto do iframe. Fontes do catálogo também passam pelo validador de HTTPS conhecido.
- [x] Ligar Aprender e CTA ao tópico escolhido; ajustar seleção da shell para prefixos sem marcar Preferências em qualquer rota nova. Botões Desafios/Steve entram somente em B2/D2. Rodar testes/análise e build Web, comprovando imports condicionais; navegador deve conservar watch link mesmo quando iframe externo falha.
- [x] Commit `feat: incorporar videoaulas por assunto` e registrar se reprodução foi observada ou só incorporação/links.

Referências: [Flutter assets](https://docs.flutter.dev/ui/assets/assets-and-images), [HtmlElementView](https://docs.flutter.dev/platform-integration/web/web-content-in-flutter), [YouTube](https://developers.google.com/youtube/player_parameters), [web](https://pub.dev/packages/web), [url_launcher](https://pub.dev/packages/url_launcher).
