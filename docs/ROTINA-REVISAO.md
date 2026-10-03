# Revisão da rotina de estudo — 03/10/2026

Revisão independente somente leitura de `ed17772..b2ccb83`, realizada ao final da execução direta. A primeira tentativa terminou por limite de uso antes de produzir revisão; foi retomada uma única revisão do conjunto. O revisor leu contratos, código e evidências existentes; não reexecutou as suítes. Reproduziu o problema de datas com o modelo Dart compilado para JavaScript em uma pasta temporária, sem alterar o checkout. O autor confirmou os achados antes de decidir sua prioridade.

## Achado importante e correção

Datas consecutivas eram convertidas em meia-noite no fuso do dispositivo. No início do horário de verão, a distância entre duas datas pode ser 23 horas, e `difference().inDays` rejeitava sete dias civis válidos. Isso impedia carregar todo o painel.

A regressão Web usa atividade de 03 a 09/03/2026, dispositivo em `America/New_York` e meta em `America/Sao_Paulo`. O build anterior rejeitou o dashboard e não mostrou seu progresso. A correção interpreta as datas de calendário em UTC apenas para validar formato e continuidade; o servidor continua definindo o dia de estudo em São Paulo. Os outros dois tamanhos mantêm o fuso São Paulo e a semana que atravessa setembro/outubro. O teste consta de `tools/verify-routine.mjs`; relatório identifica fuso, datas e transporte controlado.

Não houve nova revisão após a correção. A regressão passou: 30 percursos nos três tamanhos, zero erro interno. Após a correção, passaram também API84/84, ferramentas29/29 e Flutter101/101;113 arquivos sem alteração de formatação, análise limpa e novo build Web release. Os demais checks da Task8 foram preservados e estão registrados em [Validação](VALIDACAO.md).

## Ajuste menor adiado

- O enum OpenAPI do catálogo atual também restringe `StudyAnswerDto`, `ConfirmedAnswerDto` e `StudyErrorItemDto`. Identidades removidas continuam aceitas no reenvio de uma confirmação histórica e no caderno `outdated`, mas deixam de satisfazer esse enum publicado. O cliente Flutter atual aceita esses registros. Ajuste adiado: usar formato de identificador nas estruturas históricas e documentar que o catálogo atual valida somente novos eventos. Risco: incompatibilidade de futuros clientes ou validadores gerados; não foi identificado bloqueio no cliente entregue.

## Decisões e limites

1. **Task2 — RED das projeções SQL.** Não foi executada uma falha RED isolada das projeções antes da implementação. Os agregados e a paginação passaram no PostgreSQL real; ausência das rotas foi observada em RED. Mantive a evidência descrita sem inventar esse teste inicial. Custo se errado: evidência mais fraca de que os oráculos detectariam ausência das projeções.
2. **Firebase e Steve reais.** Mantive a implementação e os testes controlados, com comprovação externa pendente, conforme o escopo aprovado para serviços ainda ausentes. O produto não oferece conta ou IA simulada. Custo se errado: problemas de configuração, login ou respostas podem aparecer quando os provedores forem ativados.
3. **Outras plataformas e operação.** Docker, publicação, builds nativos, leitor de tela real e carga comercial permanecem sem homologação nesta entrega. A evidência cobre Flutter Web, testes de layout/semântica/teclado e banco local dedicado. Custo se errado: falhas específicas dessas plataformas, acessibilidade ou escala podem surgir fora do ambiente testado.
4. **Conteúdo autoral.** O catálogo foi preservado nesta branch e seu verificador integral passou; não repetimos a revisão editorial independente integral da entrega anterior. Custo se errado: eventuais problemas editoriais herdados podem continuar presentes.

Nenhum achado crítico foi encontrado. A gravação atômica, bloqueio por meta, propriedade composta, confirmação original em retry, mapeamento canônico das alternativas e cancelamento por gerações foram considerados consistentes pela revisão. Isso não substitui as limitações externas acima.
