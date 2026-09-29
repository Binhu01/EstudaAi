# Diagnóstico inicial — Estuda Aí

Data: 29/09/2026.

## 1. Resultado

A pasta originalmente aberta contém a **AlmaPet**, uma loja de produtos para pets. Não foi encontrada uma aplicação Estuda Aí nessa base. O usuário confirmou que são projetos diferentes e solicitou separação.

Destino criado para o Estuda Aí:

`C:\Users\glaub\OneDrive\Documentos\ChatGPT\EstudaAi`

A criação desse projeto não exige migrar a loja, converter seu banco ou substituir suas dependências.

## 2. Base inspecionada

| Área | Evidência na AlmaPet | Consequência para o Estuda Aí |
| --- | --- | --- |
| Interface | `frontend/package.json`: Next.js 16.3.6, React 19.3.0 e TypeScript | Não corresponde à aplicação Flutter solicitada |
| Backend | Server Actions em `frontend/src/app/actions/` e Supabase | Não há API NestJS |
| Banco | SQL em `supabase/migrations/` | Domínio de loja: perfis, pets, produtos e pedidos |
| Autenticação | Supabase Auth, cookies e validação no servidor | O fluxo atual pertence à loja |
| Autorização | RLS e funções PostgreSQL | Princípio útil, mas políticas não modelam metas de estudo |
| UI | CSS global, CSS Modules e lucide-react | Não há biblioteca de widgets Dart |
| Testes | Node test runner, PGlite e Playwright | Boa referência de categorias de teste; não validam o novo produto |
| Automação | `.github/workflows/ci.yml` | Pipeline voltado a Node/Next.js |
| Git | Branch `master` sem commits; arquivos aparecem como não rastreados | Não assumir que o estado existente pode ser recuperado pelo Git |

Referências locais inspecionadas: `README.md`, `package.json`, `frontend/package.json`, `frontend/AGENTS.md`, `frontend/CLAUDE.md`, `docs/ARQUITETURA.md`, `docs/VISUAL.md`, estilos, regras de domínio, migrations e testes.

As instruções específicas de Next.js em `frontend/AGENTS.md` pertencem ao frontend da AlmaPet; não definem a arquitetura do projeto separado.

## 3. Design System encontrado

A AlmaPet centraliza parte da paleta em `frontend/src/app/storefront.css`, mas ainda usa nomes históricos como `--green` e `--olive` para tons azuis. Existem valores de cores diretamente em componentes e estilos globais.

A composição é de comércio eletrônico: campanhas, vitrines, categorias e sacola. Não existem os tokens Dart solicitados: `AppColors`, `AppTypography`, `AppSpacing`, `AppRadius`, `AppElevation`, `AppShadows`, `AppIcons` e `AppAnimations`.

Não foram localizados, nos diretórios de código inspecionados, mecanismos de tema escuro pelos padrões pesquisados (`prefers-color-scheme`, `data-theme`, `dark:` ou `ThemeMode`).

Esses pontos não constituem uma auditoria completa da loja. Indicam que transportar seu visual e sua estrutura para o Estuda Aí criaria acoplamento e contrariaria o pedido.

## 4. Riscos arquiteturais relevantes

### Misturar os projetos

Compartilhar banco, identidade, migrações ou configuração de deploy criaria dependências entre dois produtos distintos. O Estuda Aí deve ter raiz, dependências, ambientes, banco, testes e histórico próprios.

### Isolamento insuficiente das metas

A seleção de uma meta na interface não é uma barreira de segurança. Todo acesso a dados de estudo precisa validar o usuário e a meta no servidor. Relacionamentos entre assunto, questão e tentativa devem impedir associações entre metas, inclusive do mesmo usuário.

O cache precisa usar, no mínimo, identidade do usuário, meta e recurso. Ao trocar de conta ou meta, requisições atrasadas não podem preencher a tela do contexto novo.

### SDKs com suporte desigual

A documentação do Firebase informa que o suporte Flutter no Windows não se destina a produção. A matriz também não oferece equivalência de Cloud Messaging e Analytics para Windows. Isso afeta a escolha dos adaptadores, e não apenas a aparência da aplicação. [Fonte oficial](https://firebase.google.com/docs/flutter/setup).

A arquitetura deve separar autenticação, notificações e analytics das regras de estudo. Um futuro adaptador Windows poderá integrar autenticação por APIs oficiais, mas essa integração exige verificação própria; não está homologada por este diagnóstico.

### Segurança dependente apenas da interface

Ocultar uma ação Premium ou uma meta de outro usuário não impede chamadas diretas à API. Autorização, validação e entitlement precisam ser aplicados no backend. IA deve receber contexto autorizado e ter limites de custo por usuário.

### Confundir fundação com produto comercial pronto

Definir contratos e criar a navegação não entrega questões, planejamento adaptativo, cobrança ou publicação. Cada fase exige comportamento implementado, testes e evidência. O projeto não deve exibir números de exemplo como se fossem desempenho real.

## 5. Ambiente observado

| Ferramenta | Resultado |
| --- | --- |
| Node.js | 24.19.0 |
| npm | 11.17.0 |
| Git | Disponível |
| Flutter | Não encontrado no PATH nem nos caminhos candidatos verificados |
| Dart | Não encontrado no PATH |
| Docker | Não encontrado no PATH |

A ausência no PATH não prova ausência em todo o computador. Não houve instalação de SDKs ou alteração global do ambiente.

O host atual é Windows. Builds e distribuição iOS precisam de macOS e Xcode; isso deverá ser atendido por uma máquina apropriada ou executor de CI. [Fonte oficial](https://docs.flutter.dev/deployment/ios).

## 6. Verificações executadas

Executadas na AlmaPet, antes de criar código do novo produto:

| Comando | Resultado |
| --- | --- |
| `npm test` | 35 testes passaram; nenhuma falha |
| `npm run typecheck` | Terminou com código 0 |
| `git status --short` | Arquivos existentes não rastreados |
| `git log -5 --oneline` | Repositório ainda sem commits |
| `git diff --stat` e `git ls-files` | Sem conteúdo rastreado para comparar |

Não foram executados build de produção, navegador, testes de acessibilidade, deploy ou homologação de serviços externos neste diagnóstico. Os testes da AlmaPet não são testes do Estuda Aí.

## 7. Recomendação

Criar o Estuda Aí como um monorepositório próprio, com cliente Flutter e backend NestJS modular, preservando PostgreSQL e Prisma conforme o pedido.

Começar pela Fase 1 delimitada na [especificação da fundação](superpowers/specs/2026-09-29-estuda-ai-fundacao-design.md). O primeiro resultado verificável será a base executável, o sistema de temas, a proteção da API e os contratos testados de contexto. As funcionalidades de estudo avançam na sequência de fases fornecida pelo usuário.
