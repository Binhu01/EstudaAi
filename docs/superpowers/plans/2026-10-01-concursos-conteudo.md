# Material autoral de Concursos — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Produzir e revisar 126 módulos autorais da Estuda Aí, 756 questões comentadas, seis propostas de Redação e 18 apoios de vídeo para a trilha Banco do Brasil 2026.

**Architecture:** A autoria preenche o canônico modular após T1 do [plano principal](2026-10-01-concursos-bb2026.md); disciplinas são verificadas isoladamente durante a produção e o catálogo integral somente em C10. A matriz de cobertura relaciona cada habilidade aos blocos, exemplos, prática e fontes; contagens não substituem revisão de conteúdo.

**Tech Stack:** JSON estruturado, verificadores Node/TypeScript definidos em T1, pesquisa de fontes primárias, testes independentes de cálculos e revisão editorial.

**Spec:** [Especificação aprovada](../specs/2026-10-01-concursos-bb2026-design.md) e [mapa curricular](../../CONCURSOS-MAPA-CURRICULAR.md).

## Global Constraints

- Todos os Global Constraints e contratos do plano principal se aplicam integralmente; executar C0–C10 entre T1 e T2.
- Autoria direta com revisão independente ao final, conforme preferência já escolhida; não despachar um implementador/revisor por disciplina.
- PDFs servem apenas de referência temática. Não reutilizar sua redação, sequência expositiva, exemplos, questões, tabelas/imagens ou identidade visual.
- Cada módulo: objetivos, explicação suficiente para a prática, exemplo desenvolvido/conferido, cuidados, revisão/recuperação, seis questões de quatro alternativas, comentários e fontes.
- 121 unidades objetivas + cinco oficinas; 756 questões, seis tarefas completas de escrita e 18 vídeos externos identificados. Conteúdo genérico repetido não satisfaz módulos diferentes.
- Taxas/regras/versões dependentes de data exigem conferência em fontes primárias no momento da autoria. Não presumir que os resumos enviados representam o programa completo.
- Não prometer aprovação, nota oficial de Redação, previsão de tema ou domínio por quantidade de material. A trilha tem status Preparação e referência histórica.

## Review Focus

1. Item histórico ausente na apostila precisa de explicação e prática próprias, não só título novo — C1–C9/C10.
2. Enunciado com duas respostas defensáveis ou distratores equivalentes precisa de correção antes de liberar o módulo — C1–C9/C10.
3. Juros com taxa/prazo ou datas incompatíveis e arredondamento oculto precisam de hipóteses explícitas e conferência independente — C4/C7.
4. Lei/documento institucional ou software antigo precisa de data/versão e distinção entre referência histórica e situação atual — C1/C2/C6/C8.
5. Passagem motivadora ou exemplo parecido com o PDF precisa de revisão da origem e redação independente; um detector não garante originalidade — C3/C5/C9/C10.

---

## Arquivos, testes e rotina comum

**Canônico compartilhado:** `apps/client/assets/contests/bb2026/catalog.json`. Atualizar uma disciplina por tarefa, preservando as já revisadas. Não criar nove fontes concorrentes nem distribuir extrações privadas.

**Registro de cobertura:** criar `docs/CONCURSOS-COBERTURA.md`, com uma linha por módulo contendo ID, itens históricos, objetivos, blocos/exemplo, IDs das questões, fontes/data e resultado da revisão editorial. Produzido a partir dos vínculos canônicos com observações da revisão humana; nunca marcar como coberto por presença do título.

**Testes editoriais:** criar `tools/test/contest-editorial.test.mjs`. `loadEditorialRoot()` lê o canônico relativo à raiz do projeto; importar `verifyContestContent` e `verifyContestMetadata` do verificador T1. Cada teste de disciplina segue estas assertions (valores específicos nas tarefas): `assert.deepEqual(report.errors,[])`, `assert.equal(report.modules,N)`, `assert.equal(report.questions,6*N)`, `assert.equal(report.writingTasks,W)`. Criar o teste antes do respectivo conteúdo e constatar falha real por ausência de módulos; não contar um filtro sem testes como falha ou sucesso.

Comandos por disciplina, na raiz: `node --test --test-name-pattern=<nome> tools/test/contest-editorial.test.mjs` e `node tools/verify-contest-content.mjs --discipline <id>`. Saída esperada após autoria: exit0 e contagens exatas, sem erros de vínculos/estrutura. As demais disciplinas incompletas ainda não tornam o catálogo publicável.

