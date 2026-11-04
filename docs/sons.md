# Sons do jogo

Fonte única dos sons gravados (`assets/sons/`). Lote 1 escolhido pelo Richard em 29/10/2026 (página https://claude.ai/artifact/YUAvgQ6UbbRQ3YMqvN3db4); lote 2 em 04/11/2026 (página https://claude.ai/artifact/PtD7fRSm5DoAnKG76TunLb, **aguardando o ouvido do Richard**). **Só CC0 ou gerado por nós** (Suno no plano pago do Richard, ou código): nada que peça crédito. Originais ficam fora do repositório, em `C:\Users\joalh\Videos\sons sketch blade\` (pastas numeradas; os pacotes baixados têm `_licenca.txt`).

## Partida
| Arquivo | Momento | Origem | Licença |
|---|---|---|---|
| `gota.ogg`, `gota_2..4.ogg` | pegar gota (sorteia) | Kenney, Interface Sounds, `drop_002/001/003/004` | CC0 |
| `morte.ogg`, `morte_2..8.ogg` | monstro morre (sorteia; chefe usa `morte` grave) | EZduzziteh, Squish Sounds Effects (8 arquivos) | CC0 |
| `dano_1..3.ogg` | caneta toma dano (sorteia) | krb21, *tossing pen down* (Freesound 118618), 3 quedas | CC0 |
| `coracao_lento.ogg` | loop enquanto a caneta está com 1 coração | gerado por `tools/sons_lote2.py` | nosso |
| `acerto.ogg` | tiro da caneta acerta | gerado por código ("tup" 460→140 Hz) | nosso |
| `pagina.ogg` | página concluída | Beussa, *Page turned* (Freesound 749880) | CC0 |
| `contagem_bipe.ogg`, `contagem_ja.ogg` | 3-2-1-JÁ na volta da pausa | steel2008, *Race Start Ready go* (Freesound 231277) | CC0 |
| `pausa.ogg`, `retomar.ogg` | abrir a pausa / CONTINUAR | crisstanza, *pause*/*unpause* (Freesound 167127/167126) | CC0 |
| `roleta.ogg` | roleta abre | Joao_Janz, *Roulette Wheel Spin Loop* (Freesound 482663) | CC0 |
| `carta.ogg` | escolher carta; subir de nível no hub | Kenney, Interface Sounds, `confirmation_002` | CC0 |
| `folha.ogg` | descanso abre; trocar capítulo no hub | Vvix, *turning paper pages #5* (Freesound 751980) | CC0 |
| `cura.ogg` | descanso: escolher cura | Suno (Sounds, v6), plano pago do Richard | nosso |
| `bonus.ogg` | descanso: escolher tinta; bônus do anúncio | MSH443PL8, *BLING* (Freesound 796125) | CC0 |
| `vitoria.ogg` | capítulo concluído | Suno (Sounds, v6), plano pago | nosso |
| `derrota.ogg` | página arruinada | Suno (Sounds, v6), plano pago (1º som do arquivo; o 2º ficou como opção na página) | nosso |

## Chefe
| Arquivo | Momento | Origem | Licença |
|---|---|---|---|
| `chefe_surge.ogg` | CUIDADO: BOSS! | noahpardo *Deep Growl 1* (345733) + uzerx *SUB A#* (63138), mistura | CC0 |
| `chefe_ataque.ogg` + `rasante.ogg` | rasante e mergulhos (rosnado + vento; no máx. 1 a cada 1,5 s, `Main.tocar_rosnado_ataque`) | AuDRoger *snarl 2* (471208) + D4XX *Swoosh 3* (607250) | CC0 |
| `asas.ogg` | junto do rasante do Tsuru e da Pena | Godowan *wings2* (240469) | CC0 |
| `krw.ogg` | aviso antes do mergulho do chefe-base | RutgerMuller *Vocal Creepy krw* (50923) | CC0 |
| `cuspe.ogg` | todo tiro de chefe (`Boss.atirar`; no máx. 1 a cada 0,12 s, tom 0,9–1,15) | Breviceps *Spitting a watermelon seed* (477782) | CC0 |
| `coracao_rapido.ogg` | chefe com raiva (4 batidas no andamento da música do chefe) | gerado por `tools/sons_lote2.py` | nosso |

## Hub
| Arquivo | Momento | Origem | Licença |
|---|---|---|---|
| `clique.ogg` | botões (hub e pausa) | dslrguide *Retractable Pen Click* (321484), só o clique de entrada | CC0 |
| `erro.ogg` | clique que não pode; anúncio que falhou | UsuarioLeal *cerrar algo* (446463) | CC0 |
| `ziper.ogg` | abrir a aba ESTOJO | Lay123344455566778 *ZIPER* (394081) | CC0 |
| `compra.ogg` | melhoria do Estojo, caneta comprada, compra concluída | Kenney, RPG Audio, `handleCoins` | CC0 |
| `check.ogg` | coletar missão e recompensa diária | jakobhandersen *pencil_check_mark_1* (181052) | CC0 |
| `aviso.ogg` | janela de versão nova | Kenney, Interface Sounds, `glass_001` | CC0 |

Música: `assets/musica/` (ver `plano-musica-adaptativa.md`).

## Regras
- **Disparo da caneta: sem som** (atira sozinha várias vezes por segundo).
- Ainda com bipe gerado por código: ataques e tiros próprios de cada chefe (`_som` em `chefes/*.gd`), zonas de bomba/grade, troca de fase do Estojo.
- Tratamento (`tools/sons_lote2.py`): corta o silêncio do começo, fade no fim, nivela pelo volume médio da parte com som (mesmas referências do lote 1: gota −12, morte −20, dano −16, página −17,6, clique −16, chefe −15/−18,7, jingles −16,6/−17,3) com limitador de picos; OGG Vorbis q4, mono, 44,1 kHz. Os 43 arquivos somam ~470 KB.
- Licença: conferida na página de cada som (Freesound/OpenGameArt). Ficaram de fora por pedirem crédito (CC-BY): airplane flyby, heartbeat fast, completed, fail jingle, magic healing, coins, soft notification, level-up (reenvio de rhodesmas) e cash register (mistura uma moeda CC-BY). Ficaram de fora por falta de link: bubble pop, splat, heartbeat e wet-splat.
- Suno, modo **Sounds**: cada download gasta 1 dos 20 do mês (plano Pro, não acumula). Gerar e ouvir no site é grátis: baixar só o melhor. Palavras que encurtam: *ultra short, instant, UI sound, one-shot stinger, ends abruptly, no reverb tail*.
- Sons que tocam muito: variações sorteadas sem repetir a última (`Main.VARIACOES`) e tom variando.
