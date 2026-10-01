# Evidências da experiência de estudo

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
