# Próximas melhorias (fora dos chefes)

Fonte única da lista de melhorias depois da 1.5.0. Decisão: conselho de LLMs de 29/10/2026, rodado sobre prints do jogo atual (`tools/capturar_prints.gd` + `tools/capturar_telas.sh`). Uma rodada anterior usou a revisão visual de 27/10, já desatualizada (monstros e chefes já têm arte), e foi descartada.

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
| 1 | **Vitória com o chefe:** nome certo ("Você derrotou o Compasso!"), sprite do chefe com carimbo "DERROTADO" e contagem da tinta | Sim (carimbo) | Não |
| 2 | **Hub Lutar com o chefe do capítulo:** silhueta "???" antes de vencer, colorido depois; melhor página e chefe vencido por capítulo | Sim (reaproveita sprites) | Não |
| 3 | **Álbum de chefes / adesivos** (os 10 chefes como coleção) + poucas conquistas | Sim | Parcial |
| 4 | **Legibilidade no chefe:** números de dano e tiros não cobrem o chefe | Não | Não |
| 5 | **Primeiros minutos:** dica das gotas de tinta; pedido de avaliação após vitória | Não | Não |
| 6 | **Prints da loja novos** com vitória e hub | Sim | Não |
| 7 | **Depois da produção:** Ascensão, maratona de chefes, gasto de tinta extra (níveis, cosméticos), sons e música variada | — | Sim |
