# Estuda Aí — Hero, desafios 8 bits, videoaulas e Steve

Data: 30/09/2026. Estado: especificação escrita aprovada pelo usuário; plano de implementação em revisão. Implementação ainda não iniciada.

## 1. Objetivo e decisões do usuário

Transformar a fundação existente numa experiência de estudo utilizável: escolher um assunto, assistir aulas, praticar num quiz individual e tirar dúvidas com Steve. A referência visual enviada é o componente React PrismaHero, adaptado para educação na aplicação Flutter existente.

O usuário confirmou: Estuda Aí é separado da AlmaPet; o quiz é individual por assunto; Steve usa IA generativa pelo backend; a proposta inclui hero Flutter, seis videoaulas e cadastro/login por e-mail para acessar o chat. O projeto permanece em `C:\Users\glaub\OneDrive\Documentos\ChatGPT\EstudaAi`.

Esta entrega prioriza esses quatro fluxos sobre a ordem histórica das fases. Não substitui o restante dos requisitos originais, não implementa Premium, CRUD de metas, ranking multiplayer ou publicação nas lojas. A experiência inicial é identificada como **Estudo livre**: usa assuntos reais do catálogo, sem inventar uma meta ou apresentar personalização com dados inexistentes. Metas persistidas serão integradas numa entrega posterior.

## 2. Abordagem e fronteiras

| Alternativa | Benefício | Custo | Decisão |
| --- | --- | --- | --- |
| Adaptar composição e animações ao Flutter | Uma interface para Web e apps; reutiliza temas, navegação e preferências | O JSX não pode ser copiado literalmente para Dart | Escolhida e aprovada |
| Adicionar microsite React separado | Reutiliza diretamente o componente enviado | Duplica navegação e manutenção da interface | Não escolhida |
| Migrar toda a interface para React | Uniformiza referências React | Substitui a fundação e o plano multiplataforma sem necessidade | Não escolhida |

O cliente mantém Riverpod, GoRouter e Dio. A API mantém NestJS, Firebase Admin e Prisma/PostgreSQL. Novos módulos são pequenos e possuem uma responsabilidade:

- **Catálogo de estudo:** arquivo versionado com assuntos, perguntas, aulas e notas de apoio. É a fonte comum do cliente e do contexto selecionado pelo servidor; as rotinas de build empacotam o mesmo conteúdo para cada aplicação.
- **Contexto de aprendizagem:** assunto atual, modo Estudo livre e geração de cancelamento. Identidade entra na chave de contexto do Steve após login.
- **Quiz:** máquina de estados e pontuação local; não depende de IA nem de conexão para responder.
- **Mídia:** player Web e abertura externa nas plataformas nativas.
- **Sessão:** cadastro, login, renovação e saída; comunica-se somente com a origem configurada da API.
- **Steve:** valida contexto e limites, monta instruções no servidor e chama o provedor por um adaptador próprio.

Não adicionar React, shadcn, Tailwind, Framer Motion ou Lucide ao projeto Flutter. Os ícones Material existentes e as animações Flutter cumprem os papéis equivalentes da referência.

## 3. Hero e navegação

A composição preserva a referência: fotografia imersiva, navegação funcional, marca grande na parte inferior, texto de apoio e animação de entrada por palavras. O hero não será uma imagem inteira da interface; texto e botões continuam acessíveis e interativos.

