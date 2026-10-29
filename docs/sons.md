# Sons do jogo

Fonte única dos sons gravados (`assets/sons/`). Escolhidos pelo Richard em 29/10/2026 ouvindo a página https://claude.ai/artifact/YUAvgQ6UbbRQ3YMqvN3db4. Todos com licença **CC0** (domínio público: uso comercial livre, crédito não obrigatório). Originais baixados do OpenGameArt (o kenney.nl bloqueia download automático); ficam fora do repositório.

| Arquivo | Momento | Origem (autor, pacote, arquivo) | Tratamento |
|---|---|---|---|
| `gota.ogg` | pegar gota de tinta | Kenney, Interface Sounds, `drop_002` | volume -22 LUFS (toca muito) |
| `morte.ogg` | monstro morre (e chefe morre, tom mais grave) | EZduzziteh, Squish Sounds Effects, `squish_02` | -20 |
| `dano.ogg` | caneta toma dano | Kenney, Interface Sounds, `error_004` | -18 |
| `pagina.ogg` | página concluída; trocar capítulo no hub | Kenney, RPG Audio, `bookFlip1` | -18 |
| `clique.ogg` | botões do hub e da pausa | Kenney, Interface Sounds, `select_002` | -20 |
| `chefe_surge.ogg` | chefe aparece na página 8 | StarNinjas, 16 Monster Growls, `monster.8` (tom 0,8×) + NenadSimic, Muffled Distant Explosion | mistura, 1,6 s, -20 |
| `chefe_ataque.ogg` | chefe desce para atacar (rasante do Avião, mergulhos de Pena, Tsuru e do chefe-base) | Darsycho, Monster Snarls, `monster-snarl-attack` (1º rosnado) | 1,3 s, -21; no máx. 1 a cada 1,5 s (`Main.tocar_rosnado_ataque`) |
| `vitoria.ogg` | capítulo concluído | Kenney, Music Jingles, `jingles_PIZZA02` | -18 |
| `derrota.ogg` | página arruinada | Kenney, Music Jingles, `jingles_PIZZA01` | -18 |

## Regras
- **Disparo da caneta: sem som** (atira sozinha várias vezes por segundo; viraria barulho constante).
- **Monstro atingido**: precisa ser muito curto (até 0,12 s), baixo (-26) e com limite de repetições. Em escolha.
- Ainda com bipe gerado por código (`_gerar_som_procedural`): clique de erro, descanso, roleta, bônus do anúncio, raiva do chefe, tiros e ataques próprios de cada chefe.
- Volume nivelado com `loudnorm` do ffmpeg; OGG Vorbis q4, mono, 44,1 kHz. Os 9 arquivos somam ~112 KB.
- Vitória e derrota foram pré-escolhidas por análise da melodia (sobe = vitória, desce = derrota) entre os 85 jingles do Kenney.
