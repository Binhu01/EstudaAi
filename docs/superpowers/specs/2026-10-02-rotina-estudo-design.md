# Rotina de estudo — login/Steve, painel diário e caderno de erros

## Pedido e resultado esperado

O usuário escolheu começar pelas três melhorias propostas: login e Steve validados, painel diário e caderno de erros. O aluno deve entrar na conta, estudar no contexto escolhido, ver atividade realmente registrada e revisar suas respostas erradas. Estudo livre e Banco do Brasil permanecem separados. Esta entrega integra esses recursos por uma única base de histórico por aluno e meta de estudo.

Em 02/10/2026, o usuário informou que ainda não possui Firebase, acesso à API da OpenAI ou PostgreSQL. Não foram encontrados arquivos `.env` no checkout principal ou no worktree, nem as variáveis necessárias no processo. Preparar configuração e testes é parte da entrega; comprovar login e respostas reais depende da ativação desses serviços. Essa pendência não será apresentada como validação concluída.

Base: `ed177722a93fd91ba4acd7b20a9d1a2637c2fc1f`. Branch de trabalho: `codex/rotina-estudo`, separada da branch do PR de Concursos. Flutter/Riverpod, NestJS, Prisma/PostgreSQL, Firebase e Responses são reutilizados. O conteúdo autoral, a área Concursos e o quiz 8 bits continuam sendo a base da experiência.

## Abordagem escolhida

O servidor guarda o histórico confirmado por conta. Salvar apenas no dispositivo seria mais simples, mas não permitiria consultar o mesmo caderno em outro dispositivo. Uma fila offline persistente acrescentaria sincronização e conflitos; nesta primeira versão, falhas têm reenvio explícito ou a opção de continuar sem salvar. O feedback da questão continua imediato.

Reutilizar as integrações atuais de conta/Steve é preferível a introduzir outro provedor. A implantação inicial pode usar PostgreSQL local persistente, sem exigir hospedagem de banco para testar a experiência. A configuração externa será guiada por documentação e diagnóstico local que informa apenas presença/validade das configurações, sem imprimir segredos.

## Conta e validação do Steve

- Reutilizar cadastro, login, recuperação, renovação, perfil e saída existentes. O backend continua verificando a identidade Firebase antes de conceder acesso a dados privados.
- Preparar o ambiente local, as migrações e um roteiro reproduzível de cadastro/login, renovação e saída. Conferir origens da prévia e conexão com o banco. A execução deve detectar configuração ausente antes de tentar chamadas reais.
- Quando os serviços forem configurados, validar o Steve com três perguntas educativas reais, incluindo Estudo livre e Concursos, conferir o contexto e o saldo retornado pelo servidor. Respostas de testes controlados não contam como respostas reais.
- Credenciais ficam no ambiente local/backend e fora do Git e do Flutter. O diagnóstico não imprime chaves, senhas, tokens ou textos privados de conversa.
- A sessão permanece em memória nesta entrega. Recarregar exige entrar novamente, mas o histórico confirmado é recuperado da conta. Persistência de credenciais e alteração da autenticação para cookies ficam fora deste escopo.
- A mensagem exibida ao aluno em falha deve oferecer recuperação compreensível, sem mostrar instruções de administração do servidor.

## Contexto e dados privados

As regras da fundação são mantidas: cada registro privado contém `userId` e `studyGoalId`, com propriedade composta verificada pelo banco e pelo caso de uso. O proprietário é derivado da sessão; o cliente não o escolhe.

Provisionar idempotentemente uma meta interna para `freeStudy` e outra para `bb2026`, por usuário. Uma chave interna opcional e única permite preservar metas anteriores e preparar expansão futura, sem criar um CRUD genérico agora. Cada meta começa com fuso `America/Sao_Paulo` e alvo diário de dez questões diferentes, ajustável para cinco, dez ou vinte.

Uma resposta confirmada registra identificador idempotente, meta, assunto/módulo, versão do conteúdo, questão, alternativa canônica e origem `quiz` ou `review`. O servidor valida o vínculo pelo `StudyDirectory`, calcula o acerto pelo catálogo e define o horário UTC. Não aceita acerto, pontos, proprietário ou horário enviados pelo cliente.

Alternativas são embaralhadas no quiz atual. O cliente deve preservar a correspondência entre alternativa exibida e índice canônico; a gravação nunca usa o índice embaralhado como se fosse o original.

O mesmo identificador com o mesmo corpo devolve a confirmação original. Reutilizá-lo com corpo ou contexto diferente resulta em conflito, sem nova contagem. Inserção do evento e atualização do caderno são uma única transação, serializada por meta para manter ordem e consistência entre dispositivos. Chamadas de Firebase/IA não fazem parte dessa transação.

Não importar automaticamente recordes locais ou respostas anônimas para uma conta. Histórico de versão antiga é preservado, mas não se mistura ao desempenho e às revisões da versão atual. Conteúdo desatualizado mostra uma recuperação para o módulo atual quando disponível.

## Painel “Seu estudo de hoje”

Entrada própria no aplicativo, com atalhos nas áreas existentes. Mostra a meta ativa e permite alternar Estudo livre/Banco do Brasil sem combinar os resultados.

Para aluno autenticado, apresentar:

1. Questões diferentes confirmadas hoje e progresso até o alvo diário. Repetir a mesma questão no mesmo dia não aumenta esse indicador; tentativas continuam registradas.
2. Acertos e total de tentativas confirmadas hoje, com rótulo explícito de tentativas.
3. Quantidade de erros pendentes e ação “Revisar meus erros”.
4. “Continuar último assunto praticado”, usando a última resposta confirmada e uma rota válida do catálogo.
5. Desempenho por disciplina/assunto na versão atual, como acertos sobre tentativas registradas, sem chamar essa métrica de domínio.
6. Atividade dos últimos sete dias civis no fuso da meta, incluindo dias sem atividade.