- Título principal: **Estuda Aí**.
- Apoio: **Seu próximo nível começa com uma descoberta.**
- Descrição: **Escolha um assunto, aprenda com videoaulas, teste seus conhecimentos e conte com o Steve.**
- Ação principal: **Escolher meu assunto**, direcionando à seleção abaixo do hero.
- Ações da navegação: **Aprender**, **Desafios**, **Steve** e acesso a **Preferências**; todas levam a fluxos reais.
- Fotografia: estudante na biblioteca, de Zoshua Colah, [página original no Unsplash](https://unsplash.com/photos/student-studies-at-a-library-with-books-klbApl9mxr0). A origem declara uso gratuito sob a [licença Unsplash](https://unsplash.com/license). Empacotar uma versão otimizada para a aplicação e registrar o crédito. O vídeo artístico da referência não será usado como conteúdo educacional.
- O shader já solicitado permanece como detalhe no hero, atrás da composição fotográfica e sem prejudicar a legibilidade. Falha de imagem conserva a estrutura, o texto e o gradiente existente.
- Animações de entrada uma vez por exibição, com duração curta. Respeitar movimento reduzido, preferência de animação, visibilidade e ciclo de vida; sem piscadas ou movimento contínuo do texto.
- Tamanhos definidos por faixas e pelo sistema tipográfico, sem fonte proporcional ao viewport. No mobile e com texto a 200%, conteúdo refluindo e todas as ações alcançáveis. Deixar visível o início da seleção de assuntos na primeira tela quando houver altura suficiente.

Rotas propostas: `/` para hero e seleção, `/aprender/:topicId`, `/desafios/:topicId`, `/steve/:topicId`, `/conta` e a rota existente `/preferencias`. IDs desconhecidos têm estado de assunto não encontrado e ação para voltar à seleção. O assunto inicial é porcentagem; fica explicitamente selecionado e pode ser alterado. Links diretos atualizam o contexto a partir do ID validado da rota.

## 4. Assuntos e desafio individual 8 bits

Catálogo inicial: `porcentagem` (Matemática), `interpretacao-texto` (Português) e `ecologia` (Ciências/Biologia). Dez questões originais por assunto, revisadas com base nas fontes educacionais da seção 5; cinco sorteadas sem repetição a cada rodada. Os textos e perguntas são autorais, sem copiar enunciados protegidos das videoaulas.

Fluxo: escolher assunto → começar rodada → selecionar resposta → ver explicação → próxima questão → resultado → repetir ou assistir aula do mesmo assunto.

Regras inequívocas:

1. Cada questão tem exatamente quatro alternativas e uma correta. Alternativas apresentam letra/símbolo e texto; cor nunca é o único indicador.
2. A primeira seleção encerra a questão. Cliques adicionais, toques repetidos e atalhos não pontuam novamente.
3. Acerto soma **100 pontos** e **20 pontos por acerto anterior consecutivo**, limitado a 80 de bônus. Cinco acertos consecutivos rendem 700 pontos. Erro soma zero e zera a sequência.
4. Sem cronômetro obrigatório ou bônus por velocidade nesta entrega. O estudante pode ler e usar recursos de acessibilidade no próprio ritmo.
5. Após responder, mostrar resposta correta e explicação, inclusive em caso de acerto. A próxima questão exige ação explícita.
6. Resultado informa acertos de cinco, pontos da rodada e melhor pontuação **neste dispositivo e neste assunto**. Não apresentar saldo XP, nível, ranking ou conquistas fictícias.
7. Reiniciar cria uma rodada nova e zera pontos/seleção. Trocar de assunto encerra a rodada corrente e abre a seleção do novo assunto.

Visual: formas com cantos retos, bordas em degraus, pequenos elementos em pixel art, marcador de progresso e celebração curta. Steve pode aparecer como personagem original em pixels. Texto principal permanece legível; fonte pixel é limitada a títulos curtos e números. Inspirar-se no ritmo de perguntas do Kahoot sem usar sua marca, logotipo ou conteúdo.

Perguntas e aulas funcionam sem login. A melhor pontuação é local, por tópico e versão do catálogo, sem sincronização de conta; não é dado de outra meta.

## 5. Videoaulas e fontes de apoio

Duas aulas por assunto, verificadas em 30/09/2026. Todas retornaram oEmbed oficial e metadados `playabilityStatus=OK` e `playableInEmbed=true` para o mesmo ID solicitado. Reprodução em navegador ainda não foi testada; habilitação e disponibilidade podem mudar.

| Assunto | Aula | Canal | Link |
| --- | --- | --- | --- |
| Porcentagem | Porcentagem e decimal | Khan Academy Brasil | https://www.youtube.com/watch?v=TEhv11SkDUs |
| Porcentagem | Aumento por porcentagem | Khan Academy Brasil | https://www.youtube.com/watch?v=V9QV6lDitGg |
| Interpretação de texto | Compreensão x Interpretação no ENEM | Professor Noslen | https://www.youtube.com/watch?v=rf1lg2foSG4 |
| Interpretação de texto | Compreensão e Interpretação de Texto — Revisão ENEM | Professor Noslen | https://www.youtube.com/watch?v=XsN0e_xPyNI |
| Ecologia | Ecossistemas e biomas | Khan Academy Brasil | https://www.youtube.com/watch?v=gEV3nOs0EjY |
| Ecologia | Fluxo de energia e matéria através dos ecossistemas | Khan Academy Brasil | https://www.youtube.com/watch?v=qj6RWzK7cYI |

Mostrar assunto, título, canal, descrição breve e nível sugerido pela curadoria. Não inventar duração. Reservar quadro preferencialmente 16:9, com player de pelo menos 200 × 200 px, inclusive no mobile; player só carregado após o estudante selecionar a aula, sem autoplay. No Flutter Web, usar iframe oficial por `HtmlElementView`, com título acessível e controles do YouTube. Sempre oferecer **Abrir no YouTube**, inclusive se a incorporação for bloqueada ou o vídeo removido.

Nos apps nativos, esta primeira entrega abre o link no aplicativo/navegador disponível, com fallback visível em caso de falha. Não afirmar player nativo incorporado nem reprodução offline. Não baixar ou redistribuir arquivos das videoaulas.

Referências para notas autorais de apoio e links do Steve:

- [Obtenção de porcentagens — Khan Academy](https://pt.khanacademy.org/math/pt-9-ano/numeros-9ano/pt-equaes-moda-antiga-com-sal/v/taking-percentages).
- [Compreensão leitora — Ceale/UFMG](https://ceale.fae.ufmg.br/glossarioceale/verbetes/compreensao-leitora).
- [O que é um ecossistema? — Khan Academy](https://pt.khanacademy.org/science/7-ano/seres-vivos-na-natureza/ecossistemas-e-biomas/a/what-is-an-ecosystem-article).

As notas são resumos curtos autorais. Não incluir transcrições integrais ou fingir que o modelo assistiu aos vídeos. Links das fontes são escolhidos pelo servidor a partir do catálogo, nunca tratados como resultados de pesquisa em tempo real.

## 6. Cadastro, login e sessão

Cadastro por e-mail/senha, login, recuperação de senha e saída. A API Nest faz chamadas HTTPS à [API REST oficial do Firebase Authentication](https://firebase.google.com/docs/reference/rest/auth) para criar conta, autenticar, renovar e solicitar recuperação. Isso fornece o mesmo contrato ao Flutter Web e às plataformas nativas sem depender de plugin de autenticação específico da plataforma.

Contratos públicos: `POST /v1/auth/register`, `/login`, `/refresh` e `/password-reset`. As respostas de cadastro/login/renovação contêm ID token, refresh token e validade, validados antes de entrar no estado do cliente. Antes de devolver uma sessão, o backend verifica o ID token pelo Firebase Admin do projeto configurado; credenciais REST de outro projeto não criam sessão válida. O perfil interno continua vindo de `GET /v1/me`, com o token verificado pelo Firebase Admin; não confiar em UID ou plano enviados pelo cliente.

A senha só transita por TLS em produção e não é persistida. Tokens ficam somente na memória da aplicação nesta entrega. Fechar/recarregar o app exige login novamente; informar isso no formulário. Renovação antes do vencimento é compartilhada entre chamadas concorrentes. Saída, credencial definitivamente inválida na renovação e troca de conta invalidam a geração da sessão e cancelam chat/requisições para impedir respostas atrasadas. Falhas temporárias de rede, 429 ou 503 preservam tokens em memória e permitem nova tentativa; não enviar token vencido enquanto a renovação estiver indisponível.

Rotas públicas de autenticação continuam protegidas por IP: **10 tentativas por minuto por IP** para o conjunto cadastro/login/recuperação; refresh possui orçamento separado de **60 chamadas por minuto por IP**, sem consumir as dez tentativas de acesso. O guard por usuário deve ignorar apenas handlers públicos, sem usar `SkipThrottle` para essas rotas. Sessão inválida continua impedindo acesso ao Steve. Recuperação retorna mensagem genérica para evitar indicar se um e-mail tem conta.

Configuração adicional no backend: `FIREBASE_WEB_API_KEY`, vinculada ao mesmo projeto de `FIREBASE_PROJECT_ID`; provedor e-mail/senha habilitado no Firebase. Nenhuma credencial real será escrita no Git. Sem configuração, mostrar indisponibilidade de acesso à conta e manter aulas/quiz funcionais. Não criar login de demonstração ou tokens falsos.

## 7. Steve com IA generativa

Steve é tutor e guia da plataforma. Recebe o assunto atual, pergunta do estudante e histórico curto da conversa; explica em português, apresenta passos, usa exemplos e pode fazer uma pergunta para verificar entendimento. Ajuda a navegar, começar quiz, interpretar pontuação e encontrar aulas reais. Não afirma ter acessado metas, notas ou desempenho que não foram fornecidos.

Interface de chat na rota própria, com avatar original em pixels, assunto visível, sugestões iniciais, campo de mensagem, enviar, carregamento, erro e nova conversa. Sem login, explicar que entrar na conta permite conversar com Steve e oferecer acesso ao formulário. Histórico só em memória, isolado por conta e tópico. Troca de assunto ou saída limpa histórico e cancela resposta pendente. A interface nunca exibe resposta de outro tópico após uma troca.

`POST /v1/steve/messages` é privado. Entrada: `topicId` conhecido, `message` de 1 a 2.000 caracteres e até oito mensagens anteriores, cada uma com até 2.000 caracteres e papel `user` ou `assistant`. Limite total de 12.000 caracteres de histórico. Não aceitar instruções de sistema, plano, userId ou materiais arbitrários do cliente. Histórico fornecido pelo cliente é dado não confiável, nunca substitui as instruções de servidor. Não há acesso a ferramentas, banco pessoal ou navegação externa pelo modelo.

O servidor monta as instruções com nome Steve, assunto, notas autorais de apoio, fontes do catálogo e orientações verdadeiras sobre funcionalidades disponíveis. Retorno: texto da resposta, assunto validado, links de apoio selecionados pelo servidor e quota restante/reset. Texto renderizado como texto seguro, sem executar HTML ou links arbitrários produzidos pelo modelo.

Provedor inicial: OpenAI Responses API, com `store: false`, instruções explícitas em cada chamada e adaptador substituível. `OPENAI_API_KEY` e `STEVE_MODEL` configurados exclusivamente no servidor. O modelo é configuração obrigatória quando a chave está presente, sem escolher automaticamente um modelo caro ou inexistente. O provedor recebe pergunta/histórico e contexto educacional; não recebe tokens Firebase, senha, e-mail, credenciais ou identificadores internos da conta.

Steve básico fica disponível para FREE com **10 chamadas por dia por usuário**, configuráveis no servidor. O entitlement central ganha a capacidade correspondente sem liberar `advancedAi`, geração de questões ou outros recursos Premium. Limite adicional de **3 mensagens por minuto por usuário** e máximo global padrão de **1.000 chamadas por dia**, também configurável.

Quota diária usa UTC, com reset informado à UI e apresentado na hora local. PostgreSQL reserva atomicamente a cota do usuário e a global antes da chamada externa; reservas impedem contorno por concorrência ou reinício da API. Só reservar após validar entrada, sessão e configuração. Liberar a reserva uma única vez, por operação atômica, quando houver certeza de cancelamento ou falha antes do envio ao provedor. Conservar a reserva quando o envio ou seu resultado forem incertos, inclusive se a API encerrar durante a operação. Uma tentativa efetivamente enviada ao provedor conta mesmo se encerrar em timeout, pois pode ter custo; informar essa regra na ajuda. Não repetir automaticamente uma chamada de IA nem reembolsar timeout sem conhecer o resultado externo.

Timeout do provedor de **30 segundos**, limite de saída de **800 tokens**, no máximo uma chamada simultânea por usuário na instância única da API desta entrega e cancelamento com AbortController. Cancelamento do cliente interrompe processamento sempre que possível, mas não garante ausência de cobrança de uma chamada já enviada. Cliente do Steve usa timeout de recebimento de **45 segundos**, acima dos 30 segundos do provedor; não herda os 15 segundos de leitura de perfil. Resposta vazia ou inválida produz 503 seguro. Recusa explícita é exibida como orientação/recusa do Steve, com estado distinto; resposta incompleta ou truncada não é mostrada como concluída e oferece ação manual para reformular a pergunta. Limite HTTP de corpo de **64 KiB** para os novos contratos. Nenhum prompt, resposta, senha, token ou corpo completo é incluído em logs.

Falhas: 400 entrada inválida; 401 sessão ausente/inválida; 429 quota/limite excedido; 503 configuração ausente, provedor ou banco indisponível; erro seguro no padrão atual com requestId. A UI mostra motivo útil e ação de recuperação. Não substituir indisponibilidade por resposta simulada de IA. Concluir integração de código não significa ter verificado chamadas reais sem credenciais configuradas.

## 8. Compatibilidade e entrega

Preservar temas, preferências persistidas, responsividade, controles de movimento e contratos de segurança da fundação. Alterar textos que anunciam recursos futuros para refletir os fluxos implementados. Aulas/quiz continuam abrindo mesmo sem API local.

Validação principal em Flutter Web neste ambiente. Android/iOS/Windows mantêm código compatível e o fallback de mídia, mas só serão anunciados como compilados/testados se houver toolchain e execução reais. Não configurar permissões globais do Windows nem modificar AlmaPet.

Documentar variáveis, configuração de Firebase/provedor, migração de quota, scripts de desenvolvimento, fontes de mídia e limitações. Atualizar OpenAPI a partir das rotas efetivas. O preview deve servir o novo build, sem alegar publicação em produção.

## 9. Critérios de aceitação e evidência

1. Hero mostra Estuda Aí, fotografia, apoio e ações reais; animações respeitam movimento reduzido e preferência local.
2. Seleção e links diretos conservam tópico consistente entre aulas, quiz e Steve, incluindo assunto desconhecido e troca durante operação.
3. Trinta questões originais validadas estruturalmente; uma rodada completa por assunto; pontuação demonstrada para todos os acertos, erro e clique repetido; resultado local rotulado por dispositivo.
4. Seis IDs reais constam do catálogo com créditos. Player Web inicia por ação, funciona quando permitido e conserva link externo. Relatar claramente metadados verificados versus reprodução realmente observada.
5. Login/cadastro/refresh/reset possuem contratos e falhas seguros; nenhuma credencial persiste em preferências. Testes com doubles não são relatados como validação Firebase real.
6. Steve exige autenticação, valida assunto, isola conversas, respeita cotas atômicas, timeout e configuração ausente. Provedor de teste somente em testes; app não apresenta conversas falsas como reais.
7. Testes de API, máquina do quiz, estado de sessão e cancelamento; análise Flutter; build Web de produção; teste de banco para concorrência das cotas conforme ambiente disponível.
8. Verificação em 360, 768 e 1440 px, texto a 200%, navegação por teclado, temas e movimento reduzido; console sem erros próprios da aplicação. Fotografias e controles sem sobreposição.
9. Evidência distingue testes locais, doubles, reprodução externa e integração real. Nenhum deploy ou construção nativa será presumido.

## 10. Referências técnicas e próximo passo

- [Referência de hero fornecida pelo usuário](C:/Users/glaub/.codex/attachments/5436bd67-a5dc-4c79-95e2-493bfa4b88ee/Texto%20colado.txt).
- [Flutter — conteúdo Web incorporado](https://docs.flutter.dev/platform-integration/web/web-content-in-flutter).
- [YouTube — parâmetros do player](https://developers.google.com/youtube/player_parameters).
- [Firebase Authentication — API REST](https://firebase.google.com/docs/reference/rest/auth).
- [OpenAI — API e autenticação no servidor](https://developers.openai.com/api/reference/overview).
- [OpenAI — geração de texto e instruções](https://developers.openai.com/api/docs/guides/text).

Após a revisão e aprovação desta especificação escrita, criar o plano de implementação com tarefas e verificações concretas. A execução só começa após revisão do plano e escolha do modo de execução, conforme o processo brainstorming adotado nesta conversa.
