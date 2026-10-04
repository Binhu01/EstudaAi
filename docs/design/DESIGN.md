# Estuda Aí — sistema visual

Direção aprovada pelo usuário em 03/10/2026: áreas de estudo inspiradas no Dala, hero inspirado na referência Auros enviada e gamificação inspirada no Playdate/Game Boy. Aplicação em Flutter, com rotas, conteúdo, conta e histórico existentes.

## Referências

- Dala: https://dala.craftedbygc.com — palco preto, branco, violeta, tipografia regular e constelação.
- Playdate: https://play.date — amarelo, carvão quente, visor monocromático e linguagem de console portátil.
- Auros: referência de estilo e tokens fornecidos pelo usuário — verde profundo, partículas luminosas e destaque ciano/lavanda.
- Oswald e Poppins: arquivos oficiais de https://github.com/google/fonts/tree/main/ofl/oswald e https://github.com/google/fonts/tree/main/ofl/poppins, distribuídos localmente com as respectivas licenças OFL em `apps/client/assets/fonts`.

As referências orientam a linguagem visual. Textos, marca e desenho do console do Estuda Aí são próprios; não são componentes ou ativos copiados dos sites.

## Estudo

Tema escuro: canvas #000000, superfície funcional #111114, texto #ffffff, apoio #bdbdbd, violeta #8052ff para ações e âmbar #ffb829 para rótulos e destaques. Tema claro equivalente: canvas #faf9fc, branco, texto #17151c e violeta #7040df. Não usar âmbar claro como texto comum sobre branco; reservar o tom de tinta escura para mensagens em fundos âmbar.

Títulos em Oswald de peso 500, cabeçalhos de página de 32–44 px e texto de leitura em Poppins 16 px com altura 1,65. Metadados e controles usam Poppins 12–14 px. PressStart2P permanece nos pequenos rótulos dos jogos. As fontes são locais; a interface não depende de uma requisição ao Google Fonts.

A navegação mantém os destinos e o assunto escolhido. Desktop usa sidebar de 260 px recolhível com grupos, busca de destinos e troca entre estudo livre e concursos. Tablet e celular usam a mesma navegação em gaveta; o celular também mantém a barra inferior nas telas de estudo e os atalhos de conta e preferências. A preparação Banco do Brasil aparece em um grupo expansível; o caderno de erros tem destino próprio. A busca abre por Ctrl/Cmd+K e funciona com teclado, Enter e Escape. O conteúdo tem largura limitada e ações explícitas; não há indicadores ou progresso fictícios.

## Hero

O hero Auros ocupa a largura da área principal, com canvas #012624, título branco Oswald, texto #bbc7c6, detalhes ciano/lavanda e ação em gradiente claro. A composição central mantém marca, promessa de aprendizado e ação real para escolher um assunto. Um cérebro tridimensional de partículas é desenhado localmente, com hemisférios, sulcos e pulsos luminosos nas conexões para representar pensamentos. O ciclo de oito segundos é contínuo e não depende de vídeo externo. O usuário pediu explicitamente o looping do cérebro mesmo com movimento reduzido do navegador: essa exceção vale apenas para o cérebro. A opção Animação do hero em Preferências permite pausar o desenho. Ele também pausa fora da tela, fora do primeiro plano e em TickerMode desativado. O texto reflow com ampliação e o botão permanece acessível no celular. O shader anterior fica em um pequeno detalhe visual, com sua configuração preservada.

## Desafios

Chassi #ffc500, tinta #312f27, visor #e9e4d9, detalhe neutro #788086 e ação #7700ff. Questões e alternativas usam fonte legível; pixels aparecem na identidade, nos rótulos e nos detalhes do console. Correção usa ícones e texto além de cor. D-pad e botões ilustrados são decorativos e excluídos da navegação; as ações reais são botões rotulados.

Preservar pontuação, confirmação de envio, revisão e estados de falha existentes. O console não implica temporizador nem competição ao vivo.

## Componentes e acesso

Tokens executáveis: `apps/client/lib/design_system/tokens.dart`. Tema: `theme.dart`. Cabeçalhos: `components/page_heading.dart`. Console: `features/quiz/quiz_console.dart`. Tokens portáveis: `docs/design/design-tokens.json`.

Espaçamento: 4, 8, 12, 16, 24, 36 e 60. Painéis operacionais com raio 8; campos 6; ações principais em pílula. Sem sombras decorativas na área de estudo. O contorno do console pertence à identidade de jogo.

Alvos de toque de pelo menos 48 px, foco visível, títulos sem altura fixa, reflow em texto ampliado e contraste mínimo 4,5 para texto comum. O shader obedece à preferência de movimento reduzido; o cérebro tem a exceção explicitamente solicitada pelo usuário. Ambos respeitam pausa manual, visibilidade e ciclo de vida.

## Verificação

Conferir análise Flutter, suíte de testes, build web, desktop/tablet/celular, os dois temas, navegação por teclado, conta, leitura, aulas, quiz, resultado, Steve, painel e caderno. A presença do Steve na interface não valida a API de IA: sua ativação real continua dependendo da configuração adiada pelo usuário.
