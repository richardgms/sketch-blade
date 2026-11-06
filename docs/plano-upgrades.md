# Plano: melhorias da roleta (upgrades da partida)

Pedido de 05/11/2026: revisar mecânica dos upgrades fracos e refazer o visual do
Escudo de Borracha, do Borrão Explosivo e da Tinta Corrosiva. É roguelite: pode
haver melhores e piores, mas todos devem ser bonitos e perceptíveis.

## Diagnóstico (código atual, 1.8.4)
Referência: Estojo nível 4 = 23 de dano, 0,56 s entre tiros (~41 de dano/s).

| Upgrade | Ganho aproximado (nv 1/2/3) | Observação |
|---|---|---|
| Duas portas | +70/90/100% | o mais forte |
| Leque | até +100/130/160% (se as diagonais acertam) | forte |
| Apontador | +18/33/54% | bom |
| Ponta crítica | +10/20/30% | ok; o x2 escala com o dano |
| Perfurante / Saltitante | situacional, forte em horda | ok |
| **Corrosiva** | +5/10/15% (2/4/6 por s, fixo) | fraca; no Estojo 10 vira +1–3% |
| **Borrão** | 8/14/20 fixos ao matar, raio 160 | some no fim (HP x1,28 por capítulo; cap. 10 = x9,3) |
| **Escudo** | bloqueia 1 golpe, recarga 8/6/4 s | mecânica boa; visual é só 2 círculos |

Causa principal: corrosiva e borrão têm dano **fixo**, enquanto o dano da caneta e
a vida dos monstros crescem. O resto escala com o dano da caneta.

Visual hoje:
- Escudo: dois `draw_arc` (azul + branco) em volta da caneta (`Player._draw`).
- Borrão: **nenhum efeito**; o dano aparece sem explosão (`Main._on_enemy_morreu`).
- Corrosiva: só tinge o monstro de verde (`Enemy.aplicar_dot`, `Boss`, `PedacoMancha`).

## Etapas
1. Decidir mecânica de corrosiva e borrão (dano proporcional ao da caneta?).
2. Escudo: visual novo à caneta (protótipo → print → página → aprovação).
3. Borrão: explosão de tinta visível (respingo + anel do raio).
4. Corrosiva: tinta borbulhando/escorrendo no monstro e no chefe.
5. Ícones/textos da roleta se a mecânica mudar; teste com robô nos chefes.

Regras: economia, save, compras e anúncios fora do escopo. Uma tela/efeito por
vez com print na página de melhorias visuais. Sem build sem pedido.

## Andamento
- 05/11: diagnóstico feito. Etapa 1 decidida (opção 1, dano proporcional) e
  Richard pediu raio maior no borrão (monstros raramente estão tão perto).
