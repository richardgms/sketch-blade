# Próximas melhorias (fora dos chefes)

Fonte única da lista de melhorias depois da 1.5.0. Antes/depois para aprovar: https://claude.ai/artifact/VdK88T7PA2HgKCCBubEKrg Decisão: conselho de LLMs de 29/10/2026, rodado sobre prints do jogo atual (`tools/capturar_prints.gd` + `tools/capturar_telas.sh`). Uma rodada anterior usou a revisão visual de 27/10, já desatualizada (monstros e chefes já têm arte), e foi descartada.

## Veredito
- **Consenso (5 de 5):** a arte do combate já está no nível da loja (monstros, elite, chefes, roleta). Mais arte de monstro rende pouco.
- **Onde a arte ainda rende:** onde o jogador para e olha e hoje não vê o que conquistou.
  - **Vitória:** só texto, e diz "Você derrotou o Boss de Tinta!" para qualquer chefe (texto fixo em `main.tscn`).
  - **Hub, aba Lutar:** caderno pequeno e meia tela vazia, sem chefe, sem progresso.
- **Choque:** parar a arte de vez e corrigir só legibilidade e progresso × investir arte nessas telas. O dono quer investir em visual, e essas telas são onde rende.
- **Pontos cegos da revisão:**
  - **Reaproveitar os sprites dos 10 chefes** em vez de gerar retratos novos: evita estilo inconsistente.
  - **Gravar progresso por capítulo sem quebrar o save** dos testadores: campo novo com valor padrão.
  - **Legibilidade no chefe:** tiros vermelhos e números de dano por cima do Compasso.
  - **Primeiros minutos:** o jogador novo não sabe o que são as gotas coloridas no chão.
  - **Pedir avaliação na loja** depois de uma vitória.
  - **Prints da loja novos** com a vitória e o hub ilustrados.

## Lista priorizada
| # | O quê | Arte? | Depende do teste humano? |
|---|---|---|---|
| 1 | ✅ feito (29/10, aguardando aprovação) **Vitória com o chefe:** nome certo ("Você derrotou o Compasso!"), sprite do chefe com carimbo "DERROTADO" e contagem da tinta | Sim (carimbo) | Não |
| 2 | **Hub Lutar com o chefe do capítulo:** silhueta "???" antes de vencer, colorido depois; melhor página e chefe vencido por capítulo | Sim (reaproveita sprites) | Não |
| 3 | **Álbum de chefes / adesivos** (os 10 chefes como coleção) + poucas conquistas | Sim | Parcial |
| 4 | **Legibilidade no chefe:** números de dano e tiros não cobrem o chefe | Não | Não |
| 5 | **Primeiros minutos:** dica das gotas de tinta; pedido de avaliação após vitória | Não | Não |
| 6 | **Prints da loja novos** com vitória e hub | Sim | Não |
| 7 | **Depois da produção:** Ascensão, maratona de chefes, gasto de tinta extra (níveis, cosméticos), sons e música variada | — | Sim |

## Feito
- **Vitória com o chefe (29/10):** `Main._mostrar_chefe_vitoria` usa o desenho e o nome da ficha (`Boss.FICHAS[cap]["nome"]`, com artigo: "o Compasso", "a Mancha"); selo redondo de carimbo (`SeloDerrotado.gd`: anel duplo, "CAPÍTULO N" e nome do chefe em arco, faixa DERROTADO) bate em 0,5 s; nesse momento o desenho vira preto e branco suave (shader com parâmetro `cinza`; no Godot 4 o `COLOR` do fragment já traz a textura, multiplicar de novo escurece). Selo no centro do desenho; anel do texto opaco para ler sobre traço preto, miolo meio transparente; a tinta conta até o total; "Capítulo N desbloqueado!" sai da lista de números e entra depois da contagem com letra de título, azul de caneta e faixa de marca-texto (some quando o capítulo é repetido). Print: `bash tools/capturar_telas.sh <pasta> vitoria` (capítulos 5 e 9, no meio da animação e no fim).
- **Hub com o chefe (29/10, protótipos):** 3 opções na página de antes/depois: A chefe no lugar da ilustração, B ilustração + ficha em post-it, C cartaz de PROCURADO; todas com sombra de tinta + "???" antes, colorido + selo depois, e trilha das 8 páginas. Aguardando escolha. Pendência junto: o subtítulo do capítulo (ex.: "Compasso") entrega o nome do chefe.
- **Hub "A evoluída" (conselho 29/10):** estrutura da A aprovada (capítulo compacto → arte grande → nome/estado → trilha → botão forte), selo pequeno no canto. Sem campo novo no save na primeira leva: capítulo não vencido mostra a ilustração do objeto (o subtítulo já é o nome do objeto, então nada é entregue), vencido mostra o monstro colorido com selo no canto (vencido = abaixo de `capitulo_desbloqueado`). A revelação objeto → monstro acontece no combate, quando o chefe surge na página 8 (sem estado novo). Botão com moldura e texto conforme a ação (Lutar / Continuar · página X / Jogar de novo), sem tirar o popup de retomada. Trilha maior, com o mini desenho do chefe na última casa (não depende só de cor). "Melhor página" entra depois, como campo com valor padrão. Cortado: transição no hub com flag "chefe visto", post-it e cartaz permanentes.
- **Hub "A evoluída", protótipo (29/10):** 3 estados na página de antes/depois (não vencido, partida salva, vencido). Gerado por script fora do repositório; aguardando aprovação para entrar no jogo.

