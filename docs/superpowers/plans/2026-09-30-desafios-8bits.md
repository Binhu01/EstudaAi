# Desafios individuais 8 bits — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Entregar rodadas de cinco questões por assunto, com feedback didático e pontuação local real.

**Architecture:** Motor Dart puro administra seleção, pontuação e estado da rodada. Riverpod conecta motor e recorde local à tela Flutter; catálogo e contexto são os de A1.

**Tech Stack:** Flutter/Riverpod/SharedPreferences existentes; fonte Press Start 2P empacotada sob OFL, sem serviço remoto de fontes.

**Spec:** [Especificação](../specs/2026-09-30-experiencia-estudo-design.md), [contratos globais](2026-09-30-experiencia-estudo.md).

## Global Constraints

Todas as restrições do índice. Cinco perguntas sem repetição, quatro opções, uma escolha aceita; 100 + 20×sequência anterior, bônus máximo 80; erro zera sequência; total perfeito 700. Sem timer/velocidade. Recorde por tópico e catalogVersion no dispositivo; não sincronizar conta nem criar ranking. Texto principal legível, pixel só em títulos/números; movimento reduzido e texto 200%.

## Review Focus

Resposta repetida não pontua; erro corta bônus; recorde menor chegando depois não sobrescreve maior. Troca de tópico abandona rodada antiga. Alternativa longa e teclado em 360 px continuam utilizáveis.

### Task 1: B1 — Motor da rodada e melhor pontuação

**Files:** Criar `apps/client/lib/features/quiz/quiz_engine.dart`, `quiz_controller.dart`, `best_score_repository.dart`; testar `apps/client/test/quiz_engine_test.dart`, `best_score_test.dart`.

**Interfaces:** Consome List<StudyQuestion>, catalogVersion e preferencesProvider. Produz `QuizEngine(questions:List<StudyQuestion>,random:Random)`, `void start()`, `bool answer(int optionIndex)`, `void next()`, `QuizState get state`. Produz também `enum QuizPhase { answering, feedback, completed }`. QuizState: phase:QuizPhase, roundQuestions, questionIndex, selectedIndex, score, streak, correctCount; índices e opção nulos somente quando aplicável. Repositório: `int read(String topicId,int catalogVersion)`, `Future<void> saveIfHigher(String topicId,int catalogVersion,int score)`. quizProvider é family por topicId e controla dispose.

- [ ] Escrever testes carregando catálogo via loadCatalog: rodada tem cinco IDs únicos; cinco respostas corretas rendem 700, correctCount=5; segunda chamada answer na mesma questão retorna false e não muda score; erro zera sequência; next antes de responder não avança; índice fora 0..3 é rejeitado. Exemplo: `expect(engine.state.score, 700); expect(engine.state.phase, QuizPhase.completed);`.
- [ ] Testar recordes: 300 depois de 700 mantém 700; tópicos/versões separados; valor local corrompido não quebra tela; duas gravações concorrentes 700/300 conservam 700. Rodar novos testes e observar falhas de classes ainda ausentes.
- [ ] Implementar motor puro com shuffle injetável de dez perguntas e take(5); start zera tudo, answer trava no primeiro toque e calcula bônus antes de incrementar streak. next avança só após feedback e termina após quinta explicação.
- [ ] Implementar controller e serialização de gravações máximas em SharedPreferences. Chave inequívoca inclui tópico/versão; após dispose, resultado de persistência não atualiza estado. Carregar recorde real, sem XP. Falha de gravação não perde resultado da rodada e mostra aviso seguro de recorde não salvo.
- [ ] Rodar `flutter test test/quiz_engine_test.dart test/best_score_test.dart`; expected todos passam, inclusive concorrência; commit `feat: criar motor de desafios por assunto`.

### Task 2: B2 — Tela do jogo 8 bits e navegação

**Files:** Criar `apps/client/lib/features/quiz/quiz_screen.dart`, `answer_tile.dart`, `quiz_result.dart`, `design_system/components/pixel_avatar.dart`, `assets/fonts/PressStart2P-Regular.ttf`, `assets/fonts/OFL.txt`; modificar `pubspec.yaml`, `design_system/tokens.dart`, `app/app.dart`, `app/shell.dart`, `features/home/home_screen.dart`, `docs/MIDIA.md`; testar `apps/client/test/quiz_screen_test.dart`, atualizar `design_system_test.dart`.

**Interfaces:** Consome quizProvider/StudyTopic/TopicScope. Produz `QuizScreen(topicId:String)`, `PixelAvatar(size:double)`, rota `/desafios/:topicId` e comandos Começar desafio/Repetir/Assistir aula. PixelAvatar é desenho original em grade via CustomPainter; não depende de bitmap ou marca Kahoot.

- [ ] Escrever widget tests: início→resposta→explicação→próxima→resultado para cada tópico; botões das respostas ficam desabilitados após seleção; ícone/texto indicam correto/erro; Repetir zera resultado. Sair para ecologia durante rodada de porcentagem não mantém pergunta/pontos antigos. Layout em 360 px e escala 2 sem overflow, com alternativa longa; foco/Enter escolhem uma vez.
- [ ] Rodar `flutter test test/quiz_screen_test.dart` e observar falhas anteriores à tela.
- [ ] Empacotar fonte licenciada [Press Start 2P](https://github.com/google/fonts/tree/main/ofl/pressstart2p) com OFL; usá-la apenas em títulos curtos/pontos. Criar estilo pixel com bordas retas/em degraus e avatar original, mantendo componentes e cores contrastantes do design system. Confete breve respeita preferência de movimento; sem efeito piscante.
- [ ] Implementar tela, feedback e resultado: acertos/5, pontos/700, melhor neste dispositivo/assunto. Escolha deve funcionar por teclado e toque ≥48px; quatro alternativas em grade desktop e coluna mobile, sem tamanho fixo que corte texto. Ações levam à aula do mesmo tópico ou recomeçam.
- [ ] Integrar rota e Desafios na navegação usando seleção atual, atualizar labels/descritivos da Home. Rodar testes do quiz e contraste, `flutter analyze` e build Web; commit `feat: entregar desafios com visual 8 bits`.
