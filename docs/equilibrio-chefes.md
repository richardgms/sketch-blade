# Equilíbrio dos chefes — bateria de testes

Meta (Richard, 28/10/2026): **cada chefe mais forte que o anterior**. Luta de 30 a 60 s.

## Como medir
- `tools/bateria_chefes.gd`: um robô joga cada chefe, sem tela e acelerado (`--headless --fixed-fps 60`, ~5 min para 180 lutas). Caneta com 9999 vidas para contar o dano; luta cortada em 150 s.
- Robôs: **esquiva** (desvia de tiros, zonas, paredes, folhas e mergulhos; mira antecipando o movimento do chefe), **segue** (só persegue o chefe), **parado** (fica em x = 540).
- Cenários: níveis D/H/C do Estojo na **chegada** (1ª vez no capítulo) e na **vitória** de cada capítulo, tirados da tabela B do `tools/sim_economia.py` (ouro por run + preços da loja); com ou sem as **3 roletas** da run (páginas 2, 4 e 6: sorteio igual ao do jogo; o robô escolhe pela preferência de um jogador típico, 30% das vezes por gosto). Cada luta tem uma build diferente.
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

## Resultado final (28/10/2026, rodada 9) — calibrado
Ajustes: vida por chefe na ficha (`Boss.FICHAS[cap]["vida"]`, multiplica a escala 1,26×/capítulo), Mancha mais lenta, Tsuru com 2 leques por janela aberta e ataques fechados maiores, cópias do Fantasma atirando a cada 2,3 s, Estojo com menos pausa entre ataques, e sinal de raiva (ver `chefes.md`).
Cenário: Estojo da **chegada** + 3 roletas, robô de esquiva, 10 builds por chefe. Margem da bateria: **±15%** entre rodadas (a build muda muito o resultado); ajustes menores que isso não se medem.
| Cap. | Chefe | Vida (×) | Vida final | Tempo médio (faixa) | Corações perdidos | Morreria |
|---|---|---|---|---|---|---|
| 1 | Borrão | 1,0 | 300 | 34 s (27–50) | 42% | 1/10 |
| 2 | Avião | 1,0 | 378 | 41 s (23–72) | 54% | 0/10 |
| 3 | Mancha | 0,65 | 309 | 47 s (20–84) | 49% | 1/10 |
| 4 | Grade | 1,2 | 720 | 29 s (19–36) | 54% | 1/10 |
| 5 | Compasso | 4,2 | 3175 | 45 s (30–58) | 51% | 1/10 |
| 6 | Pirata | 1,6 | 1524 | 35 s (24–53) | 68% | 1/10 |
| 7 | Tsuru | 0,85 | 1020 | 55 s (36–81) | 74% | 1/10 |
| 8 | Fantasma | 1,3 | 1966 | 47 s (25–63) | 73% | 1/10 |
| 9 | Pena | 1,6 | 3049 | 54 s (41–86) | 76% | 3/10 |
| 10 | Estojo | 3,2 | 7684 | 70 s (43–101) | 80% | 4/10 |

Leitura: capítulos 1–5 ≈ metade dos corações; 6–10 de 68% a 80%, com o Estojo como o mais forte. Com o Estojo da **vitória** tudo fica mais leve (o jogador que repetiu o capítulo passa). Mancha continua a mais dependente da build (20–84 s). Próximo: confirmar no celular com humanos.

## Resultado 2 (28/10/2026) — com roleta (build sorteada) e Estojo da chegada
300 lutas, 5 builds por chefe. "Morreria" = lutas em que o robô de esquiva perde mais corações do que tem.
| Cap. | Chefe | Tempo (esquiva) | Variação entre builds | Dano/min | Corações perdidos / vidas | Morreria |
|---|---|---|---|---|---|---|
| 1 | Borrão | 33 s | 28–43 s | 2,9 | 1,6 / 5 | 0/5 |
| 2 | Avião | 32 s | 24–45 s | 5,6 | 3,0 / 7 | 0/5 |
| 3 | Mancha | **66 s** | 29–98 s | 6,0 | **6,6 / 7** | **2/5** |
| 4 | Grade | 25 s | 23–31 s | 6,3 | 2,6 / 8 | 0/5 |
| 5 | Compasso | **11 s** | 7–15 s | 6,7 | 1,2 / 9 | 0/5 |
| 6 | Pirata | 21 s | 19–23 s | 7,5 | 2,6 / 9 | 0/5 |
| 7 | Tsuru | 65 s | 47–87 s | **4,6** | 5,0 / 11 | 0/5 |
| 8 | Fantasma | 37 s | 31–45 s | **11,4** | 7,0 / 11 | 1/5 |
| 9 | Pena | 29 s | 23–39 s | 8,3 | 4,0 / 12 | 0/5 |
| 10 | Estojo | **21 s** | 18–25 s | 9,2 | 3,2 / 13 | 0/5 |

