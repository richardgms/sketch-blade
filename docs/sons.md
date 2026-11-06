# Sons do jogo

Fonte única dos sons gravados (`assets/sons/`). Lote 1 escolhido pelo Richard em 29/10/2026 (página https://claude.ai/artifact/YUAvgQ6UbbRQ3YMqvN3db4); lote 2 em 04/11/2026 (página https://claude.ai/artifact/PtD7fRSm5DoAnKG76TunLb, **aprovado pelo Richard em 04/11, com os ajustes abaixo**). **Só CC0 ou gerado por nós** (Suno no plano pago do Richard, ou código): nada que peça crédito. Originais ficam fora do repositório, em `C:\Users\joalh\Videos\sons sketch blade\` (pastas numeradas; os pacotes baixados têm `_licenca.txt`).

## Partida
| Arquivo | Momento | Origem | Licença |
|---|---|---|---|
| `gota.ogg`, `gota_2..4.ogg` | pegar gota (sorteia) | Kenney, Interface Sounds, `drop_002/001/003/004` | CC0 |
| `morte.ogg`, `morte_2..6.ogg` | monstro morre (sorteia; chefe usa `morte` grave) | EZduzziteh, Squish Sounds Effects (6 arquivos; 7 e 8 removidos a pedido do Richard em 04/11) | CC0 |
| `dano_1..3.ogg` | caneta toma dano (sorteia) | krb21, *tossing pen down* (Freesound 118618), 3 quedas | CC0 |
| `coracao_lento.ogg` | loop enquanto a caneta está com 1 coração | gerado por `tools/sons_lote2.py` | nosso |
| `acerto.ogg` | tiro da caneta acerta | gerado por código ("tup" 460→140 Hz) | nosso |
| `pagina.ogg` | página concluída | Beussa, *Page turned* (Freesound 749880) | CC0 |
| `contagem_bipe.ogg`, `contagem_ja.ogg` | 3-2-1-JÁ na volta da pausa; marimba aprovada em 04/11 | GAMEDRIX974, *marimba f1*, original `marimba tick.wav`; JÁ com oitava + quinta + nota original | CC0 |
| `pausa.ogg`, `retomar.ogg` | abrir a pausa / CONTINUAR | crisstanza, *pause*/*unpause* (Freesound 167127/167126) | CC0 |
| `roleta.ogg` | roleta abre | Joao_Janz, *Roulette Wheel Spin Loop* (Freesound 482663) | CC0 |
| `carta.ogg` | escolher carta; subir de nível no hub | Kenney, Interface Sounds, `confirmation_002` | CC0 |
| `folha.ogg` | descanso abre; trocar capítulo no hub | Vvix, *turning paper pages #5* (Freesound 751980) | CC0 |
| `cura.ogg` | descanso: escolher cura | Suno (Sounds, v6), plano pago do Richard | nosso |
| `bonus.ogg` | descanso: escolher tinta; bônus do anúncio | MSH443PL8, *BLING* (Freesound 796125) | CC0 |
| `vitoria.ogg` | capítulo concluído | Suno (Sounds, v6), plano pago | nosso |
| `derrota.ogg` | página arruinada | Suno (Sounds, v6), plano pago; arquivo inteiro, com os dois trechos juntos (3,57 s), conforme pedido do Richard | nosso |

## Chefe
| Arquivo | Momento | Origem | Licença |
|---|---|---|---|
| `chefe_surge.ogg` | CUIDADO: BOSS! | noahpardo *Deep Growl 1* (345733) + uzerx *SUB A#* (63138), mistura | CC0 |
| `chefe_ataque.ogg` + `rasante.ogg` | rasante e mergulhos (rosnado + vento; no máx. 1 a cada 1,5 s, `Main.tocar_rosnado_ataque`) | AuDRoger *snarl 2* (471208) + D4XX *Swoosh 3* (607250) | CC0 |
| `asas.ogg` | junto do rasante do Tsuru e da Pena | Godowan *wings2* (240469) | CC0 |
| `krw.ogg` | chefe incha antes de atirar o leque (`Boss._avisar_leque`); o mergulho do chefe-base mantém o bipe procedural | RutgerMuller *Vocal Creepy krw* (50923) | CC0 |
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
- Tratamento (`tools/sons_lote2.py`): corta o silêncio do começo, fade no fim, nivela pelo volume médio da parte com som (mesmas referências do lote 1: gota −12, morte −20, dano −16, página −17,6, clique −16, chefe −15/−18,7, jingles −16,6/−17,3) com limitador de picos; OGG Vorbis q4, mono, 44,1 kHz. Os 40 arquivos atuais somam 357.183 bytes (~349 KiB).
- Licença: conferida na página de cada som (Freesound/OpenGameArt). Ficaram de fora por pedirem crédito (CC-BY): airplane flyby, heartbeat fast, completed, fail jingle, magic healing, coins, soft notification, level-up (reenvio de rhodesmas) e cash register (mistura uma moeda CC-BY). Ficaram de fora por falta de link: bubble pop, splat, heartbeat e wet-splat.
- Suno, modo **Sounds**: cada download gasta 1 dos 20 do mês (plano Pro, não acumula). Gerar e ouvir no site é grátis: baixar só o melhor. Palavras que encurtam: *ultra short, instant, UI sound, one-shot stinger, ends abruptly, no reverb tail*.
- Sons que tocam muito: variações sorteadas sem repetir a última (`Main.VARIACOES`) e tom variando.

## Comparação da contagem (04/11)
- A mesma página do lote 2 já foi atualizada pelo Claude em 04/11 às 03:32: https://claude.ai/artifact/PtD7fRSm5DoAnKG76TunLb (publicação confirmada no histórico, versão `1793773943-052e`). Inclui as seis mortes, o novo momento do krw, a derrota inteira e a comparação de contagens.
- Marimba: GAMEDRIX974, *marimba f1* (CC0), original `01 gota de tinta/marimba tick.wav`. Demonstração com 1 s por número e um JÁ mais agudo (oitava + quinta). **Aprovada e ligada no jogo para o build 1.8.0 (15)**, preservando exatamente os arquivos ouvidos (cópia sem recodificação). O gerador passou a usar a mesma receita em `contagem_marimba()`; os dois OGG regenerados foram decodificados e comparados com os aprovados, com diferença zero entre amostras. O som anterior de steel2008 saiu da contagem.
- Os 39 áudios referenciados na cópia local da página foram conferidos: nenhum ausente; morte 7/8 e derrota separada não são referenciados.

## Validação da retomada (04/11)
- `tools/teste_sons_partida.gd`: 7 verificações passaram, incluindo krw no inchar, bipe do mergulho sem krw, seis mortes, coração, sorteio e pausa/contagem.
- `tools/bateria_chefes.gd`: capítulos 1, 4 e 7, robô `esquiva`, uma seed, cenário `vitoria`: três lutas concluídas, código de saída 0, sem erros de script. Testes sem tela não validam a qualidade ou a mixagem de ouvido.
- Backup do save feito antes; restauração no `finally` com bytes/hash conferidos. Logs e backup em `%TEMP%/sketch-blade-continuacao-ixm1wnmj/`.
- O Godot 4.7 emitiu avisos de recursos ao encerrar os testes. A primeira importação saiu com código 0; uma repetição encerrou nativamente com `0xC0000005`, sem erro de script reportado. Os testes acima foram executados depois, usando a importação concluída. Causa da falha nativa não investigada nesta revisão de sons.
- Commits desta revisão ficam locais: a branch já contém mudanças anteriores no `Hub.gd` que trata compras, e o push segue aguardando autorização conforme as regras do projeto.

## Mixagem de mortes e Estojo — 04/11/2026
- Mortes comuns e do chefe passam pelo bus `MortesMonstros`: −7 dB por player,
  EQ6 com ganhos −12/−4/−1/−4,5/−3/−2 dB (32/100/320/1000/3200/10000 Hz),
  compressor limiar −24 dB, razão 3:1, ataque 6 ms, release 100 ms, sem makeup.
  Reduz sopro e caráter vocal; pitch limitado a 0,88–1,02 e intervalo mínimo
  de 80 ms evita empilhar mortes simultâneas. Assets originais preservados.
- Estojo soma `clique.ogg` ao `ziper.ogg`; outras abas mantêm clique.
- Teste de roteamento, ganho, antissobreposição e cliques: zero falhas.
  Qualidade subjetiva ainda depende da escuta no celular.
- Referência de bandas: [AudioEffectEQ6 oficial](https://docs.godotengine.org/en/stable/classes/class_audioeffecteq6.html).

## Vida crítica equilibrada — opção 1 aprovada e implementada (04/11/2026)
- Gatilho: 1 coração. `VidaCritica.gd` coordena som e estado; vinheta acompanha
  a reprodução do heartbeat em `AlertaVida.gd` (sem relógios visuais separados).
- Novo `coracao_critico.ogg`: dupla batida em ciclo de 0,85 s, ataques em 0 e
  0,16 s, harmônicos para celular; entrada de ganho 0,12 s, saída de cura 0,9 s.
- `zumbido_critico.ogg`: pressão/ruído ressonante de 1,2 s, faixa principal de
  180–1800 Hz, sem apito puro sustentado. Toca uma vez na entrada crítica;
  atualizar HUD/dano bloqueado não o reinicia. Na cura, cauda cai suavemente.
- Música da partida e do chefe: −4 dB e passa-baixa suave de 5 kHz, entrada
  0,3 s, saída 0,9 s. Pai `MusicaVidaCritica` exclusivo da música; efeitos,
  heartbeat e alertas de ataques não passam por ele. A mistura crítica compõe
  com fades da partida/chefe, raiva e a atenuação da tela de reviver.
- Pausa/roleta/descanso suspendem os sons sem repetir o impacto ao voltar.
  Morte/vitória/saída/som desligado limpam o tratamento. Religar som ou retomar
  run já com 1 coração entra sem novo impacto. A vinheta continua independente
  do botão de som e preserva aviso visual para quem joga sem áudio.
- Síntese original e determinística, sem API: `tools/gerar_audio_vida_critica.py`.
  Masters mono 44,1 kHz/PCM24, sem recompressão, arquivados em
  `Documentos/Sketch Blade - audio/vida-critica/`; uso no jogo em OGG q8.
  Pico/RMS antes da codificação: heartbeat −5,4/−22,4 dBFS; zumbido −11/−28 dBFS
  (player do zumbido acrescenta −3 dB). Nenhum asset anterior sobrescrito.
- 06/11: com volume baixo o coração quase some (fundamental 78 Hz; alto-falante
  de celular corta abaixo de ~400 Hz). Simulando esse corte, o atual fica em
  −47,5 dB médios. Testes em `Documentos/Sketch Blade - audio/vida-critica/testes-agudo/`
  (com o gerador): 1 = mesmo coração 1,7× mais agudo (−30,3 dB), 2 = grave + "tum"
  médio de 310 Hz (−34,6), 3 = grave + toque seco de caneta (−36,5). Aguardando escolha.
- Rampas usam tempo real para acompanhar o áudio durante hitstop e quadros
  lentos. O teste de duração também mede relógio real: timers do SceneTree no
  quadro de carregamento podiam adiantar a verificação antes da reprodução.
- `tools/teste_vida_critica.gd`: 24 verificações passaram. Regressões de música,
  feedback visual e sons da partida: todos passaram, código 0. Save restaurado
  e hash conferido; testes headless ainda reportam recursos residuais ao encerrar.
  A qualidade subjetiva ainda precisa de escuta no celular.

## Correção dos jingles de resultado — 04/11/2026
- Relato: vitória e derrota não tocavam. Reproduzido nos finais reais: os
  players herdavam a pausa de Main e congelavam imediatamente após play().
- `_tocar_som` agora usa `PROCESS_MODE_ALWAYS` somente para `vitoria.ogg` e
  `derrota.ogg`. Os sons terminam nas telas pausadas e seus players são removidos
  pelo sinal finished; efeitos de combate continuam sujeitos à pausa.
- `tools/teste_sons_resultado.gd`: antes da correção, quatro falhas (nenhum dos
  dois jingles avançava ou terminava). Depois, 16 verificações passaram nos
  caminhos reais, incluindo som desligado, limpeza da vida crítica e combate
  pausado. Save restaurado e hash conferido. Importação sem erros de script;
  headless ainda reporta recursos residuais ao encerrar.
- Correção incluída no AAB 1.8.4 (19); não estava no AAB 1.8.3.

## Resgate de missão diária — 04/11/2026
`Hub._coletar_missao` toca `compra.ogg` (a mesma moedinha do upgrade do Estojo)
junto com `check.ogg` após o resgate válido. Missão incompleta ou já coletada
retorna antes dos sons; o botão geral de som continua sendo respeitado.
