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