Rotina editorial em cada tarefa: consultar as fontes indicadas e conferir lacunas do mapa; escrever do zero explicações/passagens, exemplos e questões; resolver cada questão sem consultar o gabarito; revisar alternativas e comentário; verificar matrizes e dados; registrar cobertura/fontes. Escrever pelo menos um exemplo completo por módulo, com `check` efetivo. Distribuir reconhecimento, aplicação e interpretação nas seis questões, evitando trocar apenas números ou substantivos. Atualizar as três sugestões do Steve para o assunto real.

## Task 1: C0 — Referências de vídeo e metadados

**Files:** criar canônico, `docs/CONCURSOS-COBERTURA.md`, `tools/test/contest-editorial.test.mjs`; atualizar `docs/CONCURSOS-REFERENCIAS.md` com links complementares sem copiar conteúdo.

**Interfaces:** consome contrato T1; produz envelope com curso, nove disciplinas e duas aulas reais por disciplina, inicialmente sem módulos. `verifyContestMetadata(root):{lessons:number,errors:string[]}` valida exclusivamente metadados/apoios; esse resultado não libera o catálogo parcial.

- [x] Escrever `metadata_and_videos_ready`: `assert.equal(report.lessons,18)`, `assert.deepEqual(report.errors,[])`; curso/status/data/canal, URLs/IDs únicos e nove disciplinas presentes.
- [x] Rodar o teste e constatar falha por arquivo/apoios ausentes.
- [x] Curar 18 vídeos distintos, pertinentes aos focos do mapa, com páginas do vídeo/canal de autoria identificada; conferir disponibilidade, incorporação e contexto temporal. Registrar título, canal, descrição, nível e videoId reais, sem inventar IDs ou autoria. Criar metadados do curso com comunicado/canal oficial e edital histórico já registrados; manter rótulo Preparação.
- [x] Rodar o teste: exit0. Registrar em artifacts o que foi realmente observado sobre player/link e substituir apoio indisponível.
- [x] Commit dos arquivos C0: `content: curar aulas e referencias de concursos`.

## Task 2: C1 — Conhecimentos Bancários

**Files:** canônico, cobertura e teste editorial. **Interfaces:** consome envelope C0/T1; produz `bancarios`, B01–B22/`bb2026-b01`…`b22`, 22 módulos, 132 questões e zero tarefas de escrita.

- [x] Adicionar `bancarios_ready` com N=22/W=0, usando as quatro assertions da rotina.
- [x] Rodar o comando da rotina; confirmar falha por módulos ausentes.
- [x] Redigir os 22 focos do mapa, complementando os 23 itens históricos. Conferir BCB/CVM/Susep/Previc, legislação consolidada de sigilo/LGPD/PLD/anticorrupção e documentos oficiais do BB. Diferenciar órgãos normativos/supervisores, mercados/produtos/garantias, moeda/inflação/política, câmbio/juros, proteção/ética/PRSAC. LGPD não se limita a consentimento. Datas/nomes institucionais e normas precisam da fonte atual confirmada, não da apostila.
- [x] Resolver/revisar as 132 questões e os exemplos; conferir competências, âmbito das regras e condições, sem aconselhamento financeiro individual. Preencher os vínculos de todos os objetivos/itens, notas/fontes e cobertura real.
- [x] Rodar teste e `--discipline bancarios`: exit0/N22/Q132/W0.
- [x] Commit dos arquivos C1: `content: escrever conhecimentos bancarios autorais`.

## Task 3: C2 — Atualidades do Mercado Financeiro

**Files:** canônico, cobertura, teste. **Interfaces:** consome C0/T1; produz `atualidades`, A01–A12, 12 módulos, 72 questões/W0.

- [x] Adicionar `atualidades_ready` com N=12/W=0, usando as quatro assertions da rotina.
- [x] Rodar o comando da rotina e confirmar falha por módulos ausentes.
- [x] Redigir os 15 itens históricos nos 12 focos: transformação digital/canais, Open Finance, fintech/startup/bigtech, intermediação não bancária, moeda, blockchain/criptoativos, marketplaces, correspondentes, arranjos/Pix e segmentação. Conferir BCB e fontes técnicas originais; distinguir fatos datados e conceito estável. Não tratar funcionamento 24h, tecnologia ou criptoativo como garantia de disponibilidade/segurança/retorno.
- [x] Revisar 72 gabaritos, casos e cobertura; exemplos novos com decisões de acesso, consentimento e proteção, sem estatísticas ou agenda futura inventadas.
- [x] Rodar teste e `--discipline atualidades`: exit0/N12/Q72/W0.
- [x] Commit dos arquivos C2: `content: escrever atualidades financeiras autorais`.