- 05/11, v1 no jogo (aguardando aprovação visual):
  - Corrosiva 20/35/50% do dano do tiro por s, 3 s (`Player._disparar_projetil`);
    dano em pulsos de 0,5 s com um número só (Enemy, Boss, PedacoMancha).
  - Borrão 40/60/80% do dano da caneta, raio `GameData.RAIOS_EXPLOSAO` 200/240/280.
  - Escudo: `Player._desenhar_escudo` (anel tracejado r=92 em volta da caneta toda,
    gira, cruzinhas; recarga mostra os traços voltando) + `EscudoQuebra.gd`.
  - Borrão: `ExplosaoBorrao.gd` com `assets/ui/explosao_borrao.png` (o ícone
    convertido para branco tingível, na cor do monstro) + anel do alcance; máx. 6.
  - Corrosiva: `CorrosaoTinta.gd` (bolhas, pingos, fumaça, mancha verde), filho
    do alvo; no chefe usa 1,5x o raio de acerto.
  - Prints: `tools/prints_upgrades.gd -- <pasta> [escudo,borrao,corrosiva]`
    (backup do save antes). Antes/v1 em `Documentos\Sketch Blade - design\upgrades\`.
  - Página: https://claude.ai/artifact/TJVaMr4MGn6EGpBcQjzUyZ
  - Robô nos chefes 1, 3, 5 e 8 sem erro de script (1 semente, sem medir equilíbrio).
- 06/11, rodada 1 recusada: escudo redondo cobria a caneta, cruzinhas e 3
  tracinhos "mehh" (gostou do bloqueio com pedaços e farelo); explosão grande
  demais e por cima do MORREU!; corrosão sem convencer. Pediu opções e sugeriu
  pílula inspirada na borracha azul/vermelha de caneta.
- 06/11, rodada 2 (3 opções por efeito, troca por `static var estilo`):
  - Escudo em pílula (`EscudoBorracha.gd`): A tracejada, B bicolor azul/vermelho,
    C contorno com hachura. Quebra genérica por pedaços (`EscudoQuebra.pedacos`).
  - Explosão (`ExplosaoBorrao.gd`, z 0, MORREU! por cima): A nuvem e B estrela de
    quadrinho geradas no GPT Image (originais em `Sketch Blade - design\upgrades\gerados\`,
    branco tingível em `assets/ui/explosao_nuvem.png` e `explosao_estrela.png`),
    C respingo menor. Conversão: alfa = alfa x (1 - luminância) x 2,2.
  - Corrosão (`CorrosaoTinta.gd`): A rabiscado, B vapor, C bolhas à caneta.
  - Prints em `upgrades\v2\` (sufixo -A/-B/-C). Depois da escolha, apagar os
    estilos e imagens não usados.
- 06/11, rodada 3: escudo escolhido = B (borracha), pedindo mais cara de borracha.
  `EscudoBorracha.gd` virou o bloco chanfrado da borracha de caneta (azul 35% em
  cima, vermelho 65%, face de cima, quinas, hachura e faixa branca); miolo por
  baixo da caneta (`_desenhar_escudo(false)`), contorno por cima. Estilos A/C saíram.
  Corrosão: nenhuma das 3 agradou (rabiscado não; vapor de código "parece Paint";
  bolhas tampam o olho do chefe; "só verde" era melhor). Próximo: vapor desenhado
  no GPT Image, animado no jogo. Explosão: escolha ainda pendente.
- 06/11, rodada 4: GIF do ChatGPT (Images 2.6, 04/11) testado pelo Richard, movimento
  ruim; o Codex CLI não gera GIF (devolve PNG). Escolhido vapor animado pelo jogo:
  `vapor_referencia.png` (GPT Image, em `upgrades\gerados\`) separado em 3 fiapos
  (`assets/ui/vapor_1..3.png`, reduzidos por máximo de bloco para o traço não
  sumir no tamanho do monstro). `CorrosaoTinta.gd`: fiapos sobem do alto da
  cabeça, crescem e somem (1,1 s, 3,2/s), shader de onda; monstro segue
  esverdeado. Prints e GIFs do jogo em `upgrades\v4\` (`tools/prints_upgrades.gd`
  grava a sequência `gif-*`). Chefe não fica verde (só o vapor).
- 06/11, rodada 5: fumaça espalhada (x ±0,8 raio, base mais baixa e inclinada nas
  laterais) e bolhas à caneta: folha de 6 quadros do GPT Image (`upgrades\gerados\
  bolha_quadros.png`; pedir "uma linha de N quadros com vãos largos" funcionou e
  saiu em grade igual) recortada em `assets/ui/bolha_quadros.png` (6 x 96 px,
  reduzida por máximo de bloco). Bolhas nascem na borda do corpo fora do rosto,
  sobem tremendo (quadros 0/1) e estouram (2..5, 0,06 s); chefe 4/s e maiores,
  monstro 1,5/s. Camada própria sem o shader de onda. GIF do monstro: o script
  baixa o dano da caneta para ele durar na tela.
- 06/11, rodada 6: número de dano colorido por fonte. `receber_dano_fonte(q, fonte)`
  em Enemy, Boss e PedacoMancha (guarda `fonte_dano` só durante a chamada);
  `Main.COR_DANO_FONTE`: corrosão `#6fd877`, explosão `#c99bff` (tiro branco,
  crítico dourado, dano no jogador vermelho). No chefe, número colorido ao lado,
  fora da soma de `spawn_dano_chefe`. Novo upgrade com dano próprio: passar a fonte
  e pôr a cor na tabela. Uma captura de prints encerrou no meio uma vez sem erro
  no log; repetida, passou.
- 06/11, rodada 7: lilás da explosão sem contraste → rosa `#ff5cc8`. Textos
  flutuantes (`FeedbackLabel.gd`) com contorno escuro 12 (cor na fonte, não no
  modulate, senão o contorno tinge). `Main._spawn_feedback(..., folga)`: texto
  fora do alvo, acima; embaixo e descendo se acima ficar sobre o HUD (y < 360).
  MORREU! usa folga 95 ou 0,62 x raio do Borrão. Escudo: saiu o "BLOQUEADO"
  (ficou só APAGADO!, folga 190). Tsuru continua usando "BLOQUEADO" no bloqueio dele.
- 06/11, rodada 8: borracha aprovada (por enquanto); explosão escolhida = nuvem.
  Virou animação: folha de 6 quadros do GPT Image (`upgrades\gerados\explosao_quadros.png`,
  com a nuvem como referência) em `assets/ui/explosao_quadros.png` (6 x 140 px).
  Quadros fora de grade: separados pelos vãos de colunas vazias e cada um limitado
  à própria faixa. Tempos 0,05/0,06/0,08/0,20/0,14/0,14 s. Saíram estrela, respingo
  e a nuvem parada (texturas removidas). APAGADO! com folga 280.
  GIF da explosão: o script espera o hitstop (0,06 s real) e grava em câmera lenta
  0,2x; senão o hitstop devolve time_scale 1 e a gravação sai acelerada.
- 06/11, rodada 9: quebra do escudo animada. Folha do GPT Image com a borracha do
  jogo como referência (`upgrades\gerados\borracha_quebra_quadros.png`; referência
  `ref_borracha_jogo.png`), recortada COM as cores (alfa = brancura invertida,
  cor desmisturada do branco, redução com alfa pré-multiplicado) em
  `assets/ui/borracha_quebra.png` (6 x 216x336). Centros fixos a cada 363 px
  (a estrelinha do impacto deslocava o centro calculado pelos vãos).
  `EscudoQuebra.gd` toca 0,52 s na escala do escudo + 8 farelos com gravidade.
  Saiu `EscudoBorracha.pedacos`. O escudo parado segue em código (precisa da recarga).
