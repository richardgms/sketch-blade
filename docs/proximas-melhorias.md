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
- **Vitória com o chefe (29/10):** `Main._mostrar_chefe_vitoria` usa o desenho e o nome da ficha (`Boss.FICHAS[cap]["nome"]`, com artigo: "o Compasso", "a Mancha"); selo redondo de carimbo (`SeloDerrotado.gd`: anel duplo, "CAPÍTULO N" e nome do chefe em arco, faixa DERROTADO) bate em 0,5 s; nesse momento o desenho vira preto e branco suave (shader com parâmetro `cinza`; no Godot 4 o `COLOR` do fragment já traz a textura, multiplicar de novo escurece). Selo no centro do desenho; anel do texto opaco para ler sobre traço preto, miolo meio transparente; a tinta conta até o total. Print: `bash tools/capturar_telas.sh <pasta> vitoria` (capítulos 5 e 9, no meio da animação e no fim).