## Task 4: C3 — Língua Portuguesa

**Files:** canônico, cobertura, teste. **Interfaces:** consome C0/T1; produz `portugues`, P01–P13, 13 módulos, 78 questões/W0.

- [x] Adicionar `portugues_ready` com N=13/W=0, usando as quatro assertions da rotina.
- [x] Rodar o comando da rotina e confirmar falha por módulos ausentes.
- [x] Criar passagens/exemplos próprios nos nove itens históricos: leitura/evidência, classes, ortografia, oração/período, pontuação, concordância, regência, crase e colocação. Conferir ABL/VOLP e gramáticas/fontes acadêmicas primárias adequadas. Explicar sintaxe e condições antes de regras; não reduzir vírgula a pausa ou regência a concordância.
- [x] Resolver 78 perguntas no contexto escrito, conferindo variantes normativas aceitáveis e evidência das inferências. Eliminar perguntas com alternativa igualmente defensável; explicar o raciocínio e os erros relevantes, sem reutilizar passagens dos PDFs.
- [x] Rodar teste e `--discipline portugues`: exit0/N13/Q78/W0.
- [x] Commit dos arquivos C3: `content: escrever portugues autoral para concursos`.

## Task 5: C4 — Matemática

**Files:** canônico, cobertura, teste; criar `apps/api/test/contest-calculations.test.ts` com oráculos independentes identificados por questionId.

**Interfaces:** consome C0/T1; produz `matematica`, M01–M18, 18 módulos, 108 questões/W0; verificações numéricas que C7 amplia.

- [x] Adicionar `matematica_ready` com N=18/W=0, usando as quatro assertions da rotina.
- [x] Rodar o comando da rotina e confirmar falha por módulos ausentes.
- [x] Redigir os 11 itens históricos, além de proporções/porcentagens do PDF: números/contagem/medidas, lógica/conjuntos, relações/funções polinomiais/exponenciais/logarítmicas, matrizes/determinantes/sistemas, sequências/PA/PG. Declarar unidades, domínio, base percentual, denominador e hipótese de proporcionalidade. Usar referências acadêmicas originais e cálculos próprios.
- [x] Conferir 108 respostas por método independente e registrar exemplos/oráculos representativos por família de cálculo. Nos testes, usar contas exatas/racionais, enumeração ou substituição na condição original, comparando com a alternativa correta; não apenas comparar o índice com ele mesmo. Oráculos de combinatória, lógica, funções, álgebra linear e progressões devem exercitar suas condições.
- [x] Rodar teste editorial/`--discipline matematica` e `npm run build` seguido de `node --test apps/api/dist/test/contest-calculations.test.js`: exit0/N18/Q108/W0, oráculos conferidos.
- [x] Commit dos arquivos C4: `content: escrever matematica e conferir gabaritos`.

## Task 6: C5 — Língua Inglesa

**Files:** canônico, cobertura, teste. **Interfaces:** consome C0/T1; produz `ingles`, E01–E08, oito módulos, 48 questões/W0.

- [x] Adicionar `ingles_ready` com N=8/W=0, usando as quatro assertions da rotina.
- [x] Rodar o comando da rotina e confirmar falha por módulos ausentes.
- [x] Escrever passagens próprias e oito focos de vocabulário/gramática/leitura, cobrindo o item histórico amplo. Conferir British Council e fontes linguísticas primárias; explicar auxiliares, tempo/aspecto, modalidade/voz, posse/referência, conectores, informação/ideia central, inferência/propósito. Não supor que posição de frase ou título prova interpretação.
- [x] Revisar as 48 questões com evidência textual e distinções de contexto. Preservar variantes válidas, diferenciar my/mine e forma/função dos auxiliares; comentários em português com trechos inéditos do próprio material.
- [x] Rodar teste e `--discipline ingles`: exit0/N8/Q48/W0.
- [x] Commit dos arquivos C5: `content: escrever ingles autoral para concursos`.

## Task 7: C6 — Vendas e Negociação

**Files:** canônico, cobertura, teste. **Interfaces:** consome C0/T1; produz `vendas`, V01–V20, 20 módulos, 120 questões/W0.

