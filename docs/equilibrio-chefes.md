# Equilíbrio dos chefes — bateria de testes

Meta (Richard, 28/10/2026): **cada chefe mais forte que o anterior**. Luta de 30 a 60 s.

## Como medir
- `tools/bateria_chefes.gd`: um robô joga cada chefe, sem tela e acelerado (`--headless --fixed-fps 60`, ~5 min para 180 lutas). Caneta com 9999 vidas para contar o dano; luta cortada em 150 s.
- Robôs: **esquiva** (desvia de tiros, zonas, paredes, folhas e mergulhos; mira antecipando o movimento do chefe), **segue** (só persegue o chefe), **parado** (fica em x = 540).
- Cenários: **zerado** (Estojo 1/1/1) e **progressão** (níveis D/H/C na vitória de cada capítulo, da tabela B do `tools/sim_economia.py`). Sem upgrades da roleta.
- 3 sementes por combinação. Rodar os 3 robôs em paralelo e resumir com `python tools/resumo_bateria.py <pasta>`.
- Limite do robô: mira pior que uma pessoa em alvo rápido (aproveitamento baixo no Avião, na Mancha e no Tsuru). Por isso o tempo de luta usa o **melhor** dos 3 robôs.

## Resultado 1 (28/10/2026, antes dos ajustes) — cenário progressão
| Cap. | Chefe | Vida | Tempo (melhor robô) | Dano/min (esquiva) | Corações perdidos (esquiva) / vidas | Parado perde |
|---|---|---|---|---|---|---|
| 1 | Borrão | 300 | 28 s | 2,9 | 1,3 / 6 | 6 |
| 2 | Avião | 378 | 29 s | 5,4 | 10,3 / 7 | 4 |
| 3 | Mancha | 476 | 51 s | 9,9 | 19,7 / 7 | 21 |
| 4 | Grade | 600 | 34 s | 12,7 | 7,3 / 8 | 18 |
| 5 | Compasso | 756 | **14 s** | 2,8 | 0,7 / 9 | 3 |
| 6 | Pirata | 952 | 24 s | 9,1 | 4,0 / 10 | 22 |
| 7 | Tsuru | 1200 | 77 s | 4,8 | 7,0 / 11 | 74 |
| 8 | Fantasma | 1512 | 34 s | 7,9 | 4,7 / 12 | 20 |
| 9 | Pena | 1905 | 28 s | 10,4 | 9,3 / 12 | 15 |
| 10 | Estojo | 2401 | **24 s** | 7,1 | 3,3 / 13 | 11 |

No cenário zerado só o Borrão, a Grade e o Compasso morrem em 150 s (os demais exigem Estojo melhorado, como esperado).

## Achados
1. **A dificuldade não sobe com o capítulo.** Dano por minuto: 2,9 → 5,4 → 9,9 → **12,7** → **2,8** → 9,1 → 4,8 → 7,9 → 10,4 → 7,1. A Grade (4) é a que mais machuca; o Compasso (5) e o Tsuru (7) quase não ameaçam; o Estojo (10), chefe final, é mediano.
2. **A vida dos chefes não acompanha a caneta.** A vida sobe 1,26× por capítulo (300 → 2401, 8×), mas o dano por segundo da caneta na progressão sobe 14× (13 → 194). Resultado: Compasso morre em 14 s e o Estojo em 24 s.
3. **Mancha (3) fora da curva:** pedaços pequenos e rápidos (até ~360 px/s, também na vertical): só 9% dos tiros acertam e quem fica parado perde 21 corações. Difícil demais para o capítulo 3.
4. **Compasso (5) fácil demais de acertar:** fica parado girando e tem as pernas como área extra; 86% dos tiros acertam.
5. **"Ficar parado não compensa" funciona** em 9 de 10 chefes (parado perde 2 a 10× mais). Exceção: Avião, onde o parado perde menos (fica no meio e os rasantes têm brecha larga) — aceitável.

## Proposta de ajuste (aguardando decisão)
- **Vida por chefe** (multiplicador na ficha), para a duração subir de 30 s (cap. 1) a 55 s (cap. 10): Borrão ×1,1, Avião ×1,1, Mancha ×0,7, Grade ×1,1, Compasso ×2,9, Pirata ×1,8, Tsuru ×0,6, Fantasma ×1,5, Pena ×1,8, Estojo ×2,3.
- **Pressão em ordem crescente:** Mancha mais lenta (pedaços a ~60% da velocidade), Grade com leque de 3 tiros e aviso de 1,4 s, Compasso com descanso menor e mais perseguidoras, Tsuru com ataques de asa fechada mais fortes, Estojo com passeio menor e leque de 5 tiros.
- Rodar a bateria de novo e só seguir para o build quando a curva subir de chefe em chefe.

## Conselho de LLMs (28/10/2026): "só mais vida" ou "mecânicas novas"?
- **Consenso (5 de 5):** não só vida (luta mais longa = tédio e mais variância) e não mecânica nova em massa antes da produção. O problema é de **ordem e economia**, não de falta de conteúdo: caneta 14x × chefe 8x; Mancha (3) é parede onde a retenção se decide; Compasso (5) é presente.
- **Choque:** reordenar os chefes (barato, mas o Estojo reaproveita ataques e a história dos capítulos muda) × corrigir os pontos fora da curva no lugar. E criar modos de fim de jogo agora (Ascensão, rush de chefes) × só depois de haver dados humanos.
- **Pontos cegos da revisão:** o robô joga sem roleta e só com o Estojo esperado (falta medir com roleta e Estojo ±2); poucas lutas por chefe; falta dado humano (o painel "Stats de teste" pode contar vitórias e derrotas por capítulo, e os testadores mandam print); clareza (Tsuru fechado, sombra do Fantasma e "com raiva" precisam ser óbvios no celular).
- **Recomendação:** meta de duração (vida por chefe) + pressão crescente com os botões que já existem + corrigir só Mancha, Compasso, Tsuru e Estojo + clareza; mecânica de fim de jogo (Ascensão) fica para a 1ª atualização depois da produção.
