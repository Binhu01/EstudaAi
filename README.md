# Estuda Aí

Plataforma de aprendizagem adaptativa com metas de estudo independentes, em projeto separado da AlmaPet.

## Estado atual

**Experiência de estudo implementada.** O cliente Flutter oferece hero educacional com fotografia e shader, três assuntos, seis videoaulas incorporadas, desafios individuais de cinco questões em estilo 8 bits e Steve, tutor com IA pelo backend. Tema e movimento são configuráveis. Aulas e quiz abrem sem conta; o chat exige acesso verificado.

A API NestJS integra cadastro/login/recuperação Firebase, perfil interno e Steve pela API Responses, com limites por usuário e cota diária persistida no PostgreSQL. A integração Prisma/PostgreSQL foi verificada em banco isolado real. Credenciais Firebase/OpenAI ainda precisam ser fornecidas ao ambiente para validar login e respostas reais; o produto não usa uma conta ou IA simulada.

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
flutter run -d chrome --web-port 4173 --dart-define=API_ORIGIN=http://127.0.0.1:3001
```

A Home, aulas e quiz podem abrir sem backend. Configure banco, Firebase e provedor/modelo a partir de `.env.example`, aplique migrações e siga [Instalação](docs/INSTALACAO.md). `API_ORIGIN` é uma origem pública, nunca uma chave. O login fica apenas em memória: recarregar o aplicativo exige entrar novamente.

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

## Contrato

| Rota | Acesso | Comportamento |
| --- | --- | --- |
| `GET /health/live` | Público | Processo atendendo |
| `GET /health/ready` | Público | Consulta ao banco; 503 em indisponibilidade |
| `POST /v1/auth/register`, `/login`, `/refresh`, `/password-reset` | Público, com limite por IP | Sessão Firebase ou confirmação genérica de recuperação |
| `GET /v1/me` | ID token Firebase verificado | ID interno e plano FREE |
| `GET /v1/me/entitlements` | ID token Firebase verificado | Capacidades atuais; Premium indisponível |
| `POST /v1/steve/messages` | ID token Firebase verificado | Tutor por assunto, fontes do catálogo e cota retornada pelo servidor |

O backend determina identidade e benefícios. A UI não concede Premium nem autoriza dados de outra meta. Segredos de banco/Firebase/IA ficam fora do cliente e do Git. Progresso, sequências e conquistas só devem aparecer quando houver dados reais das fases correspondentes.

## Documentação e continuidade

- [Instalação](docs/INSTALACAO.md): versões, comandos, configuração e execução local.
- [Experiência de estudo](docs/EXPERIENCIA-ESTUDO.md): assuntos, quiz, aulas e funcionamento do Steve.
- [Arquitetura](docs/ARQUITETURA.md) e [shader](docs/SHADER.md): fronteiras, isolamento e adaptação visual.
- [Validação](docs/VALIDACAO.md): resultados comprovados e limitações por plataforma.
- [Operação e deploy](docs/DEPLOY.md): migração explícita, containers, pendências e release.
- [OpenAPI](contracts/openapi.json): contrato dos endpoints existentes.
- [Requisitos originais](docs/REQUISITOS-ORIGINAIS.txt): escopo integral do produto.
- [Especificação da fundação](docs/superpowers/specs/2026-09-29-estuda-ai-fundacao-design.md) e [plano](docs/superpowers/plans/2026-09-29-fundacao.md): decisões e critérios da Fase 1.
- [Diagnóstico inicial](docs/DIAGNOSTICO-INICIAL.md): registro histórico anterior à implementação.

CRUD de metas, estudo adaptativo, missão do dia, revisões, dashboard, simulados e Premium comercial continuam fora desta entrega. Os desafios de Estudo livre não produzem XP global nem ranking compartilhado.
