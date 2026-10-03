# Rotina diária e caderno de erros

Abra **Meu estudo** pelo cabeçalho do celular ou pela navegação em telas maiores. Sem conta, a página oferece login; aulas e desafios públicos continuam disponíveis.

## Seu estudo de hoje

Escolha Estudo livre ou Banco do Brasil. Cada área tem sua meta interna, histórico e alvo diário independente:5,10 ou20 questões diferentes. O padrão é10.

Responder a mesma questão três vezes conta uma questão diferente e três tentativas. Acertos são as respostas corretas confirmadas, sem transformar tentativas em domínio. O servidor determina o resultado e horário; o dia usa `America/Sao_Paulo`. Os sete dias incluem dias com zero atividade. O desempenho por assunto/disciplina considera o histórico da versão atual; não fabrica XP, tempo estudado ou sequências.

O botão de continuidade abre o último assunto com resposta confirmada. Quando ainda não há histórico, oferece começar um desafio. O alvo só muda após confirmação do servidor; uma falha mantém o valor anterior.

## Seu caderno

**Revisar meus erros** abre o caderno. Filtre pendentes ou revisados e um assunto/disciplina. A lista carrega20 registros por vez, com botão para continuar, e mantém ordenação recente com desempate estável.

Uma resposta errada abre ou reabre a questão. Na revisão, alternativas aparecem antes do comentário. Após escolher, a resposta fica travada e mostra a explicação. Somente um acerto confirmado marca **Revisado**. Errar novamente mantém a pendência. Revisado indica uma resposta correta registrada, sem afirmar domínio da matéria.

Material, videoaulas e Steve mantêm o módulo selecionado. Material autoral aparece para módulos de Concursos; os assuntos livres oferecem suas aulas. Registros de versões antigas ficam separados e oferecem conteúdo atual, sem tratar a questão nova como se fosse a antiga.

Rotas Web: `/#/meu-estudo`, `/#/meus-erros`, `/#/meus-erros/:topicId/:contentVersion/:questionId`.

## Confirmação, saída e privacidade

Quando há conta, cada resposta do quiz é enviada separadamente. Um identificador único acompanha a mesma resposta em todo reenvio. O servidor impede duplicação e grava evento/caderno na mesma transação.

Se não chegar confirmação: “Não foi possível confirmar o registro desta resposta. Tente novamente ou continue estudando.” **Tentar novamente** reenvia o mesmo intento; **Continuar estudo** permite avançar ou voltar ao caderno. A falha não prova que o servidor deixou de salvar. Continuar abandona a espera, sem prometer desfazer uma gravação.

Sair ou trocar de conta/área cancela pedidos e descarta resultados antigos. Tokens, dados privados e respostas pendentes não ficam em disco. Recarregar exige login novamente; não há fila offline ou importação de recordes anônimos. A pontuação local do desafio permanece independente do histórico por conta.

## Configuração e evidência

Veja [Configuração](ROTINA-CONFIGURACAO.md) para banco local, Firebase e OpenAI. A integração do histórico tem testes SQL/HTTP, PostgreSQL real e aplicativo Web. `test:routine` usa transportes controlados exclusivamente no teste, com contas distintas, confirmação perdida e ambas as áreas. Ele não comprova autenticação externa ou IA ao vivo. O roteiro separado `verify:live` permanece pendente até os provedores serem configurados.

Os [resultados e limites](VALIDACAO.md) identificam o que foi realmente executado. Android, iOS, Windows nativo, Docker e deploy não foram homologados nesta etapa.
