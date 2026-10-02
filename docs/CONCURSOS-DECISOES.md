# Decisões da execução — Concursos

Registro completo das decisões classificadas como `Ruling` nos planos, em ordem, antes da limpeza dos arquivos temporários da execução principal.

| Decisão | Motivo | Custo se estiver errada |
| --- | --- | --- |
| Criar worktree manual no EstudaAi | Ferramenta nativa da conversa está vinculada à AlmaPet, fora do escopo. | Checkout adicional a limpar; AlmaPet permanece sem alteração. |
| Reutilizar node_modules por junction e SDK Flutter da base | Plano não adiciona dependências; versões e locks existentes são os mesmos. | Reinstalar isoladamente e repetir baseline; não alterar dependências da base. |
| Fixar steveClock nas duas fixtures antigas | resetAt de 02/10/2026 00:00 UTC havia vencido; produto descartava corretamente a quota. Falha 56/58 → aprovação 58/58, mantendo teste explícito de renovação. | Fixture pode ocultar comportamento temporal; teste explícito de expiração continua obrigatório. |
| Numerar headings como Task N, mantendo T1–T8/C0–C10 nos títulos | Scripts oficiais extraem somente Task N. | Organização documental, sem mudança de escopo. |
| Commit candidato T8 antes da revisão | Revisão integral precisa incluir scripts/documentação; conclusão de T8 exige a revisão. | Um commit local candidato antes dos ajustes; nenhuma integração/publicação. |
| Firebase/OpenAI reais ficaram fora do julgamento | Sem configuração; contratos testados, sem anunciar login ou respostas reais. | Ajustes na integração quando configurada. |
| Reprodução integral dos 18 vídeos ficou fora do julgamento | São apoio complementar com player e link; evidência limitada a metadados/iframe/link. | Vídeo restrito ou indisponível exige alternativa. |
| Docker, nativos, CI remota e implantação ficaram fora do julgamento | Entrega Web e testes locais; não anunciar execução ausente. | Incompatibilidades dessas plataformas ainda não detectadas. |
| Não repetir PostgreSQL real | Nenhuma alteração de SQL/cota; testes existentes mantidos. | Diferença ambiental pode exigir validação adicional. |
| Não afirmar originalidade universal, domínio ou aprovação | Autoria própria e comparação limitada não demonstram esses resultados. | Coincidência ou erro residual, exigindo revisão didática. |

Achado menor adiado: espaçamento de referências de células/variáveis (`paraB 2`, `usarD 2`, `principalP emn`), inclusive nas notas. Os achados importantes foram corrigidos e verificados; ver [revisão final](CONCURSOS-REVISAO.md) e [validação](VALIDACAO.md).