- [x] Adicionar `vendas_ready` com N=20/W=0, usando as quatro assertions da rotina.
- [x] Rodar o comando da rotina e confirmar falha por módulos ausentes.
- [x] Redigir os 17 itens históricos: competição/posição/segmentação, valor/jornada/aprendizagem, serviços/qualidade/processos, venda/marketing/canais, negociação/atendimento, relacionamento regulado/ouvidoria, inclusão/CDC. Conferir normas BCB/CMN, CDC/LBI/LGPD compilados e fontes originais de qualidade/marketing quando usadas. Ensinar negociação efetiva e adequação da oferta, ausentes no resumo; não tratar NPS como medida de toda satisfação nem Pareto/Ishikawa como prova causal.
- [x] Conferir 120 perguntas com casos novos e informação suficiente; limites/vulnerabilidades/acessibilidade e ética não viram frases genéricas sem decisão prática. Não criar obrigação normativa a partir de norma auxiliar de qualidade.
- [x] Rodar teste e `--discipline vendas`: exit0/N20/Q120/W0.
- [x] Commit dos arquivos C6: `content: escrever vendas e negociacao autorais`.

## Task 8: C7 — Matemática Financeira

**Files:** canônico, cobertura, teste; ampliar `apps/api/test/contest-calculations.test.ts`.

**Interfaces:** consome C0/T1 e oráculos C4; produz `financeira`, F01–F07, sete módulos, 42 questões/W0.

- [x] Adicionar `financeira_ready` com N=7/W=0, usando as quatro assertions da rotina.
- [x] Rodar o comando da rotina e confirmar falha por módulos ausentes.
- [x] Redigir linha do tempo, juros simples/compostos, taxa/período, equivalência, SAC e Price, nos quatro itens históricos. Conferir BCB/metodologia da Calculadora do Cidadão e referências matemáticas primárias. Criar capitais, taxas e fluxos inéditos; explicitar taxa constante, pagamentos ao fim do período, encargos/indexação ausentes nos casos didáticos, arredondamento e unidades. Conversão anual/12 não substitui equivalência composta.
- [x] Conferir todas as 42 respostas e tabelas por fluxo de caixa/saldo e método independente. Oráculos `simple_interest_units`, `compound_equivalent_rates`, `sac_balance_zero`, `price_discounted_payments_equal_principal` devem comparar a alternativa/resultado numérico autoral, com tolerância declarada por arredondamento. Não reutilizar o caso incompleto ou a fórmula vazia do PDF.
- [x] Rodar teste/`--discipline financeira` e testes numéricos C4: exit0/N7/Q42/W0, saldo/capital reconciliados.
- [x] Commit dos arquivos C7: `content: escrever matematica financeira com calculos conferidos`.

## Task 9: C8 — Informática

**Files:** canônico, cobertura, teste. **Interfaces:** consome C0/T1; produz `informatica`, I01–I21, 21 módulos, 126 questões/W0.

- [x] Adicionar `informatica_ready` com N=21/W=0, usando as quatro assertions da rotina.
- [x] Rodar o comando da rotina e confirmar falha por módulos ausentes.
- [x] Redigir os 14 itens históricos: sistemas, documentos/planilhas/apresentações, segurança/proteção, arquivos/programas/redes/protocolos/navegadores, comunicação/social, BI/análise, EAD/multimídia/trabalho remoto/nuvem. Conferir documentação Microsoft/SUSE/GNU, CERT.br, RFCs e fornecedores do software efetivamente usado. Contextualizar os alvos históricos do edital; não anunciar LibreOffice como suíte exigida por ele nem recomendar versões legadas para instalação atual.
- [x] Revisar 126 perguntas. Exercícios operacionais identificam aplicativo/idioma/versão e resultado esperado. Distinguir IMAP/POP/SMTP, CCO, e-mail/webmail, sincronização/backup, permissões/segurança, SSD/HDD e distribuições/suítes; não afirmar imunidade de sistema ou equivalência automática de comandos.
- [x] Rodar teste e `--discipline informatica`: exit0/N21/Q126/W0.
- [x] Commit dos arquivos C8: `content: escrever informatica autoral e contextualizada`.

## Task 10: C9 — Oficinas de Redação

**Files:** canônico, cobertura, teste. **Interfaces:** consome C0/T1; produz `redacao`, R01–R05, cinco oficinas, 30 questões formativas e seis WritingTasks (1/1/1/1/2).