**O que a roleta mudou:** leque e tiro duplo cobrem chefe que se move (Avião: 117 s sem roleta → 32 s com). Com a build real, a **pressão (dano/min) já sobe quase em ordem** (2,9 → 9,2), com 2 exceções: Tsuru baixo e Fantasma alto. O problema passa a ser outro: **a partir do cap. 4 as lutas são curtas e seguras** (perde de 13% a 33% dos corações), e o chefe final morre em 21 s. Mancha continua fora da curva (longa, letal e muito dependente da build: 29–98 s).

## Achados do resultado 1 (sem roleta)
1. **A dificuldade não sobe com o capítulo.** Dano por minuto: 2,9 → 5,4 → 9,9 → **12,7** → **2,8** → 9,1 → 4,8 → 7,9 → 10,4 → 7,1. A Grade (4) é a que mais machuca; o Compasso (5) e o Tsuru (7) quase não ameaçam; o Estojo (10), chefe final, é mediano.
2. **A vida dos chefes não acompanha a caneta.** A vida sobe 1,26× por capítulo (300 → 2401, 8×), mas o dano por segundo da caneta na progressão sobe 14× (13 → 194). Resultado: Compasso morre em 14 s e o Estojo em 24 s.
3. **Mancha (3) fora da curva:** pedaços pequenos e rápidos (até ~360 px/s, também na vertical): só 9% dos tiros acertam e quem fica parado perde 21 corações. Difícil demais para o capítulo 3.
4. **Compasso (5) fácil demais de acertar:** fica parado girando e tem as pernas como área extra; 86% dos tiros acertam.
5. **"Ficar parado não compensa" funciona** em 9 de 10 chefes (parado perde 2 a 10× mais). Exceção: Avião, onde o parado perde menos (fica no meio e os rasantes têm brecha larga) — aceitável.

## Proposta de ajuste (atualizada com o resultado 2; aplicada, ver resultado final)
- Meta: fração de corações perdidos na **chegada** subindo de ~25% (cap. 1) a ~75% (cap. 10), com lutas de 25 s a 60 s. Como a pressão já sobe, a vida vira o botão principal: luta mais longa contra chefe mais agressivo = mais perigo, em ordem.
- Exceções: Mancha (pedaços mais lentos, luta mais curta), Tsuru (mais pressão de asa fechada, luta mais curta), Fantasma (pressão um pouco menor), Compasso (vida bem maior).

### Proposta anterior (resultado 1)
- **Vida por chefe** (multiplicador na ficha), para a duração subir de 30 s (cap. 1) a 55 s (cap. 10): Borrão ×1,1, Avião ×1,1, Mancha ×0,7, Grade ×1,1, Compasso ×2,9, Pirata ×1,8, Tsuru ×0,6, Fantasma ×1,5, Pena ×1,8, Estojo ×2,3.
- **Pressão em ordem crescente:** Mancha mais lenta (pedaços a ~60% da velocidade), Grade com leque de 3 tiros e aviso de 1,4 s, Compasso com descanso menor e mais perseguidoras, Tsuru com ataques de asa fechada mais fortes, Estojo com passeio menor e leque de 5 tiros.
- Rodar a bateria de novo e só seguir para o build quando a curva subir de chefe em chefe.

## Conselho de LLMs (28/10/2026): "só mais vida" ou "mecânicas novas"?
- **Consenso (5 de 5):** não só vida (luta mais longa = tédio e mais variância) e não mecânica nova em massa antes da produção. O problema é de **ordem e economia**, não de falta de conteúdo: caneta 14x × chefe 8x; Mancha (3) é parede onde a retenção se decide; Compasso (5) é presente.
- **Choque:** reordenar os chefes (barato, mas o Estojo reaproveita ataques e a história dos capítulos muda) × corrigir os pontos fora da curva no lugar. E criar modos de fim de jogo agora (Ascensão, rush de chefes) × só depois de haver dados humanos.
- **Pontos cegos da revisão:** o robô joga sem roleta e só com o Estojo esperado (falta medir com roleta e Estojo ±2); poucas lutas por chefe; falta dado humano (o painel "Stats de teste" pode contar vitórias e derrotas por capítulo, e os testadores mandam print); clareza (Tsuru fechado, sombra do Fantasma e "com raiva" precisam ser óbvios no celular).
- **Recomendação:** meta de duração (vida por chefe) + pressão crescente com os botões que já existem + corrigir só Mancha, Compasso, Tsuru e Estojo + clareza; mecânica de fim de jogo (Ascensão) fica para a 1ª atualização depois da produção.
