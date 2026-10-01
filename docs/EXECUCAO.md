# Registro de execução — Fundação

Plano: `docs/superpowers/plans/2026-09-29-fundacao.md`.

- Especificação aprovada pelo usuário em 29/09/2026, com referência ShaderGradient.
- Execução no repositório independente já criado, branch `codex/estuda-ai-foundation`; não criar worktree da AlmaPet por engano.
- Preservar SDK local em `.tooling/` ignorado pelo Git.
- O preset React foi adaptado para GLSL Flutter, com correspondências e limites em `docs/SHADER.md`.
- Pre-flight: API fornece identidade/entitlements; cliente só consome os contratos existentes. Home não depende de serviços de estudo ainda não implementados.
- Tarefa 1: implementada e testada. Firebase Admin, configuração, guards, CORS/Helmet, logs seguros e quota por identidade.
- Tarefa 2: implementada; migração SQL e isolamento testados com PGlite. Integração do adapter Prisma/PostgreSQL completo pendente.
- Tarefa 3: implementada e testada. Preferências serializadas, contexto/cancelamento, Freezed/JSON e Dio; sem sessão fictícia no bootstrap.
- Tarefa 4: implementada. Shader compilado, contraste, pausa e fallback verificados; sem equivalência exata com a cena 3D original.
- Tarefa 5: implementada. Home vazia, locale pt-BR, navegação/tema, texto a 200% e Chromium nos três tamanhos.
- Tarefa 6: operação/docs preparadas, revisão independente concluída e verificações locais registradas. Docker, CI remota e deploy não executados.

Conclusão local em 30/09/2026. [Validação](VALIDACAO.md) registra evidências e limites. A Fase 2 deve completar autenticação antes de liberar metas pessoais.

## Ajustes de execução

- SDK Flutter local; configuração Git de arquivos longos restrita ao próprio SDK.
- `FLUTTER_WINDOWS=false` apenas no processo para Web/testes; Windows nativo não validado.
- PGlite substituiu Docker/PostgreSQL nos testes de SQL, sem declarar o adapter completo como verificado.
- Playwright sobre o build real substitui `integration_test` dependente de dispositivo nesta fase.
- Revisão corrigiu perda de preferências simultâneas, connect timeout, quota por usuário e documentação de erros; regressões passaram.
- Lockfile re-resolvido com overrides; instalação sem scripts de dependências e geração Prisma explícita.
