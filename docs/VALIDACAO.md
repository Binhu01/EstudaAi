# Evidências da fundação

Verificação local em 30/09/2026, Windows, Node 24.19.0/npm 11.17.0, Flutter 3.47.5 e Dart 3.13.4. Projeto independente na branch `codex/estuda-ai-foundation`.

| Verificação executada | Resultado |
| --- | --- |
| `npm ci --ignore-scripts` com lockfile corrigido | Instalação concluída |
| `npm run db:generate` | Prisma Client 6.19.3 gerado |
| `npm test` | 13 testes passaram; build TypeScript incluído |
| `npm run openapi` | Contrato gerado da aplicação Nest, sem listener |
| `npm audit --json` | Zero vulnerabilidades reportadas na consulta |
| `dart run build_runner build` | Modelos Freezed/JSON gerados |
| `dart format --output=none --set-exit-if-changed lib test` | Formatação verificada |
| `flutter test` | 18 testes passaram |
| `flutter analyze` | Nenhum alerta |
| `flutter build web --release --no-web-resources-cdn` | Build Web e shader compilados |
| `npm run test:visual` | Chromium: 1440×1000, 360×800 e 768×1024 |
| Docker/Compose e GitHub Actions | Revisão estática; execução não realizada |

Web/testes usaram `FLUTTER_WINDOWS=false` no processo porque o privilégio de symlink de plugins Windows não estava disponível. Não foi alterado Developer Mode ou outra configuração global.

## Cobertura comprovada

- HTTP Nest real: saúde, sessão obrigatória, perfil interno, FREE, sanitização de falhas/logs, request ID, CORS e quotas por IP e por usuário entre endpoints.
- O teste HTTP usa um verificador injetado. Strings `expired`/`other-project` nesse teste demonstram recusa do guard, não emissão/expiração real de tokens.
- Um teste separado usa Firebase Admin real para rejeitar JWT malformado e audiência de outro projeto antes de consultar certificados/usuários. Login válido, assinatura de token emitido, expiração/revogação e credenciais reais permanecem sem teste de ponta a ponta.
- PGlite aplica o SQL real da migração e executa consultas parametrizadas do repositório: dois usuários/metas, acesso cruzado, atualização alheia, SQL literal e restrições de banco. Não equivale a executar o adapter Prisma com PostgreSQL completo.
- Cliente: chave de cache separada por usuário/meta, descarte de resposta antiga inclusive ao voltar à meta, logout, callback de cancelamento, preferências corrompidas, persistência e alterações simultâneas.
- Dio: origem configurada, bearer do contrato de sessão, prazo de conexão, redirects desativados, sessão ausente/401, resposta inválida e códigos seguros para timeout, rede indisponível e cancelamento. A rede usa adapter controlado nos testes; o bootstrap ainda não tem login nem conexão com a API.
- UI: navegação e tema em 360/1440; texto a 200% em celular; pares de contraste nos dois temas; locale pt-BR. A revisão independente também conferiu texto a 200% no desktop.
- Shader real compilado: avanço do tempo, pausa/retomada por lifecycle, movimento reduzido e rolagem; falha do programa mantém o fundo estático utilizável.
- Chromium no build de produção: temas, animação, reabertura com escolhas persistidas, Enter/Tab e nenhum erro no console nos três viewports. Comparação de uma faixa de pixels decorativos verifica movimento e pausa sem confundir foco com shader. Uma janela adicional verifica `prefers-reduced-motion: reduce`.

Capturas e relatório locais: `artifacts/screenshots/` e `artifacts/web-verification.json`, ignorados pelo Git. Script reproduzível: `tools/verify-web.mjs`. Prévia: `http://127.0.0.1:4173`, enquanto `npm run preview` estiver em execução.

## Revisão e correções

A revisão independente identificou concorrência nas preferências, timeout de conexão ausente, falta de quota por usuário e respostas ausentes no OpenAPI. As falhas foram reproduzidas antes das correções; regressões passaram depois. A revisão final não apontou novos problemas materiais. Operação foi revisada separadamente; actions foram fixadas em SHAs de tags oficiais conferidas.

Overrides corrigem `js-yaml`, `deepmerge-ts` e o `uuid` transitivo de `gaxios`. A árvore foi re-resolvida sem o lock antigo; instalação, geração Prisma e testes passaram. Zero avisos de auditoria é uma consulta pontual de advisories, não ausência absoluta de risco.

## Limites da entrega

| Área | Estado |
| --- | --- |
| Flutter Web/Chromium local | Build e fluxo verificados |
| Android | Scaffold; sem SDK/aparelho/build ou assinatura de release verificados |
| iOS | Scaffold; sem macOS/Xcode/build ou assinatura verificados |
| Windows nativo | Scaffold; sem compilação C++/symlinks autorizados verificados |
| Firebase com tokens emitidos | Configuração e teste real pendentes |
| Prisma/PostgreSQL real e migration deploy | Pendentes de infraestrutura |
| Docker e CI remota | Não executados |
| Stores/deploy comercial | Não publicados |

Não foram medidos bateria, GPU, dispositivos reais, LCP/INP ou carga multiusuário. Não há homologação por suíte completa de acessibilidade ou leitor de tela real; a evidência atual cobre contraste, semântica/controles, teclado e reflow. Readiness verifica `SELECT 1`, não schema ou Firebase. Login/CRUD de metas, estudo adaptativo, IA e Premium comercial pertencem às próximas fases.