## Hub novo: rascunho do amigo designer (29/10) — PLANO ATUAL
Rascunho (fora do repositório): `Documentos\Sketch Blade - design\hub-rascunho-amigo-2026-10-29.png`. Substitui o protótipo "A evoluída" acima como referência visual; a regra continua: nada novo no save além do recorde. Pegar as ideias e ajustar ao gosto do Richard, uma tela por vez, com print na página de antes/depois antes de seguir.

**Elementos comuns**
- Setas de capítulo ao lado do título "Capítulo N" (sobem do meio da tela) → centro livre para a arte.
- Título "Capítulo N" + nome do capítulo maior + "MODO NORMAL" com sublinhado verde.
- Trilha de 8 casas maior; a última casa é o chefe: círculo com "?" antes de vencer, mini desenho do chefe com ✓ verde depois.
- Botão principal cheio (azul com texto branco), moldura desenhada.
- Frase que ensina a regra: "Nova tentativa começa na página 1."

**Telas (ordem de implementação)**
1. **Hub · Nova tentativa** (capítulo não vencido): ilustração do objeto, "Algo se mexe nesta página…", "Melhor tentativa: página 6 de 8", trilha com recorde, "Nova tentativa começa na página 1.", botão LUTAR.
   - Variante **primeira vez** (nunca jogou o capítulo): igual, sem a linha "Melhor tentativa", trilha toda vazia; frase sugerida: "8 páginas · o chefe espera na última."
2. **Hub · Concluído** (capítulo vencido): arte do monstro (`assets/inimigos/chefe_N.png`) com selo DERROTADO pequeno no canto (decidir: selo redondo da vitória × retangular do rascunho), "O Compasso foi derrotado!", "Capítulo concluído", trilha cheia com mini chefe + ✓, "Nova tentativa começa na página 1.", botão JOGAR NOVAMENTE.
3. **Retomar partida** (popup ao abrir com `run_snapshot` ativo; hoje "RUN EM ANDAMENTO"): título "PARTIDA EM ANDAMENTO", "Capítulo 5 · Compasso", ilustração, "Página 4 de 8", trilha numerada com a página atual destacada, "Você voltará ao início da página 4.", bloco "Preservado nesta partida" (corações, tinta, nº de melhorias, reviver disponível/usado), botão CONTINUAR PARTIDA, botão ABANDONAR PARTIDA (contorno vermelho) + "Ao abandonar, você perde os ganhos desta partida." Também: LUTAR no hub não pode apagar a partida salva sem avisar.

**Dados**: vencido = capítulo < `capitulo_desbloqueado`; partida salva = `SaveManager.get_run_snapshot()` (capitulo, pagina, hp, tinta_partida, upgrades, revive_usado); recorde = campo novo com valor padrão (ex.: `stats["melhor_pagina"][str(cap)]`), gravado em `_processar_fim_de_jogo`.
**Ícones**: coração `assets/upgrade2.svg`, tinta `assets/ink.svg`; seta de melhoria e asa de reviver podem precisar de ícone novo (skill `gerar-imagem`).
**Como prototipar/printar**: script `extends SceneTree` que abre `hub.tscn` num `SubViewport` 1080x1920, ajusta o save em memória (`SaveManager.dados`) e salva PNG; ver `tools/capturar_telas.gd`. Sempre backup do save do PC antes e restaurar depois.
