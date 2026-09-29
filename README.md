# Estuda Aí

Plataforma de aprendizagem adaptativa com metas de estudo independentes.

> Você não precisa decidir o que estudar. O Estuda Aí decide seu próximo passo com base no seu desempenho.

## Estado do projeto

Projeto separado da AlmaPet, criado em 29/09/2026.

**Etapa atual: diagnóstico e especificação da fundação.** Ainda não existe aplicativo executável, API implementada ou build de distribuição nesta pasta. Os documentos distinguem o que foi verificado do que está proposto.

## Documentação

- [Requisitos originais](docs/REQUISITOS-ORIGINAIS.txt): texto integral fornecido pelo usuário.
- [Diagnóstico inicial](docs/DIAGNOSTICO-INICIAL.md): estrutura encontrada, tecnologias, Design System, riscos e verificações executadas.
- [Especificação da Fase 1](docs/superpowers/specs/2026-09-29-estuda-ai-fundacao-design.md): arquitetura proposta, limites, experiência inicial e critérios de aceite.

## Organização proposta

```text
EstudaAi/
├── apps/
│   ├── client/                 # Flutter: Android, iOS, Web e Windows
│   └── api/                    # NestJS + Prisma + PostgreSQL
├── contracts/                  # OpenAPI e contratos de integração
├── infra/                      # Docker, ambientes e operação
├── docs/                       # Arquitetura, instalação, API e deploy
└── .github/workflows/          # Verificação contínua
```

Essa árvore é a estrutura planejada; os diretórios de aplicação serão criados durante a implementação.

## Regras centrais

1. Dados pessoais pertencem ao usuário autenticado.
2. Conteúdo, tarefas, progresso, revisões e recomendações pertencem também a uma meta específica.
3. O backend determina autorização e benefícios Premium.
4. A aplicação não contém segredos de IA ou credenciais administrativas.
5. Azul identifica navegação; verde comunica evolução; amarelo sinaliza atenção; laranja representa desafios.
6. Percentuais, sequências e conquistas só aparecem quando calculados a partir de dados reais.

## Sequência do MVP

Fundação → Metas → Questões → Missão do Dia → Conteúdos multimodais → Revisões → Dashboard → Simulados → IA → Premium → Qualidade → Publicação.

As demais fases permanecem no escopo do produto. A primeira implementação deve fechar os critérios de aceite da fundação antes de avançar.
