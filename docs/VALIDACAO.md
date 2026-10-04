# Evidências da experiência de estudo

## Fechamento e preparo de publicação — 04/10/2026

A versão atual acrescenta correção dos destinos pós-login, proxies explicitamente confiáveis, backup privado e atualização dos verificadores para a sidebar e os dois elementos animados do hero.

| Verificação desta execução | Resultado |
| --- | --- |
| API | 96/96; build TypeScript e ambos os catálogos incluídos |
| Flutter | 130/130; análise limpa, formatação e build Web release concluídos |
| Ferramentas | 54/54 com regressão PostgreSQL de backup ativada; sintaxe dos sete scripts aprovada |
| Conteúdo | 126 módulos, 756 questões, seis propostas; `errors:[]` |
| PostgreSQL isolado | 1/1 integração com concorrência/quota/histórico; cluster de estudo preservado |
| Backup real | 7 tabelas e1 sequência restauradas em banco UUID; dados/schema conferidos e original preservado |
| Navegador integrado | Layout do hero em 1440×900 e 360×800, navegação móvel por teclado, menu→painel→conta; proteção sem sessão e console sem erros/avisos |
| Android | Permissão INTERNET incluída no manifesto principal; sem build/homologação nativa |

Os quatro destinos pós-login (aulas/Steve × Estudo livre/Concursos) passaram em testes de widgets, incluindo texto ampliado. Os testes HTTP do proxy comprovam que headers forjados não mudam o IP sem um proxy configurado e que clientes encaminhados por um proxy permitido têm limites separados.

A prévia e a API locais foram retomadas; `/health/ready` respondeu200 com banco identificado e dados preservados. A sessão autenticada no navegador aguarda entrada do usuário. A OpenAI foi adiada novamente por sua escolha; não houve chamada real ao Steve. Domínio, hospedagem e orçamento ainda não foram informados. Testes de tela estreita não substituem um aparelho real.

O [ensaio de backup](BACKUP.md) verificou conteúdo, colunas, índices e constraints, incluindo uma regressão CHECK que preserva expressões equivalentes e detecta mudanças reais. Os arquivos e bancos de ensaio ficaram privados/preservados.

O job remoto de publicação constrói as imagens runtime/migration, verifica ambos os catálogos e valida o Caddyfile. Esses checks e os quatro percursos de navegador serão executados após o envio; sua preparação local não comprova publicação nem HTTPS público. Captura atual de Concursos salva no diretório de visualizações da conversa.

## Aprendizagem integrada — 04/10/2026

Implementação no worktree de Concursos, branch `codex/visual-dala-playdate`. O visual, a sidebar e a animação do hero existentes foram preservados. Esta seção registra a entrega anterior ao fechamento de publicação documentado acima.

| Verificação local | Resultado |
| --- | --- |
| API | 92/92 testes, incluindo cobertura, sequência, limite temporal e contexto completo do Steve; build e catálogo incluídos |
| Flutter | 126/126 testes e análise sem problemas; nove testes dirigidos do catálogo, quiz e revisão também passaram durante os ajustes finais de texto e contraste |
| Web release | Compilado com API local, sem recursos CDN e com `FLUTTER_WINDOWS=false` somente no processo |
| Serviços reais | Banco pronto, login Firebase, identidade verificada, progresso e caderno em Estudo livre e Banco do Brasil; acesso privado sem sessão devolve 401 |
| Navegador real | Leitura e controles em 1440×900 e 360×800; módulo anterior dentro da disciplina e próximo desativado no último módulo; rodada pública com acertos, erro, explicação e resumo |

O painel e a rodada de revisão autenticados foram verificados em testes de widgets e HTTP/SQL; não se afirma uma sessão autenticada no navegador nesta entrega. O percurso público foi conferido no navegador integrado. A checagem de console não encontrou avisos ou erros internos. Capturas da leitura desktop/mobile e do resumo estão salvas no diretório de visualizações da conversa.

