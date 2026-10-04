# Cliente Estuda Aí

Aplicativo Flutter/Material 3 com Riverpod, GoRouter e Dio. A [experiência de aprendizagem](../../docs/APRENDIZAGEM.md) conecta painel diário, cobertura por matéria, conquistas de constância, rodadas de erros e leitura ajustável. Inclui estudo livre, preparação para concursos, material autoral, videoaulas, desafios individuais, Steve, conta, painel diário e caderno de erros.

O visual adapta as referências Dala (estudo), Auros (hero enviado pelo usuário) e Playdate/Game Boy (desafios). A sidebar recolhível tem busca de destinos, troca de área e gaveta mobile; o hero usa cérebro de partículas com pensamentos luminosos em looping de oito segundos. Veja o [sistema visual](../../docs/design/DESIGN.md), os [tokens portáveis](../../docs/design/design-tokens.json), a [instalação](../../docs/INSTALACAO.md), a [validação](../../docs/VALIDACAO.md) e a [adaptação do shader](../../docs/SHADER.md). Os tokens e temas executáveis ficam em `lib/design_system`.

Use o SDK Flutter 3.47.5/Dart 3.13.4. Oswald (títulos), Poppins (leitura/interface) e PressStart2P (rótulos de jogo) são fontes locais. O cérebro tem looping explicitamente solicitado mesmo com movimento reduzido, e pode ser pausado em Preferências. Cérebro e shader pausam por visibilidade e ciclo de vida; o shader também respeita movimento reduzido.

Rotas principais: `/`, `/aprender/:topicId`, `/desafios/:topicId`, `/steve/:topicId`, `/concursos`, `/conta`, `/meu-estudo`, `/meus-erros` e `/preferencias`. Rotas de módulos mantêm o contexto da preparação. A galeria `/componentes` existe somente em desenvolvimento.

Não coloque chaves administrativas, tokens ou senhas neste cliente. A IA do Steve depende de configuração no backend. Diretórios Android/iOS/Windows são scaffolds; builds nativos e identidades comerciais ainda precisam de validação.
