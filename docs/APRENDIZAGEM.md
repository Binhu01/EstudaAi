# Experiência de aprendizagem integrada

O fluxo reúne conteúdo → desafio → explicação → revisão → próximo passo, preservando estudo livre e preparação Banco do Brasil em contextos separados.

## Painel diário

Meu estudo destaca a quantidade de questões diferentes que falta para a meta, o último assunto com resposta confirmada e ações para retomar o material/videoaulas, praticar ou abrir pendências. Continuar estudando retoma o assunto, não uma posição de leitura ou vídeo. A meta continua em 5, 10 ou 20 questões e só muda após confirmação do servidor.

Cobertura conta questões distintas praticadas na versão atual. O desempenho por matéria distingue cobertura, resultado da última resposta de cada questão e acertos em todas as tentativas. Dias ativos e sequências usam o calendário America/Sao_Paulo; a sequência atual pode terminar ontem, para permitir estudar hoje. Dados de outras contas, áreas, versões e datas futuras ficam fora dos indicadores.

Os marcos são derivados dos registros confirmados: primeira prática, primeiro acerto em revisão, três dias seguidos e um alvo de questões distintas adequado ao catálogo. Não há XP global, ranking ou afirmação de domínio. Cliente antigo/servidor sem o campo adicional não apresenta valores fictícios.

## Caderno e desafios

O resultado de um desafio mantém as alternativas escolhidas e comenta as questões erradas. Erros confirmados de alunos conectados entram no caderno; respostas anônimas não são importadas posteriormente.

Entender esta questão mostra a última resposta registrada, alternativa correta e explicação sem criar nova tentativa. O comentário só usa uma questão da mesma versão do catálogo.

Revisar até 5 erros inicia uma rodada com as pendências atuais do filtro. Cada resposta mostra sua explicação e exige confirmação antes de avançar. Reenvio conserva o mesmo identificador. Se a confirmação falhar, é possível tentar novamente ou pular sem prometer cancelar uma eventual gravação. Questões indisponíveis podem ser puladas. O resumo diferencia acertos confirmados, erros confirmados e itens não revisados na rodada.

A rodada é temporária, vinculada à conta/sessão/área. Sair ou trocar a conta invalida o resumo e impede usar a fila anterior. Recarregar a rota pede abrir uma nova rodada no caderno; as respostas já confirmadas permanecem no servidor.

## Leitura e navegação

O material autoral oferece três tamanhos de texto e espaço adicional entre linhas. As preferências ficam no dispositivo, se somam à escala de acessibilidade e afetam somente a leitura. As fontes e a interface preservam o sistema visual existente. A coluna de leitura tem até 760 px úteis.

Material e videoaulas oferecem módulo anterior/seguinte no rodapé, sem sair da disciplina e mantendo a ação selecionada. Os limites da sequência ficam desativados.

## Steve

O backend fornece o conteúdo autoral do módulo: objetivos, pré-requisitos, explicações, fórmulas/variáveis/condições, exemplos, tabelas, revisões e propostas de redação. Instruções e contexto têm orçamento máximo de 16.000 caracteres; regras de privacidade e tutoria permanecem antes do material. O banco de respostas do quiz não é fornecido ao tutor.

Vídeos têm somente metadados, sem transcrição ou posição de reprodução. Steve não recebe progresso pessoal e não deve inventar números nem notas oficiais.

A autenticação Firebase e o banco já estão configurados. A ativação e a validação de respostas reais da OpenAI continuam pendentes por escolha do usuário. Não há resposta de IA simulada.

## Verificação

Foram adicionados testes para resumo de erros, rodada com reenvio idempotente, saída da conta, questão indisponível, consulta de explicação sem gravação, leitura ampliada, navegação, persistência de preferências, cobertura, sequência e datas futuras. A validação inclui os conjuntos completos da API e Flutter, análise do cliente, compilação web e conferência no navegador. A evidência final e os limites ficam no relatório da entrega. Builds nativos e deploy não fazem parte desta alteração.