O banco local foi retomado com os dados preservados. Firebase e histórico foram exercitados com a conta dedicada de validação e configuração privada, sem expor credenciais. A OpenAI permanece pendente por escolha do usuário: não houve chamada ao provedor nem comprovação de resposta real do Steve. As instruções e o conteúdo contextual do tutor passaram nos testes locais. Não houve migração, build nativo, publicação, push ou criação de PR nesta etapa.

Os comportamentos e limites estão descritos em [Aprendizagem](APRENDIZAGEM.md).

## Rotina diária — 02/10/2026

Branch `codex/rotina-estudo`, baseada em `ed17772`, no worktree isolado do EstudaAi. AlmaPet e a branch do PR#1 foram preservados. Implementação direta, testes por etapa e uma revisão independente do conjunto prevista ao final.

| Verificação local | Resultado |
| --- | --- |
| API, geração Prisma e OpenAPI | 84/84 testes; contrato gerado |
| Ferramentas de conteúdo/configuração | 29/29; configuração ausente não fabrica prontidão ou chama provedores |
| PostgreSQL18 real | 1/1 ciclo dedicado de quota/histórico; duas conexões, UUID concorrente, propriedade, rollback, painel/paginação |
| Operação PostgreSQL persistente | Init idempotente, sentinela preservada após reinício, senha preservada, portas/pastas/cluster alheio recusados, `.env` preservado |
| Cliente Flutter | 101/101; três viewports, texto200%, revisão correta pelo teclado, paginação/contexto e confirmação perdida |
| Geração/formatação/análise | Modelos versionados sem diff;113 arquivos formatados, zero mudanças; análise sem problemas |
| Build Web release | Concluído sem recursos CDN; `FLUTTER_WINDOWS=false` somente no processo |
| Visual/estudo livre/Concursos | Temas/shader/teclado nos três tamanhos;9 percursos/45 respostas livres e27/135 de Concursos, zero erro interno |
| Nova rotina no navegador | 30 percursos em360×800,768×1024,1440×1000; zero erro interno; login gate, alvo, conta/área, erro→revisão e retry |
| Conteúdo autoral | 126 módulos/756 questões/seis propostas; `errors:[]`; catálogos sem diff desde a base |

Transporte de conta/histórico do `test:routine` é controlado somente no teste. Confirmação perdida grava a resposta na fixture e devolve503; retry usa o mesmo UUID/corpo, sem duplicar o evento. As demais suítes Web continuam verificando a fronteira local de login indisponível. Isso não comprova Firebase/OpenAI reais. As projeções SQL foram verificadas em GREEN no banco real; a falha RED isolada dessas projeções não foi executada antes da implementação, embora a ausência das rotas tenha sido observada em RED.

O cluster de estudo `.tooling/pg-local` foi inicializado em127.0.0.1:55433 com SCRAM e arquivos privados com ACL restrita. As três migrações foram aplicadas; diagnóstico de schema confirmou `verified` antes/depois do reinício. O cluster ficou parado, com dados preservados. Um teste separado usa55434; integração usa55432. Nenhum cluster/serviço externo foi alterado. A migração foi executada carregando `.env` diretamente no processo da CLI Prisma; `--env-file` com `--run` não encaminhou DATABASE_URL neste ambiente, e o guia foi corrigido.

`verify-live-study.mjs` encerrou como **pending**, sem criação de conta ou chamada externa. Firebase e OpenAI continuam ausentes. Configuração plausível é `configured`; somente execução real comprova login/IA. O [guia](ROTINA-CONFIGURACAO.md) e o roteiro separado estão disponíveis. Recuperação de senha exige comando explícito do operador.