- [x] Adicionar `redacao_ready` com N=5/W=6, assertions da rotina e `assert.deepEqual(redacao.modules.map(m=>m.writingTasks.length),[1,1,1,1,2])`.
- [x] Rodar o comando da rotina e confirmar falha por módulos/tarefas ausentes.
- [x] Escrever tarefa/gênero, planejamento/tese, argumentos, progressão/coerência/coesão e revisão; usar os critérios históricos 7.3 como referência identificada. Criar seis propostas completas com tema, tarefa, texto motivador próprio, planejamento e autoavaliação. Exercícios desenvolvidos mostram escolhas/revisões de trechos, não só orientações abstratas.
- [x] Resolver/revisar as 30 questões sobre decisões de escrita e cada proposta; conferir se há produção/reescrita possível sem editor persistente. Sugestões do Steve apoiam planejamento/revisão de trechos no limite de mensagem existente, sem oferecer nota oficial ou previsão de tema.
- [x] Rodar teste e `--discipline redacao`: exit0/N5/Q30/W6.
- [x] Commit dos arquivos C9: `content: escrever oficinas e propostas originais de redacao`.

## Task 11: C10 — Cobertura, originalidade e aprovação editorial integral

**Files:** completar `docs/CONCURSOS-COBERTURA.md`, canônico e teste editorial; criar `tools/check-contest-originality.mjs`, `tools/test/contest-originality.test.mjs`; relatórios privados em `artifacts/concursos-bb2026/editorial`.

**Interfaces:** consome T1/C0–C9; produz catálogo integral revisado para T2. Exportar `findSourceMatches(text:string,sources:{id:string,text:string}[]):{sourceId:string,start:number,tokenCount:number}[]`, com posições por token no texto autoral normalizado e coincidências máximas, e `collectAuthoredText(root:unknown):string`, que reúne campos pedagógicos/notas/questões/tarefas, excluindo URLs/metadados das referências. CLI na raiz: `node tools/check-contest-originality.mjs --sources 'C:\Users\glaub\OneDrive\Documentos\ChatGPT\EstudaAi\artifacts\concursos-bb2026\source-analysis' --report 'artifacts/concursos-bb2026/editorial/originality-report.json'`. Ler apenas `source-01.txt`…`source-08.txt`; nenhum relatório privado vira asset.

- [x] Adicionar `full_catalog_ready`, com `r=verifyContestContent(root,{})`, `v=verifyContestMetadata(root)` e `assert.deepEqual([r.modules,r.questions,r.writingTasks,v.lessons],[126,756,6,18])`; ambos errors=[] e nove disciplinas/IDs/objetivos/itens ligados a conteúdo/prática. No teste do detector, `phrase='um dois tres quatro cinco seis sete oito nove dez onze doze'` e `assert.equal(findSourceMatches(phrase,[{id:'s',text:phrase}]).length,1)`; variações de caixa/espaços/pontuação preservam o resultado, coincidência menor que12 não aparece.
- [x] Rodar testes novos antes do detector; constatar falha da função ausente. O teste integral do catálogo pode já passar após C9; registrar esse resultado sem fabricar uma falha.
- [x] Implementar detector que normaliza Unicode/caixa/espaços/pontuação e sinaliza coincidências de pelo menos 12 tokens consecutivos com as oito extrações, sem alterar textos automaticamente. Importar suas funções nos testes não executa a CLI/leitura de fontes privadas. Listar fonte e posição no relatório ignorado; revisar correspondências manualmente e reescrever dependência expositiva real. Manter justificativa para coincidência técnica comum; não alegar garantia universal.
- [x] Revisar cada linha de cobertura e cada um dos 756 gabaritos/comentários: explicação suficiente, caso novo, resposta única, distratores e objetivos efetivos; conferir precisão/datas das normas, passagens próprias e seis tarefas de escrita. Corrigir materiais que só repetem definições. Registrar o que foi revisado e não fabricar selo/resultado de auditoria.
- [x] Rodar `node --test tools/test/contest-content.test.mjs tools/test/contest-editorial.test.mjs tools/test/contest-originality.test.mjs`, `node tools/verify-contest-content.mjs --all`, detector nas fontes privadas e oráculos numéricos: exit0, matriz completa e correspondências editoriais resolvidas. A verificação mecânica complementa, não substitui, a leitura editorial.
- [x] Commit dos arquivos C10: `content: concluir cobertura e revisao do material de concursos`. Liberar T2 somente com esses resultados; revisão independente do conjunto ocorre em T8, sem nova confirmação rotineira do usuário.

## Auto-revisão

Cada disciplina do mapa tem tarefa, contagem e destino próprios. C0 cobre vídeos/status; C1–C9 cobrem os conteúdos ausentes nas apostilas e as condições de autoria; C4/C7 têm oráculos independentes; C10 confere integralidade/similaridade sem promessa de garantia. T1 mantém a distinção entre disciplina isolada em produção e catálogo integral disponível. O plano principal define tipos, campos, rotas, integração e revisão final, evitando decisões divergentes de schema.
