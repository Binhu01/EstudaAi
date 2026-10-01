# ShaderGradient no Flutter

O [preset integral](references/shader-gradient.json) preserva todos os valores enviados pelo usuário. O componente original pertence ao ecossistema React/Three.js; a aplicação aprovada usa Flutter. Esta implementação é um fragment shader GLSL original, compilado pelo Flutter, com aparência inspirada na referência. Não reproduz a câmera, o ambiente ou a malha 3D de forma exata.

| Referência | Aplicação nativa |
| --- | --- |
| `color1`, `color2`, `color3` | Tokens exatos `#d6ce36`, `#0000d8`, `#9147ff` |
| `brightness=1.5` | Multiplicador da iluminação procedural |
| `rotationZ=140` | Rotação do campo de coordenadas em 140 graus |
| `uDensity=.8`, `uFrequency=5.5` | Densidade do ruído e frequência de ondulação |
| `uAmplitude=7`, `uStrength=.4` | Deformação do campo e intensidade das ondas |
| `uSpeed=.3`, `uTime=0` | Velocidade e instante inicial |
| `type=sphere`, `lightType=3d` | Aproximação de volume/iluminação no campo 2D, sem geometria 3D |
| `grain=on`, `frameRate=10` | Grão discreto; atualização a cada 100 ms |
| Câmera, FOV, zoom, posições/rotações 3D, reflexão, `envPreset=city` | Valores guardados como referência; não há câmera, ambiente refletivo ou cena Three.js |
| `format=gif`, canvas/embed/helpers/range/wireframe | Não geram GIF, WebView, editor ou controles no aplicativo |
| `pixelDensity=1` | Referência preservada; a densidade real segue o renderer/dispositivo Flutter |

Código: `apps/client/shaders/study_gradient.frag`, `lib/design_system/shader/` e tokens centrais. Não foi usada uma biblioteca React dentro do cliente. O fundo mantém azul/violeta/amarelo somente na área de boas-vindas; cores operacionais continuam com seus significados originais.

Preferências → Animação de fundo controla o movimento. A política também interrompe atualizações em lifecycle inativo, fora do viewport, `TickerMode` desabilitado e movimento reduzido. Ao desativar, o shader mantém um quadro estático. Falha de carregamento/compilação preserva um gradiente estático nas mesmas cores.

A compilação Web, o avanço/pausa e o fallback possuem verificações executadas. Isso não mede consumo de bateria, GPU ou desempenho em dispositivos nativos; essas medições e ajustes precisam de aparelhos reais antes da publicação. Referência técnica: [fragment shaders do Flutter](https://docs.flutter.dev/ui/design/graphics/fragment-shaders).