Relatórios/capturas: `artifacts/rotina-estudo`, mais os relatórios anteriores de Web/estudo/Concursos. CI acrescenta diagnóstico e nova rotina com fixtures públicas; esta fase não foi executada remotamente. A execução anterior do PR#1 e seus resultados continuam registrados abaixo. Docker, builds nativos, leitura de tela real, carga comercial e deploy permanecem fora da evidência desta etapa.

## Revisão e fechamento da rotina — 03/10/2026

A [revisão independente](ROTINA-REVISAO.md) de `ed17772..b2ccb83` encontrou um problema importante no calendário do cliente e um ajuste menor no enum OpenAPI das identidades históricas. O autor confirmou ambos; corrigiu o calendário em uma passagem e adiou o ajuste documental. Nenhum problema crítico foi encontrado. A tentativa anterior de revisão foi interrompida por limite de uso antes de produzir parecer; não houve segunda revisão após a correção.

O teste Web recebeu sete datas civis consecutivas de03 a09/03/2026, com dispositivo em `America/New_York` e meta em São Paulo. No build anterior, o painel rejeitou o payload após o salto de horário de verão de23 horas. O cliente passou a validar datas/continuidade em UTC, sem modificar o dia determinado pelo servidor. O mesmo percurso passou após novo build:30 fluxos/3 tamanhos/zero erro interno; os dois outros tamanhos preservam São Paulo e a semana que cruza setembro/outubro. O relatório guarda fuso/datas para reprodução. API84/84, ferramentas29/29, Flutter101/101, format113/zero mudanças e análise limpa foram repetidos na árvore corrigida. Checks PostgreSQL/conteúdo e demais percursos Web da Task8 não foram repetidos porque a correção não os altera.

Login/Steve reais permanecem pendentes. As decisões, seus custos e o ajuste menor adiado estão na revisão. A integração escolhida pelo usuário é enviar a branch e criar PR separado sobre `codex/concursos-bb2026`; o PR#1 não é alterado.

## CI do Pull Request #1 — 02/10/2026

A primeira execução remota, no commit `79d112e`, comprovou geração, testes e build da API, o verificador integral do catálogo e a integração com PostgreSQL 17.11. O job Flutter comprovou geração, lockfile, formatação, análise, testes, build Web e verificação visual nos três tamanhos.

O percurso de Estudo livre falhou ao localizar a mensagem de indisponibilidade do login: o Flutter disponibilizou o mesmo texto no conteúdo e no anúncio para leitores de tela. O seletor global encontrou dois elementos. A correção limita essa verificação à árvore semântica do aplicativo, exige uma única mensagem e preserva o anúncio acessível. O percurso de Concursos não chegou a executar nessa primeira tentativa.

