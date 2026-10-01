# Decisões da entrega

Decisões tomadas durante a execução aprovada e avaliação dos pontos deixados fora da revisão. Cada item preserva o motivo e o custo, na ordem em que foi registrado.

- Ruling: checkout Git manual no repositório EstudaAi — ferramenta nativa vincula a conversa à AlmaPet e não recebe caminho de outro repo — custo: checkout não gerenciado pela UI, cleanup manual ao concluir.
- Ruling: headings dos subplanos numerados como Task N preservando A1–D3 — helper task-brief exige números, sem mudar escopo — custo: apenas formato dos títulos.
- Ruling: usar Flutter SDK absoluto da pasta primária — tooling ignorado não acompanha worktree — custo: comandos locais dependem desse SDK, CI usa versão fixada.
- Task D2: Ruling: Respostas concluídas podem ultrapassar o limite de 2.000 caracteres de cada mensagem de histórico de C3; enviar apenas pares completos com ambas as mensagens até 2.000, removendo pares mais antigos até oito mensagens/12.000 caracteres — mantém o contrato sem truncar a explicação — custo: respostas muito longas permanecem visíveis mas não ajudam o contexto de pedidos seguintes.
- Task D3: Ruling: O índice dizia reset {status:accepted}, mas C1/D1 e OpenAPI usam {accepted:true}; alinhei o índice ao contrato implementado/testado — mantém confirmação genérica aprovada — custo: consumidores do índice antigo precisam usar accepted=true.
- Task D3: Ruling: Sem configuração local não há API em3001; validar acesso real como conexão recusada com mensagem segura, e503 nos testes HTTP Nest, sem iniciar servidor com identidade/credencial fictícia — custo: login e respostas externas ficam pendentes do ambiente configurado.
- Final: Ruling: Firebase/OpenAI reais fora da avaliação por ausência de configuração — entregar código e testes, sem alegar chamadas reais — custo: ativação/validação externa depende do ambiente.
- Final: Ruling: Playback das outras cinco aulas fora da evidência — manter iframes/links validados e afirmar reprodução só da primeira — custo: demais reproduções dependem de disponibilidade externa e nova inspeção.
- Final: Ruling: Builds nativos, Docker, CI remota e deploy não executados — preservar matriz de limites sem homologação implícita — custo: publicação requer validação própria.
- Final: Ruling: Proxy e múltiplas instâncias são preparação de produção pendente — entrega inicial por instância mantém limitação documentada — custo: escalar sem adaptar pode agrupar IPs e contornar limites por minuto.
- Final: Ruling: Preferência Animação de fundo não promete desativar rolagem do CTA — conservar rolagem respeitando movimento reduzido do dispositivo — custo: desligar apenas fundo conserva algumas transições.

Não houve achado menor adiado. Dois achados importantes da revisão foram corrigidos com regressões que falharam antes e passaram depois: refresh de usuário excluído e saldo desatualizado. Veja [Validação](VALIDACAO.md).
