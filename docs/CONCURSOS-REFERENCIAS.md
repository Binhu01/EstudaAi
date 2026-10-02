# Análise das referências — Concursos / Banco do Brasil 2026

Registro de pesquisa de 01/10/2026. A estrutura modular, a [especificação escrita](superpowers/specs/2026-10-01-concursos-bb2026-design.md) e os dois planos de implementação foram aprovados pelo usuário. A autoria e implementação estão em andamento.

## Intenção confirmada

Criar uma área separada de Concursos dentro do Estuda Aí, inicialmente com a trilha Banco do Brasil 2026. Preservar a experiência de aulas, desafios individuais em estilo 8 bits e Steve. O usuário exige explicações, exemplos e questões totalmente autorais, usando as apostilas somente como referência dos assuntos. Confirmou ampliar a preparação para Matemática Financeira, Informática e Redação, além das seis disciplinas iniciais; posteriormente forneceu os dois PDFs adicionais.

## Referências fornecidas

Foram extraídos os textos dos oito PDFs, totalizando 99 páginas (83 com texto extraído). Páginas com fórmulas foram renderizadas e conferidas para distinguir falhas da extração de lacunas visíveis. A análise textual permanece em artifacts, ignorada pelo Git, e não será usada como conteúdo de distribuição.

| Disciplina | Páginas | Recorte observado |
| --- | ---: | --- |
| Conhecimentos Bancários | 14 | SFN, mercados, política monetária, mercado de capitais e LGPD |
| Atualidades do Mercado Financeiro | 8 | Internet Banking e Open Banking |
| Língua Portuguesa | 20 | Leitura, classes, pontuação, concordância e regência |
| Matemática | 10 | Razão, proporção e porcentagem |
| Língua Inglesa | 9 | Vocabulário, gramática introdutória e estratégias de leitura |
| Vendas e Negociação | 16 | Estratégia, experiência/valor, qualidade e ética |
| Matemática Financeira | 8 | Juros simples e amortização; comparação breve com juros compostos |
| Informática | 14 | E-mail, sistemas operacionais, aplicativos de escritório, redes sociais e arquivos |

## Precisão e cobertura

As referências são introdutórias. A ampliação precisa complementar os assuntos ausentes, sem afirmar que os PDFs já representam o programa completo. O Anexo III do edital 2022/001 de Agente Comercial serve como referência histórica; não como edital de 2026.

Foram identificadas, entre outras, simplificações na estrutura do SFN e na LGPD, tratamento histórico de Open Banking e depósitos remunerados, confusão entre regência e concordância, regras gramaticais excessivamente gerais, condições ausentes em razões e conversões de taxas e terminologia incorreta de protocolos de e-mail. A fórmula da prestação Price aparece visualmente vazia; outras fórmulas financeiras estavam presentes em imagens e apenas não foram extraídas. Os exemplos dessa fonte serão descartados na autoria, com cálculos independentes e hipóteses explícitas nos novos casos.

## Orientação editorial proposta

- Organização própria por objetivos de aprendizagem, pré-requisitos e aplicação; não repetir a sequência expositiva das apostilas.
- Módulos com explicação nova, exemplo resolvido inédito, pontos de atenção, síntese e exercícios comentados.
- Textos originais também para interpretação em Português e Inglês. Questões devem exigir raciocínio e evidência, com uma única alternativa correta e justificativa.
- Cálculos financeiros devem declarar regime, unidades, datas de pagamento e hipóteses de encargos; conferir resultados por método independente.
- A preparação de Redação incluirá planejamento, tese, argumentos, coesão e revisão. Orientação do Steve não será apresentada como nota oficial de banca.
- Videoaulas externas complementares identificadas com autor/canal, sem alegar autoria da Estuda Aí.
- Fontes oficiais e data de revisão para normas e informações que mudam. Não fixar taxa corrente, cronograma, vagas, banca ou condições de um futuro edital sem confirmação.
- Material e questões terão autoria e identidade visual da Estuda Aí; não distribuir as apostilas ou seus elementos visuais.

## Evidências oficiais consultadas