As verificações da nova execução e do commit atual podem ser consultadas no [Pull Request #1](https://github.com/Binhu01/EstudaAi/pull/1). Os registros locais abaixo descrevem o fechamento anterior ao envio ao GitHub; seus limites de CI e PostgreSQL não substituem esta evidência remota posterior. Login/IA reais, builds nativos e deploy continuam sem validação ao vivo.

A execução posterior [37073422237](https://github.com/Binhu01/EstudaAi/actions/runs/37073422237) concluiu com sucesso os dois jobs, incluindo81 testes Flutter,66 API,22 de ferramentas, uma integração PostgreSQL e todos os percursos Web existentes. Essa evidência pertence à versão anterior; não valida automaticamente as mudanças da rotina.

## Concursos — 02/10/2026

Branch `codex/concursos-bb2026`, baseada em `b9154fc`, no EstudaAi separado da AlmaPet. Catálogo integral: 126 módulos, 756 questões, seis propostas de Redação e 18 vídeos distintos. Revisão editorial do autor, vínculos históricos e 24 oráculos numéricos conferidos; comparação com oito extrações privadas sem coincidências de 12 ou mais palavras. Não se apresenta essa comparação como certificação universal.

Geração Dart executada; conteúdo dos modelos versionados permaneceu igual. Formatação: 96 arquivos, zero mudanças no check; análise sem problemas. **81 testes Flutter, 66 testes API e 22 testes de ferramentas passaram**, além do verificador integral com `errors:[]`. O OpenAPI foi gerado com 129 identidades, e as cópias API/Web preservam os bytes do canônico. Build Web release sem recursos CDN concluído. `FLUTTER_WINDOWS=false` apenas no processo, sem mudar configurações globais.

Navegador Chromium em 1440×1000, 360×800 e 768×1024: **27 percursos de Concursos e 135 respostas**, nove percursos livres e 45 respostas; zero erros internos. Inclui todas as disciplinas, material→aulas→quiz→Steve→conta, cinco questões distintas/700 pontos, contexto, recuperação de relação inválida e alias livre recusado. Temas claro/escuro, movimento reduzido, pausa/persistência do shader e teclado foram verificados nos três tamanhos. Reflow a 200%, fórmula/tabela, passagens longas, feedback e ações têm testes Flutter; não se confunde essa evidência com zoom do navegador.

Relatórios/capturas locais ignorados pelo Git: `artifacts/concursos-bb2026/verification`, `artifacts/web-verification.json` e `artifacts/study-verification.json`. Scripts `test:visual`, `test:study` e `test:contests` reproduzem a verificação com `PREVIEW_URL`. A prévia da branch usa `http://127.0.0.1:4174/#/concursos`. Fórmula F07 e tabela I05 foram inspecionadas nas capturas dos três tamanhos; em 360 px também foi conferida a última coluna após rolagem horizontal. A ausência do rótulo acessível dos textos selecionáveis foi reproduzida e corrigida. A comparação final percorreu 96.763 tokens autorais e oito extrações privadas, sem sequências iguais de 12 ou mais palavras. Iframes/link foram conferidos; não foi observada reprodução dos 18 vídeos novos. Erros de terceiros e indisponibilidade esperada da API local são separados dos erros internos.

Firebase/OpenAI reais seguem sem configuração demonstrada. Testes de transporte controlado não equivalem a login ou respostas reais. SQL e quotas não mudaram; PostgreSQL real não foi repetido nesta entrega. Docker, CI remota, builds nativos e deploy não foram executados. A [revisão independente](CONCURSOS-REVISAO.md) incluiu 27 módulos/162 questões e 55 testes dirigidos; o autor corrigiu os três achados importantes em uma passagem, com regressões RED→GREEN, e adiou um ajuste menor de espaçamento. Não houve segunda revisão nem auditoria factual independente integral.

## Registro histórico — 01/10/2026

Verificação local em 01/10/2026, Windows, Node 24.19.0/npm 11.17.0, Flutter 3.47.5/Dart 3.13.4. Trabalho isolado em `codex/experiencia-estudo`, baseado na fundação `967b6a6`, no EstudaAi separado da AlmaPet. Integração local por fast-forward em `codex/estuda-ai-foundation`; geração dos modelos, formatação, análise, 35 testes API, 58 testes Flutter e build Web foram repetidos no checkout integrado. Nenhum push ou publicação.

| Verificação executada | Resultado |
| --- | --- |
| `npm test` | 35/35; build TypeScript e catálogo incluídos |
| `npm run test:pg:local` | 1/1 integração Prisma/PostgreSQL 18, com múltiplos cenários concorrentes |
| `npm run openapi` | Contrato Nest gerado sem listener/identidade simulada |
| `dart format --output=none --set-exit-if-changed lib test` | Sem alterações pendentes |
| `flutter test` | 58/58 |
| `flutter analyze` | Nenhum achado |
| `flutter build web --release --no-web-resources-cdn` | Build Web/shader/fontes/assets gerados |
| `npm run test:visual` | Chromium 1440×1000, 360×800, 768×1024; tema, teclado, shader, persistência e reduced motion |
| `npm run test:study` | Nove percursos por assunto/viewport, 45 questões, 18 seleções de aula/links externos; zero erro interno |
| Catálogo Flutter/API/bundle Web do checkout integrado | SHA256 idêntico: `116ab1a7daae5dff2782bd3dab6f659791bb5a1d7c674bc8e5752f11351bdff6` |
| Docker/Compose e GitHub Actions | Preparados; execução remota não realizada |

Web/testes usaram `FLUTTER_WINDOWS=false` no processo devido ao privilégio de symlink de plugins Windows indisponível. Não se alterou Developer Mode ou configuração global. O hash anterior do catálogo no worktree era `9c06a46b7de8060c2cd6a4bb37d7bb816e2fb951bcd18a1cd8d1484eea91b790`; o checkout Windows converteu finais de linha para CRLF, sem alterar o conteúdo JSON. As três cópias integradas são idênticas. O `main.dart.js` reconstruído no primário também é idêntico ao bundle validado no navegador. Na fundação de 30/09, instalação pelo lock, geração Prisma/modelos e auditoria npm foram executadas; a consulta daquela data reportou zero advisories. Não foi feita nova auditoria nesta entrega.

## Cobertura e natureza dos testes

- HTTP Nest real: saúde, autenticação, DTOs estritos, request ID, CORS, quotas IP/usuário, sanitização, corpo 64 KiB e cancelamento HTTP. Transportes Firebase/Responses são controlados explicitamente nos testes; não representam contas/provedores externos.
- Firebase Admin real rejeita JWT malformado/audiência de outro projeto antes de consultar serviços externos. Cadastro/login/refresh validam os ID tokens devolvidos pelo gateway. Não foram emitidos tokens reais nem comprovadas expiração/revogação de uma conta configurada.
- PGlite executa SQL/migrações/repositórios, isolamento de proprietário, restrições e rollback. Integração separada aplica ambas as migrações em PostgreSQL 18 vazio e usa dois PrismaClients: 20 reservas concorrentes respeitam 10 vagas, dois usuários disputam a última vaga global, devolução duplicada só decrementa uma vez, falha de insert faz rollback e novo dia tem buckets próprios. O cluster temporário é identificado pelo `data_directory` e encerrado; nenhum banco/serviço existente é alterado.
- Responses: campos enviados, múltiplos blocos, reasoning antes de texto, fase final versus comentário, recusa, resposta incompleta inclusive sem texto, timeout/abort e ausência de retry. Cota permanece consumida após envio incerto; abort antes do transporte libera uma vez. IDs/e-mail não entram no pedido ao provedor.
- Cliente: origem HTTPS/loopback, bearer, timeout/redirects, códigos seguros, refresh compartilhado, logout durante refresh, falha temporária com token ainda válido, recusa de token expirado, perfil não confirmado e recuperação sem afirmar acesso.
- Chat: uma chamada pendente, assunto/conta/geração/nova conversa/dispose cancelam e descartam conclusão tardia; pares completos até oito mensagens/12.000 caracteres; resposta incompleta/longa não entra como explicação completa. 503 preserva a pergunta sem inventar resposta; 401 remove a sessão.
- Quiz: cinco questões e alternativas embaralhadas, escolha única, explicação/avanço, sequência, perfeito 700, recorde serializado por assunto/versão e recuperação de falha local. Conteúdo de 30 questões revisado; notação percentual, inferência e energia disponível foram ajustadas.
- UI: três assuntos, navegações/rotas/contexto, seis players sob escolha, resultado→aula→Steve→conta, texto 200% e teclado, contraste nos dois temas, locale pt-BR. Capturas revelaram símbolos sem glifo; regressões foram reproduzidas antes de usar ícones Material empacotados. Fotografia local e quatro formas inspecionadas após build.
- Shader: compilação real, movimento por pixels, pausa/reabertura/persistência, lifecycle, detalhe fora da tela e movimento reduzido.

## Navegador e fronteiras externas

Relatórios em `artifacts/web-verification.json` e `artifacts/study-verification.json`; capturas em `artifacts/screenshots` e `artifacts/study`, ignorados pelo Git. A cópia preservada desta entrega no checkout primário está em `artifacts/2026-10-01-experiencia`, incluindo os registros de execução. Scripts reproduzíveis: `tools/verify-web.mjs` e `tools/verify-study.mjs`. Prévia `http://127.0.0.1:4173` enquanto o servidor estiver em execução; links de rotas Web usam `/#/aprender/porcentagem`, por exemplo.

O roteiro verificou todos os seis iframes com ID/título corretos e abertura de URL YouTube em popup por gesto real, em cada viewport. Pedidos externos abortados ao trocar/dispor player são registrados separadamente; não provam indisponibilidade do vídeo nem reprodução. Inspeção adicional confirmou playback real da primeira aula de porcentagem, `TEhv11SkDUs`: após clicar “Assistir vídeo”, o tempo avançou de0 para6,2 e12,2 segundos, `paused=false`, `readyState=4`, sem erro de mídia. Capturas/estado estão em `artifacts/playback`. Não se generaliza essa reprodução para as outras cinco aulas ou aparelhos.

Não há `.env` local de projeto com configuração Firebase/OpenAI demonstrada nem API atendendo 3001. A tentativa real de acesso no navegador recebe `ERR_CONNECTION_REFUSED` e mensagem segura de indisponibilidade. Esse erro esperado é separado dos erros internos. HTTP 503 por configuração ausente foi comprovado nos testes Nest, não alegado como resposta de um servidor local inexistente. Login e três respostas reais de matérias ficam pendentes de configuração; nenhum double entra no produto.

## Plataformas e entrega

| Área | Estado |
| --- | --- |
| Flutter Web/Chromium local | Build e percursos verificados |
| Android/iOS/Windows nativos | Scaffolds; builds/aparelhos/assinaturas não verificados |
| Prisma/PostgreSQL 18 isolado | Migrações e concorrência verificadas localmente |
| PostgreSQL 17 da CI/destino e job Compose | Configurados, ainda sem execução comprovada |
| Firebase/OpenAI com conta/chaves reais | Integração de código/testes pronta; validação ao vivo pendente |
| Docker/CI remota/stores/deploy | Não executados/publicados |

Não há homologação por leitor de tela real ou suíte completa de acessibilidade. A evidência cobre controles semânticos, contraste, teclado e reflow. Não foram medidos LCP/INP, bateria, GPU, carga comercial ou rollback do destino. Readiness executa `SELECT 1`; não confirma schema nem Firebase. CRUD de metas, adaptatividade, XP/ranking global e Premium comercial permanecem fora desta entrega.

## Revisão final

Revisão independente somente leitura do HEAD `b7407e6` identificou dois achados importantes e nenhum crítico/menor: refresh de usuário excluído devolvia503; saldo do chat permanecia anunciado como disponível após falha de tentativa e renovação UTC. Ambos foram reproduzidos antes da correção e resolvidos em uma passagem, com regressões HTTP/cliente e suíte completa verde. `USER_NOT_FOUND` agora devolve401 (conforme [Firebase REST](https://firebase.google.com/docs/reference/rest/auth#section-refresh-token)); o cliente já limpa a sessão em401. O saldo só volta a ser mostrado após confirmação válida do servidor, desaparece em envio/erro ou no reset, e a interface explica consumo de cota quando não chega resposta. Não se calcula reembolso no cliente.

Serviços externos sem configuração, cinco playbacks não observados, builds nativos/containers/CI/deploy e proxies/múltiplas instâncias permanecem fora da evidência atual. A preferência “Animação de fundo” controla o fundo; rolagem do CTA respeita movimento reduzido do dispositivo. Decisões de execução e custos estão em [Decisões da entrega](DECISOES-ENTREGA.md). Nenhum achado menor foi adiado.