O servidor determina “hoje” pelo fuso da meta, não pelo relógio enviado pelo cliente nem pela data UTC isolada. Sem histórico, a tela apresenta uma orientação para iniciar o primeiro desafio; não inventa sequências, porcentagens de aprendizagem ou minutos estudados. Sem conta, apresenta acesso ao login. Carregamento, falha com nova tentativa e ausência de dados são estados diferentes.

## Caderno de erros

Uma linha por meta, assunto/módulo, versão e questão registra primeiro/último erro, quantidade de erros, última resposta confirmada e estado `pending` ou `reviewed`.

Uma resposta errada cria ou reabre o item pendente. Uma resposta correta confirmada em quiz ou revisão o marca como revisado. “Revisado” significa o último acerto registrado, sem certificar domínio ou retenção. Identificadores idempotentes repetidos não alteram contagens ou estado.

A tela mostra pendentes por padrão, permite consultar revisados e filtrar disciplina/assunto. Ordenar pendentes pelo último erro, mais recente primeiro, com desempate estável. Paginação de vinte itens, máximo de cinquenta por página.

Ao abrir a revisão, o aluno responde antes de ver o comentário e a alternativa correta. A revisão usa a mesma confirmação de resposta, com origem `review`. Oferece retorno ao material quando houver, às aulas e ao Steve no contexto da questão. O caderno não tem ação que simplesmente marque um erro como resolvido sem responder.

Programação espaçada, notificações, flashcards, simulados e algoritmo adaptativo ficam para uma etapa posterior. A primeira versão entrega o caderno e a prática dos erros com métricas reais.

## Registro e falhas no cliente

O registro de cada resposta ocorre quando o aluno responde, mesmo se abandonar a rodada depois. O UUID é gerado uma vez nesse toque e reutilizado nas novas tentativas de envio. A escolha trava e o comentário aparece imediatamente; avançar aguarda a confirmação ou uma decisão explícita em caso de falha.

Em falha, mostrar “Tentar novamente” e “Continuar sem salvar”, explicando que aquela resposta ainda não entrou no painel ou no caderno. Continuar sem salvar abandona o envio, sem afirmar sincronização futura. Não criar uma fila offline silenciosa.

Capturar usuário, meta e geração da sessão no toque. Cancelar e descartar respostas de requisições antigas em saída, troca de conta ou contexto. Antes de obter o token e antes de enviar, conferir que o contexto original continua ativo. Nunca reenviar uma resposta da conta anterior na nova conta.

O quiz anônimo continua disponível e conserva seu recorde local. O histórico privado e o caderno exigem conta. Pontuação de rodada e recorde local permanecem separados das métricas confirmadas de estudo.

## Fronteiras da API

| Rota proposta | Responsabilidade |
| --- | --- |
| `POST /v1/study-contexts/:scope/ensure` | Obter/criar a meta interna autorizada para `freeStudy` ou `bb2026` |
| `PATCH /v1/goals/:goalId/daily-target` | Selecionar cinco, dez ou vinte questões diferentes por dia |
| `PUT /v1/goals/:goalId/answers/:answerId` | Confirmar uma resposta idempotente, validar identidade canônica e atualizar o caderno |
| `GET /v1/goals/:goalId/dashboard` | Resumo diário, atividade, desempenho e último assunto confirmado |
| `GET /v1/goals/:goalId/errors` | Lista paginada por estado e disciplina/assunto |

Todas as rotas exigem autenticação, validação estrita, limites de requisições e vínculo entre proprietário, meta e catálogo. Respostas cruzadas de outra meta/usuário são recusadas. Contrato OpenAPI, modelos do cliente e migrações acompanham a implementação. Cache do cliente usa usuário/meta/recurso/parâmetros, conforme a fundação.

## Critérios de aceitação

- Dois usuários e duas metas do mesmo usuário não conseguem ler/gravar histórico cruzado; saída e troca de conta/contexto não reutilizam dados ou respostas pendentes.
- Índices embaralhados são convertidos corretamente em opções canônicas. Questão inválida, versão antiga, meta incompatível e propriedades extras são recusadas.
- Reenvio após confirmação perdida não duplica dados. Reutilização incompatível de UUID resulta em conflito. Gravações concorrentes preservam contagens e a ordem do caderno.
- Uma rodada interrompida conserva respostas já confirmadas. Falhas e “Continuar sem salvar” não criam resultados fictícios.
- Meta diária conta questões diferentes; acertos contam tentativas. Passagem da meia-noite UTC e da meia-noite no fuso da meta têm testes com relógio controlado.
- Erro → acerto → novo erro produz pendente → revisado → pendente. A revisão não marca domínio.
- Telas são utilizáveis em 360×800, 768×1024 e 1440×1000, com texto a 200%, teclado, estados acessíveis e tema existente. Navegação conserva área/módulo ao ir para conta ou Steve.
- Migração preserva dados anteriores; testes em PostgreSQL real validam isolamento, idempotência e concorrência. Executar testes pertinentes, análise, builds e percursos de navegador; registrar limites sem misturar testes controlados e serviços reais.
- Validar login e Steve ao vivo somente após a configuração externa. Até lá, registrar claramente essa pendência e entregar o roteiro preparado, sem contas ou respostas simuladas no produto.

## Limites da entrega

O escopo é configuração/validação de conta e Steve, painel diário e caderno de erros. Não altera conteúdo das apostilas, não amplia o banco de questões e não cria ranking, Premium, simulados, editor de Redação ou publicação. Esta especificação aguarda revisão do usuário antes do plano e da implementação; o método de execução direta com uma revisão final, já escolhido na conversa, permanece a preferência.