- [Comunicado do Banco do Brasil de 03/06/2026](https://imprensa.bb.com.br/bb-esclarece-que-nao-ha-previsao-de-novo-concurso-2/): texto confirmado novamente em 01/10/2026; informa ausência de previsão de novo edital. Essa informação datada não permite afirmar que uma publicação futura é impossível.
- [Edital histórico 2022/001](https://www.bb.com.br/docs/portal/dipes/Edital-de-Abertura-de-Selecao-Externa-2022-01.pdf): referência de Agente Comercial e da prova de Redação.
- [BCB — estrutura do SFN](https://www.bcb.gov.br/en/financialstability/nationalfinancialsystem), [Open Finance](https://www.bcb.gov.br/meubc/faqs/s/open-finance) e [política monetária](https://www.bcb.gov.br/controleinflacao).
- [CVM — ofertas primárias e secundárias](https://www.gov.br/investidor/pt-br/investir/como-investir/ofertas-publicas-de-distribuicao/oferta-primaria-x-secundaria).
- [LGPD compilada](https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709compilado.htm), [Lei 15.352/2026](https://www.planalto.gov.br/ccivil_03/_ato2023-2026/2026/lei/l15352.htm) e [CDC compilado](https://www.planalto.gov.br/ccivil_03/leis/l8078compilado.htm).
- [British Council — perguntas e negativas](https://learnenglish.britishcouncil.org/free-resources/grammar/english-grammar-reference/questions-negatives) e [possessivos](https://learnenglish.britishcouncil.org/free-resources/grammar/english-grammar-reference/possessives-pronouns).

## Referências complementares para autoria

- Bancários/atualidades: [SFN](https://www.bcb.gov.br/estabilidadefinanceira/sfn), [CET — CMN 4.881](https://www.bcb.gov.br/estabilidadefinanceira/exibenormativo?numero=4881&tipo=Resolu%C3%A7%C3%A3o+CMN), [legislação cambial](https://www.bcb.gov.br/estabilidadefinanceira/legislacaocambial), [instituições de pagamento](https://www.bcb.gov.br/estabilidadefinanceira/instituicaopagamento), [metas de inflação](https://bcb.gov.br/controleinflacao/historicometas), [ética BB](https://ri.bb.com.br/o-banco-do-brasil/etica/).
- Direito/proteção: [PLD — Lei 9.613](https://www.planalto.gov.br/ccivil_03/leis/l9613.htm), [sigilo — LC 105](https://www.planalto.gov.br/ccivil_03/leis/lcp/lcp105.htm), [anticorrupção — Lei 12.846](https://www.planalto.gov.br/ccivil_03/_ato2011-2014/2013/lei/l12846.htm), [LBI](https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2015/lei/l13146.htm).
- Português: [VOLP/ABL](https://www.academia.org.br/nossa-lingua/vocabulario-ortografico), [crase](https://www12.senado.leg.br/manualdecomunicacao/estilos/crase), [concordância verbal](https://www12.senado.leg.br/manualdecomunicacao/estilos/concordancia-verbal), [Ensino de gramática — USP](https://sce.fflch.usp.br/sites/sce.fflch.usp.br/files/Ensino_Gramatica%20ebook-compactado.pdf).
- Inglês: [British Council — relativas](https://learnenglish.britishcouncil.org/free-resources/grammar/english-grammar-reference/relative-pronouns-relative-clauses), [condicionais](https://learnenglish.britishcouncil.org/free-resources/grammar/b1-b2/conditionals-zero-first-second).
- Matemática: [IMPA/OBMEP — contagem](https://portaldaobmep.impa.br/index.php/modulo/ver?modulo=15&tipo=7), [OpenStax — funções](https://openstax.org/books/college-algebra-2e/pages/3-1-functions-and-function-notation), [matrizes](https://openstax.org/books/college-algebra-2e/pages/7-5-matrices-and-matrix-operations), [progressões](https://openstax.org/books/college-algebra-2e/pages/9-4-series-and-their-notations).
- Informática: [CERT.br](https://cartilha.cert.br/fasciculos/), [Microsoft — guias Office 2013](https://www.microsoft.com/en-us/copilot/blog/2013/02/04/download-our-free-office-2013-quick-start-guides/), [openSUSE 42.1 arquivado](https://doc.opensuse.org/documentation/leap/archive/42.1/startup/html/book.opensuse.startup/index.html), [lançamento 42.1](https://news.opensuse.org/2015/11/04/opensuse-leap-42-1-becomes-first-hybrid-distribution/), [SMTP](https://www.rfc-editor.org/info/rfc5321/), [POP3](https://www.rfc-editor.org/info/rfc1939/), [IMAP4rev2](https://www.rfc-editor.org/info/rfc9051/), [HTTP](https://www.rfc-editor.org/rfc/rfc9110.html).

O openSUSE Leap 42.1 tinha Plasma 5.4.2 como padrão. O recorte KDE 4 é histórico e distinto; não será apresentado como padrão dessa distribuição. Interfaces Office 2013/Windows 10 serão contextualizadas conforme o edital anterior, sem recomendação de instalação de versões antigas. Os vídeos e seus autores estão identificados no catálogo; anos de títulos não confirmam novo edital. Disponibilidade observada por oEmbed, sem promessa de reprodução.

O [mapa detalhado](CONCURSOS-MAPA-CURRICULAR.md), a [cobertura editorial](CONCURSOS-COBERTURA.md) e os contratos orientam a entrega aprovada.
