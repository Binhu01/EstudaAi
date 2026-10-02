# Concursos no Estuda Aí

A área separada de Concursos oferece Banco do Brasil 2026 como **Preparação** para Escriturário — Agente Comercial. A referência é o edital histórico 2022/001, com consulta das normas em 01/10/2026 e revisão editorial em 02/10/2026. O nome da trilha não anuncia edital, vagas, banca ou calendário futuro, nem afiliação ao banco.

| Disciplina | Módulos | Questões comentadas |
| --- | ---: | ---: |
| Conhecimentos Bancários | 22 | 132 |
| Atualidades do Mercado Financeiro | 12 | 72 |
| Língua Portuguesa | 13 | 78 |
| Matemática | 18 | 108 |
| Língua Inglesa | 8 | 48 |
| Vendas e Negociação | 20 | 120 |
| Matemática Financeira | 7 | 42 |
| Informática | 21 | 126 |
| Redação | 5 | 30 |
| Total | 126 | 756 |

Cada módulo reúne objetivos, explicações, aplicação resolvida, erros frequentes, revisão, perguntas de recuperação, fontes e seis questões próprias. Fórmulas informam variáveis e condições; tabelas permitem rolagem horizontal. Inglês usa passagens autorais incorporadas aos enunciados que dependem delas. Redação inclui seis propostas com texto motivador, planejamento e autoavaliação; a escrita ocorre no caderno ou editor do aluno, sem editor persistente ou nota oficial.

As oito apostilas fornecidas orientaram a pesquisa dos assuntos. Seus textos, exemplos, imagens e exercícios não são distribuídos. O material foi escrito para a Estuda Aí, com revisão de gabaritos, exemplos e hipóteses. A comparação normalizada com as oito extrações privadas encontrou zero sequências iguais de pelo menos 12 palavras nos campos pedagógicos; essa checagem limitada não garante originalidade universal. A [matriz editorial](CONCURSOS-COBERTURA.md) e o [registro de fontes](CONCURSOS-REFERENCIAS.md) delimitam a cobertura.

Há 18 vídeos externos distintos, dois por disciplina, identificados por título e canal. São apoio complementar à disciplina. O player só é criado após seleção e mantém alternativa de abertura no YouTube. Metadados/oEmbed, iframe e link foram conferidos; reprodução dos 18 vídeos não foi comprovada.

O desafio 8 bits sorteia cinco das seis questões do módulo, sem repetição, e embaralha alternativas. A resposta trava a escolha e apresenta a explicação. Uma rodada perfeita vale 700 pontos. O recorde fica neste dispositivo, isolado por módulo e versão, preservando os recordes do Estudo livre. Não é um simulado oficial ou sala ao vivo.

Steve usa o contexto do módulo, notas curadas e fontes do servidor. Exige a mesma conta verificada e compartilha a cota por usuário com o Estudo livre. Trocar de área ou módulo cancela pedidos e descarta respostas antigas, inclusive ao voltar ao mesmo assunto. Login e IA reais dependem da configuração de Firebase, banco e provedor no backend; não há resposta ou conta de demonstração no produto.

Início abre o Estudo livre; Concursos abre o hub. Aprender, Desafios e Steve seguem a seleção ativa, e cada área lembra sua seleção. Preferências e Conta conservam esse contexto. No celular, Preferências fica no cabeçalho e também abre por Ctrl+,. Links com curso, disciplina ou módulo incompatíveis mostram recuperação.

O catálogo canônico é `apps/client/assets/contests/bb2026/catalog.json`, schema 1 e versão de conteúdo 1, independente do catálogo livre. O build valida e copia seus bytes para API e Web. O diretório do servidor reúne 129 identidades confiáveis, também usadas no OpenAPI. Não houve mudança de SQL ou cota.

Verificação reproduzível na raiz: `npm test`, `npm run openapi`, os três testes em `tools/test/contest-*.test.mjs` e `node tools/verify-contest-content.mjs --all`. No cliente: geração, formatação, `flutter analyze`, `flutter test` e build Web release. Com a prévia ativa: `npm run test:visual`, `npm run test:study`, `npm run test:contests`; use `PREVIEW_URL` para outra porta. Fontes privadas não são exigidas na CI.

Resultados e limites em [Validação](VALIDACAO.md). A [revisão independente](CONCURSOS-REVISAO.md) examinou o conjunto e uma amostra do material; o autor corrigiu os três achados importantes e a acessibilidade dos textos selecionáveis com regressões. Um ajuste menor de espaçamento foi adiado.
