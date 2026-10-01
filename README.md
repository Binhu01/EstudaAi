# Estuda Aí

Plataforma de aprendizagem adaptativa com metas de estudo independentes, em projeto separado da AlmaPet.

## Estado atual

**Fundação implementada, com verificações locais registradas.** O cliente Flutter oferece Home responsiva, Preferências persistidas, temas claro/escuro e shader decorativo com controle de movimento. A galeria de componentes é de desenvolvimento. O fluxo executável ainda não inclui login, CRUD de metas ou atividades de estudo.

A API NestJS implementa saúde pública, verificação de identidade pelo Firebase Admin no backend, perfil interno em `/v1/me` e entitlements FREE. Prisma/PostgreSQL tem migração mínima de usuários e metas, com acesso de repositório vinculado a usuário/meta. A integração com Firebase real e com o adapter Prisma/PostgreSQL ainda precisa de validação configurada; doubles e PGlite têm evidência própria.

Docker/Compose e CI foram preparados, mas Docker não está disponível nesta máquina e o workflow não foi executado remotamente. Nenhum deploy ou publicação foi feito. Os diretórios de plataforma gerados pelo SDK não representam builds Android, iOS ou Windows homologados. Veja [Validação](docs/VALIDACAO.md) para comandos realmente executados e pendências.

## Começar

Use Node 24.x e Flutter 3.47.5/Dart 3.13.4. Na raiz, instale o workspace da API e gere Prisma:

```powershell
npm ci --ignore-scripts
npm run db:generate
npm test
```

No cliente, após disponibilizar Flutter no PATH da sessão:

```powershell
Set-Location apps/client
flutter pub get --enforce-lockfile
dart run build_runner build
flutter run -d chrome --web-port 4173
```

A Home pode abrir sem backend. Para API real, configure banco e credenciais externas a partir de `.env.example`, aplique migrações explicitamente e siga [Instalação](docs/INSTALACAO.md). O guia também registra a alternativa de processo usada para testes/Web neste Windows, sem validar o app Windows nativo.

Para conferir a versão compilada, gere `flutter build web --release --no-web-resources-cdn` no cliente e execute `npm run preview` na raiz. A prévia abre em `http://127.0.0.1:4173`; `npm run test:visual` verifica esse build após preparar Chromium, conforme o guia de instalação. A instalação npm omite scripts de dependências; Prisma e os modelos Dart são gerados explicitamente.

## Estrutura

```text
EstudaAi/
├── apps/client/               # Flutter, preferências e Design System
├── apps/api/                  # NestJS, Firebase Admin, Prisma e testes
├── contracts/                 # Contrato OpenAPI
├── infra/                     # Compose e operação local
├── docs/                      # Especificação, instalação e evidências
└── .github/workflows/          # CI de API e Flutter Web
```

## Contrato inicial

| Rota | Acesso | Comportamento |
| --- | --- | --- |
| `GET /health/live` | Público | Processo atendendo |
| `GET /health/ready` | Público | Consulta ao banco; 503 em indisponibilidade |
| `GET /v1/me` | ID token Firebase verificado | ID interno e plano FREE |
| `GET /v1/me/entitlements` | ID token Firebase verificado | Capacidades atuais; Premium indisponível |

O backend determina identidade e benefícios. A UI não concede Premium nem autoriza dados de outra meta. Segredos de banco/Firebase/IA ficam fora do cliente e do Git. Progresso, sequências e conquistas só devem aparecer quando houver dados reais das fases correspondentes.

## Documentação e continuidade

- [Instalação](docs/INSTALACAO.md): versões, comandos, configuração e execução local.
- [Arquitetura](docs/ARQUITETURA.md) e [shader](docs/SHADER.md): fronteiras, isolamento e adaptação visual.
- [Validação](docs/VALIDACAO.md): resultados comprovados e limitações por plataforma.
- [Operação e deploy](docs/DEPLOY.md): migração explícita, containers, pendências e release.
- [OpenAPI](contracts/openapi.json): contrato dos endpoints existentes.
- [Requisitos originais](docs/REQUISITOS-ORIGINAIS.txt): escopo integral do produto.
- [Especificação da fundação](docs/superpowers/specs/2026-09-29-estuda-ai-fundacao-design.md) e [plano](docs/superpowers/plans/2026-09-29-fundacao.md): decisões e critérios da Fase 1.
- [Diagnóstico inicial](docs/DIAGNOSTICO-INICIAL.md): registro histórico anterior à implementação.

Fundação → Metas (inclui login completo) → Questões → Missão do Dia → Conteúdos multimodais → Revisões → Dashboard → Simulados → IA → Premium → Qualidade → Publicação.

Essas fases compõem o MVP, mas as posteriores à fundação ainda não estão implementadas.
