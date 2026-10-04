# Fechamento da entrega e preparo de publicação

> Execução: direta, com revisão independente ao final, conforme autorização anterior e pedido de concluir as pendências.

**Objetivo:** fechar as verificações e o preparo operacional do Estuda Aí, preservar o visual aprovado e enviar uma branch para revisão.

**Arquitetura:** Flutter Web, NestJS/Firebase e PostgreSQL permanecem separados. Caddy serve o build e encaminha a API no mesmo domínio HTTPS; publicação efetiva depende do destino e DNS fornecidos pelo usuário. Uma instância de API enquanto os limites por minuto forem locais.

**Requisitos:** solicitação de 04/10/2026 e documentação existente de Rotina/Aprendizagem/Deploy. A ativação OpenAI foi novamente adiada pelo usuário durante esta execução. Não contratar hospedagem, comprar domínio, aceitar termos ou alterar assinaturas de lojas sem os dados/autorizações necessários.

## Tarefas e evidência

- [x] Corrigir empacotamento do catálogo de Concursos em .dockerignore e acrescentar builds runtime/migration à CI.
- [x] Corrigir atalhos pós-login em account_screen.dart usando LearningEntry/StudyRoutes; testar ambas as áreas e ações.
- [x] Configurar proxies por IP/CIDR explícitos, padrão desligado, em config.ts/contracts.ts/main.ts/app.ts; testes HTTP de quotas separadas e header forjado recusado.
- [x] Preparar infra/Caddyfile e exemplo de produção, validação no container agendada na CI; não declarar HTTPS público antes de DNS/servidor.
- [x] Implementar tools/postgres-backup.mjs com dump, hash e snapshot consistente; ensaiar restauração exclusivamente em banco novo, preservando o original e os arquivos privados.
- [x] Alinhar scripts web ao menu/gaveta, preferências e recortes reais de shader/cérebro; conferir via CUA; execução integral agendada na CI.
- [x] Corrigir permissão INTERNET do Android principal; documentar SDK, aparelho e assinatura ainda ausentes.
- [x] Atualizar README/guias com o estado atual e resultados executados, repetir testes apropriados e build Web.
- [ ] Revisar arquivos sem segredos, criar commit, enviar branch e abrir PR sobre codex/rotina-estudo, que contém a base atual.

Verificação local: API96/96, Flutter130/130, ferramentas54/54, integração PostgreSQL1/1, build/análise limpos. Backup real de7tabelas/1sequência passou, com original preservado. A revisão independente e o envio precedem a conferência dos três jobs remotos; resultados posteriores devem ser registrados no PR.

## Pontos de revisão

- Headers encaminhados só podem determinar IP quando a conexão direta vier de proxy explicitamente confiável.
- Uma restauração nunca pode selecionar ou sobrescrever o banco de estudo existente.
- Contagens do manifesto e dump devem compartilhar snapshot, mesmo com respostas concorrentes.
- Pós-login em Concursos deve manter o módulo e abrir material/Steve na área correta.
- Testes de movimento devem distinguir shader, cérebro e preferências, conservando o looping solicitado.

## Dependências externas

- OpenAI: usuário concluirá o acesso depois; não fazer chamada real.
- Navegador com conta: aguardando entrada do usuário em conta de teste.
- Domínio/hospedagem/orçamento: aguardando informação; preparo local não equivale a publicação.
- Aparelho real/SDK nativo: não disponíveis neste host; não afirmar homologação.
