# Revisão visual e de legibilidade (27/10/2026)

Página com prints: https://claude.ai/artifact/7dyKLa9FEkmNdMGMqtxCp2
Prints de todas as telas: `Documentos\Sketch Blade - loja\revisao-telas\` (gerados por script, 1080x1920).

## Achados
| # | Tela | Problema | Gravidade |
|---|---|---|---|
| 1 | Roleta (`Main._criar_menu_upgrades`) | 3 cartas estreitas; descrição 18 px, nome 28 px; efeito fora da carta; metade inferior vazia | Crítico |
| 2 | Popup de compra (Hub) | Sem fundo opaco: ilustração do capítulo e setas por cima do texto | Crítico |
| 3 | Derrota/vitória (Main) | "Capítulo 1" e "[ JOGAR ]" da tela inicial aparecem por trás | Crítico |
| 4 | HUD combate | Vida/tinta pequenos, sem coração; "Página" fino | Alto |
| 5 | Combate | Tiro é tracinho de 2-3 px; inimigos comuns são círculos | Alto |
| 6 | Combate | Inimigos/chefe procedurais destoam da arte dos ícones | Médio (opcional) |
| 7 | Resultados | 5 linhas iguais, sem destaque do total | Médio |
| 8 | Configurações | Botão "[ STATS DE TESTE ]" visível ao jogador | Alto |
| 9 | Imagens | 30 PNGs até 1254 px sem compressão, ~209 MB de memória de vídeo; roleta segura ~100 MB na página 7 (provável causa do fechamento) | Alto |

Bom: descanso, missões, recompensa diária (36-46 px, bom contraste).

## Tamanho mínimo de texto
Descrições/rótulos 36 px; texto corrido 42-44 px; títulos mantidos. Fontes abaixo de 30 px hoje: `Main.gd` 1164/1173/1182/1432/1814/1848, `Hub.gd` 198/439/818/1117/1221/1741, `main.tscn:100`.

## Plano
1. Sobreposições (2, 3) e esconder botão de teste (8).
2. Texto maior + roleta redesenhada (1).
3. Imagens no tamanho de tela, originais em `Documentos\Sketch Blade - arte original` (9).
4. HUD e tiro mais visíveis (4, 5).
5. Versão 4 (inclui checkpoint por página) no teste fechado.
6. Opcional: arte de inimigos e chefe (6).
