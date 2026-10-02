# Experiência de estudo

A área [Concursos](CONCURSOS.md) amplia esta experiência com a preparação Banco do Brasil, mantendo seleção, material, aulas, desafio e Steve por módulo. Cada área lembra seu assunto; Conta e Preferências preservam a seleção. Os destinos livres descritos abaixo continuam disponíveis.

## Percurso

Escolha Porcentagem, Interpretação de texto ou Ecologia na Home. Aprender, Desafios e Steve reutilizam esse assunto. Um endereço com assunto desconhecido mostra recuperação, sem alterar o contexto. O hero usa fotografia local creditada em [Mídia](MIDIA.md), texto animado curto e detalhe shader com controle de movimento.

Cada assunto contém duas videoaulas, notas, fonte de aprofundamento e dez questões autorais no catálogo canônico. O player YouTube é carregado somente ao escolher uma aula, sem reprodução automática. Disponibilidade, anúncios, políticas de incorporação e conectividade são externos. “Abrir no YouTube” permanece disponível como alternativa; nos aplicativos nativos, a aula abre externamente.

## Desafios individuais

Cada rodada sorteia cinco questões sem repetição e embaralha alternativas. A primeira escolha trava a questão e mostra gabarito/explicação; somente então é possível avançar. Um acerto vale100 pontos e bônus de20 por acerto anterior consecutivo, até80; erro quebra a sequência. Cinco acertos seguidos totalizam700.

O recorde é salvo neste dispositivo por assunto e versão do catálogo. Repetir preserva o maior resultado; trocar de assunto abandona a rodada. O resultado pode levar à aula do mesmo tópico. Não há cronômetro, sala ao vivo, XP global, ranking compartilhado ou sincronização de recordes. Ícones/formas, texto e estados explicam o resultado além das cores. Fonte pixel e avatar original são usados nos detalhes do jogo.

## Conta e Steve

Cadastro, entrada, recuperação de senha e refresh usam o backend com Firebase Email/Password. O backend verifica o ID token pelo Admin antes de aceitar a sessão. Tokens e conversa ficam apenas em memória. Logout/troca de conta remove dados e cancela chamadas; fechar/recarregar exige entrar novamente. Recuperação usa confirmação genérica para não revelar existência de conta.

Steve responde perguntas sobre a plataforma e matérias no assunto selecionado. Sugestões preenchem o campo, sem enviar automaticamente. A pergunta aceita até2.000 caracteres. Apenas uma chamada pode ficar pendente; “Nova conversa” limpa a conversa e cancela o pedido. Trocar assunto, inclusive ir e voltar, descarta respostas antigas. Não há streaming nem repetição automática.

O histórico enviado contém até quatro pares concluídos e no máximo12.000 caracteres. Pares com resposta acima de2.000 caracteres e respostas incompletas/recusadas permanecem visíveis, mas não entram no contexto seguinte. O texto é apresentado sem executar HTML/Markdown; as fontes clicáveis são as do catálogo, verificadas separadamente. Uma resposta incompleta é identificada, inclusive se o provedor não fornecer texto.

Configure no servidor `OPENAI_API_KEY` junto com `STEVE_MODEL`; não há modelo padrão escolhido silenciosamente. A API usa Responses, `store:false`, até800 tokens de saída e prazo30s. Alguns modelos podem consumir o orçamento em raciocínio e responder incompleto. `store:false` desativa armazenamento recuperável de Responses; não constitui promessa geral de ausência de retenção pelo provedor.

Há limite3 mensagens/minuto por usuário e uma chamada simultânea por instância, além da cota diária persistida (padrão10 por usuário/1000 global). A reserva é transacional no PostgreSQL e renova à meia-noite UTC. Só cancelamento antes do envio ao provedor devolve a reserva; timeout posterior pode consumir cota. A UI exibe somente saldo confirmado pelo servidor antes de sua renovação; envio/falha ou chegada do reset retira o saldo antigo. A renovação do limite é mostrada em horário local. A interface explica que uma tentativa enviada pode consumir cota mesmo sem resposta. Falha conserva a pergunta para edição/tentativa manual, sem criar uma resposta fictícia.

## Configuração e verificação ao vivo

Siga [Instalação](INSTALACAO.md), aplique ambas as migrações e configure origem/API/Firebase/provedor. Nenhuma chave entra no build Flutter. Valide com uma conta do ambiente: acesso, refresh, logout, recuperação e três perguntas simples — “Quanto é20% de150?”, “Como diferenciar compreensão e interpretação com pistas do texto?” e “Como energia e matéria circulam no ecossistema?”. Confira explicação/fontes e quota no servidor, sem registrar conteúdo ou tokens.

Resultados efetivamente executados e limites por plataforma estão em [Validação](VALIDACAO.md). Ausência de configuração é mostrada como indisponibilidade; não se usa login, perfil ou IA de demonstração.
