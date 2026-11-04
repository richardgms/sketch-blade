# Plano de música adaptativa

Fonte única sobre a música da partida (efeitos e jingles continuam em `sons.md`). **Situação (04/11/2026): abordagem aprovada pelo Richard (leve = stem da cheia tratado). Etapa 0 ok (cheia gerada em plano pago da Suno). Etapa 1 aprovada de ouvido ("3 voltas perfeito"). Etapa 2 feita. Etapa 3 aguardando ouvido (página de escuta: https://claude.ai/artifact/W3KYzjySNFX9UeH3dwtUwS). Código do jogo ainda não mexido.** Saiu de um /brainstorming e de um /llm-council (5 conselheiros + revisão anônima).

## O que queremos
- A música da partida fica mais forte conforme a partida pesa, **sem troca de faixa perceptível** (hoje a pesada recomeça do começo e dá para ouvir).
- Ideia do Richard (mantida na essência): cada instrumento em versão leve e pesada, tudo no mesmo tempo, e o código cruza leve↔pesado e libera instrumentos no tempo certo.
- Fora de escopo agora: música do hub, música por capítulo, compras e anúncios (pausar a música no anúncio entra quando mexermos em anúncios).

## O que foi medido (04/11, por arquivo; ninguém além do Richard ouviu)
- Material em `C:\Users\joalh\Videos\sons sketch blade\26 musica\01 Sala sci-fi (escolhida)\`. Originais Suno: limpa 59,48 s, cheia 88,20 s (48 kHz estéreo). Stems do Moises com a mesma duração do original.
- Loops recortados: limpa 58,734 s = **117 batidas**; cheia 83,681 s = **167 batidas** (0,5021 s por batida = 119,49 BPM; intervalos de 0,496 a 0,508 s). Nenhum é múltiplo de 4 batidas (29¼ e 41¾ compassos): a frase pode "quebrar" a cada volta.
- **Limpa e cheia não são a mesma composição:** nota dominante do baixo por batida concorda em só ~50% no melhor alinhamento; em compassos inteiros a limpa tem Sol# onde a cheia tem Sol (semitom → choque se tocarem juntas ou em crossfade). Medição grosseira (FFT do baixo), mas suficiente para descartar misturar as duas gerações.
- Tamanho real (stem de guitarra de 83,7 s): estéreo q3 0,89 MB · q4 0,97 MB · q5 1,21 MB; mono q4 0,54 MB. Os 10 efeitos atuais somam 116 KB.

## O que o Godot 4.7 oferece (doc oficial 4.7, via Context7)
- `AudioStreamSynchronized`: até 32 sub-streams que começam juntos no mesmo playback, volume por sub-stream (`set_sync_stream_volume`). Cada um faz loop sozinho → **só fica em sincronia se todos tiverem a mesma duração exata**. Como tudo é mixado num playback só, não há defasagem entre camadas por construção (falta testar CPU e pausa no Android).
- `AudioStreamInteractive`: clipes com transição no próximo beat/compasso/fim, destino "mesma posição" (`TRANSITION_TO_TIME_SAME_POSITION`, para clipes de mesmo comprimento), crossfade em batidas, clipe de preenchimento, `switch_to_clip`. Serve para trocar músicas inteiras (ex.: chefe), não camadas.
- `AudioStreamOggVorbis`: `bpm`, `beat_count` (define o ponto de loop), `bar_beats`, `loop`, `loop_offset`.
- `AudioStreamPlaylist` existe (sequência de streams); não precisamos dele.
- Vários `AudioStreamPlayer` disparados juntos: sem garantia de amostra exata; evitar para camadas.
- A confirmar em teste: `AudioStreamSynchronized` dentro de um clipe do `AudioStreamInteractive` (útil para o chefe na fase 2).

## Decisão central (veredito do conselho)
**Uma geração só (a cheia), e as versões "leves" feitas a partir dos stems dela, tudo dentro de um `AudioStreamSynchronized`.** A ideia do Richard continua (guitarra leve/pesada, bateria leve/pesada, cruzamento no tempo certo); muda só a origem da versão leve: em vez de outra gravação, é o mesmo stem tratado fora do jogo (passa-baixa, menos volume, menos ataques), gravado como arquivo próprio com a mesma duração. Assim leve e pesada têm a mesma harmonia e o mesmo comprimento por construção, e o cruzamento é só volume.
- Unânime: misturar limpa com cheia (ou esticar pela grade) está descartado; esticar acerta o tempo, não a nota.
- Choque: o Expansionista queria música reagindo a vida, combo e um tema por capítulo; os revisores chamaram de escopo inflado para a primeira música. Fica para depois de a base funcionar.
- Pontos cegos levantados na revisão: testar primeiro se o "pulo" de hoje é o loop torto (29¼/41¾ compassos) e o recomeço da pesada; critério de aceite medível; música desligável; pausa, segundo plano e anúncio; ducking com jingles; licença comercial da Suno.

### Como garantir "mesmo tempo, mesmo ritmo" (custos)
| Caminho | Custo | Risco |
|---|---|---|
| **Leve tratada da mesma geração (escolhido)** | Zero de Suno; ~1 tarde de cortes e conversão por código | Baixo. Limite: a leve soa "abafada/menor", não um arranjo diferente |
| Cover da cheia na Suno ("soft, sparse") + Moises | Créditos Suno + Moises; 1–2 h + aprovação | Médio/alto: o Cover não mantém duração nem harmonia exatas. Só entra se passar na medição (baixo por batida ≥ 85–90% e mesma contagem de batidas depois de alinhado) |
| Alinhar/esticar limpa e cheia pela grade | Horas | **Descartado** pela medição (Sol# × Sol) |
| Compor leve/pesada à mão (DAW/MIDI) | Dias a semanas, exige DAW | Baixo musicalmente, alto em tempo. Só se o jogo pedir guitarra pesada de verdade |

## Resultado da etapa 1 (04/11)
- Grade de batidas medida direto na bateria da cheia (Moises, WAV 48 kHz): 175 batidas, 0,4789–0,5224 s entre elas; o "1" do compasso cai na batida 0 (bumbo mais forte). O metrônomo do Moises e o da "receita CapCut" não servem de régua (escorregam ~0,003 s por batida em relação ao bumbo).
- **Só existe emenda boa com 24 compassos:** batidas 52→148 (26,12 s → 74,15 s), o trecho dos 26 s se repete aos 74 s. Semelhança por instrumento 0,92–0,94 nas 16 batidas depois da emenda (par aleatório: 0,52–0,68). Com 32 ou 40 compassos nenhum ponto passou de 0,66 → descartados.
- Corte: 50 ms antes do ataque do bumbo, alinhado por correlação da bateria (ajuste de −3 ms); o início recebe 45 ms da continuação natural do fim, com cruzamento seno/cosseno (as ondas nessa janela não se parecem, correlação ≈ 0,05, então potência igual). Salto na emenda abaixo do passo normal do áudio em todas as camadas (sem clique).
- Loop = 2.305.556 amostras a 48 kHz = 48,032 s = 96 batidas (~119,92 BPM). Todas as camadas com o mesmo número de amostras.
- **Cordas quase ausentes no trecho (−54 dB RMS):** o nível do chefe precisa de outra fonte (decidir na etapa 3 ou depois).
- Estimativa de tamanho cai para ~3–4 MB (loop de 48 s).

## Resultado da etapa 2 (04/11)
- `tools/musica/camadas_jogo.py` gera as 7 camadas do jogo em `etapa 2 - camadas do jogo\` (WAV 24 bits + OGG q4 48 kHz + `musica_partida.json` com bpm 119,92, `beat_count` 96, `bar_beats` 4 e o ataque de cada batida).
- Metrônomo refeito: o clique do arquivo do Richard (1 por batida, mesmo volume) colocado no ataque real da bateria de cada batida do loop novo, de forma circular (o clique que passa do fim continua no começo).
- Versões leves: passa-baixa sem defasagem (FFT do loop inteiro, circular, então a emenda continua perfeita). Guitarra leve: corte em 900 Hz, −6 dB. Bateria leve: 1500 Hz, −4 dB. Valores iniciais, ajustáveis de ouvido.
- Cruzamento leve↔pesada **com ganho igual** (as curvas somam 1), não potência igual: as duas versões são o mesmo som, então potência igual daria um "inchaço" de +3 dB no meio.
- Medido: todas as OGG decodificam com exatamente 2.305.556 amostras; total **3,16 MB** (baixo 210 KB e metrônomo 111 KB em mono; bateria 707, bateria leve 521, guitarras 605, guitarra leve 365, outros 721 KB em estéreo). A bateria leve é quase mono (correlação E/D 0,98): dá para economizar ~200 KB se precisar.
- Etapa 3: `tools/musica/demo_niveis.py` gera `etapa 3 - niveis\TESTE niveis 1-2-3-1.ogg` (112 s: nível 2 aos 0:24, nível 3 aos 0:56, volta ao 1 aos 1:28). Volume médio: nível 1 −19,9 dB, nível 2 −17,6, nível 3 −16,9 (o degrau 2→3 é mais de brilho que de volume).
- Arquivos (fora do repo): `Videos\sons sketch blade\26 musica\01 Sala sci-fi (escolhida)\etapa 1 - loop 24 compassos\` (camadas WAV 24 bits, `corte.json`, `grade_batidas.json`, testes OGG q8). Scripts: `tools/musica/` (`grade_batidas.py`, `achar_emenda.py`, `cortar_loop.py`; rodar com uma pasta de trabalho fora do repo como argumento).

## Camadas (todas cortadas do mesmo trecho da cheia, mesma duração exata)
| Camada | Versões | Observação |
|---|---|---|
| baixo | única | mono |
| metrônomo suave (feito pelo Richard da bateria) | única | percussão leve do começo; mono |
| bateria (material escolar) | leve + pesada | leve = passa-baixa 1500 Hz e −4 dB; pesada = stem cheio |
| guitarras | leve + pesada | leve = passa-baixa 900 Hz e −6 dB; pesada = stem cheio |
| outros (efeitos alienígenas) | única | acentos; entra no fim |
| cordas | — | quase ausentes no loop (−54 dB): fora das camadas; o chefe precisa de outra fonte |

São 7 sub-streams, **3,16 MB medidos** (q4, loop de 48 s). O Godot guarda o OGG comprimido e decodifica tocando: memória ≈ tamanho do arquivo; CPU = 7 decodificações Vorbis ao mesmo tempo (**não medido**; testar no celular mais fraco disponível; se pesar, juntar baixo+metrônomo).

## Níveis de intensidade (v1: só por página; nada de oscilar)
| Nível | Quando | O que toca |
|---|---|---|
| 1 Calmo | páginas 1–2 e 4 (descanso) | baixo + metrônomo + guitarra leve |
| 2 Andando | páginas 3 e 5 | + bateria leve; guitarra leve → pesada |
| 3 Pesado | páginas 6 (elite) e 7 (horda) | bateria leve → pesada + outros |
| 4 Chefe | página 8 | tudo + cordas |

- Subir: no próximo início de compasso (4 batidas ≈ 2 s), camada entrando em 1 compasso. Cruzamento leve↔pesada: as duas ao mesmo tempo por 1 compasso, com ganho igual (curvas somando 1; ver etapa 2).
- Descer (descanso, morte do chefe): em 2 compassos.
- Histerese: com gatilho por página não há vai-e-volta. Se um dia usarmos monstros vivos ou vida baixa, subir na hora (no compasso) e só descer depois de ~8 s abaixo do limite.
- Compasso calculado pela posição real de reprodução e pela grade medida de batidas (lista em arquivo), não por 0,5 s fixo (o andamento varia ±35 ms).

## Início, pausa e fim
- **Início da partida:** toca o nível 1 desde a posição 0 com subida de volume de ~2 s (a entrada suave que o Richard gostou). Sem trecho de introdução no v1; se quiser, depois dá para pôr uma introdução no começo do arquivo e usar `loop_offset`.
- **Pausa, roleta, reviver:** `stream_paused` na música (retoma na mesma posição, todas as camadas juntas). Música em `PROCESS_MODE_ALWAYS` para os fades andarem com o jogo pausado.
- **Vitória:** música desce em ~1 s e entra o jingle `vitoria.ogg`. **Derrota:** música corta em ~0,5 s e entra `derrota.ogg`. Sem tocar jingle por cima da música (o tom dos jingles do Kenney não foi conferido com Mi menor).
- **Liga/desliga:** v1 obedece ao "Som" das configurações (`som_ativo`). Opção "Música" separada fica para decidir depois (tela de configurações é aprovada; mexer nela pede página de aprovação).
- Constante para desligar a música por código (rollback sem build de áudio novo).

## Critério de aceite (medível antes do ouvido)
- Todos os arquivos com o mesmo número de amostras.
- Loop: corte no ataque real da bateria, número de batidas múltiplo de 4 (ficou 96 = 24 compassos), sem clique na emenda (continuação do fim cruzada no começo; ficou 45 ms antes do ataque).
- No celular: nenhuma camada sai de sincronia depois de 10 min e de pausar/retomar e ir para segundo plano.
- Aprovação de ouvido do Richard em cada etapa (arquivo de teste na pasta "testes para ouvir" e página de escuta).

## Etapas (cada uma pequena e testável; o jogo continua funcionando sem música até a 4)
| # | Quem | O quê | Pronto quando |
|---|---|---|---|
| 0 | Richard | Conferir que a cheia foi gerada em plano pago da Suno (uso comercial) | Confirmado |
| 1 | Código + Richard | Achar na cheia um trecho que emende (corte no ataque, cauda dobrada); gerar o loop de teste e ouvir 3 voltas. **Feito: 24 compassos; falta o ouvido** | Richard aprova que não "pula" |
| 2 | Código | Cortar os stems com o mesmo intervalo de amostras; metrônomo no loop novo; guitarra e bateria leves; OGG q4 (mono onde der); grade de batidas. **Feito** | Medição: mesma duração em todos, sem clique |
| 3 | Código + Richard | Mixagem de teste offline dos níveis e das passagens (arquivo único para ouvir). **Gerado (níveis 1–3; o 4 depende da fonte do chefe); falta o ouvido** | Richard aprova níveis e passagens |
| 4 | Código | `Musica.gd` (autoload): `AudioStreamSynchronized`, níveis por página, fades no compasso, pausa, vitória/derrota; atrás de constante liga/desliga | Partida de teste no PC sem erro; prints/log de nível por página |
| 5 | Richard | Build de teste no celular (10 min, pausa, segundo plano) | Sem dessincronia, sem travar |
| 6 | Código | Registrar em `sons.md` (fonte, licença, tratamento) e tamanho no AAB | Build conferido |
| Depois | — | Música do chefe separada (`AudioStreamInteractive`), gatilhos por vida/monstros, opção "Música" nas configurações, Cover da Suno se a leve tratada ficar pobre | Decidir com o jogo rodando |

## Registro de decisões
| Decisão | Alternativas | Por quê |
|---|---|---|
| Uma geração só (cheia) | limpa; misturar as duas | Cheia tem mais material para emendas; misturar dá choque harmônico (medido) |
| Leve = stem tratado, arquivo próprio (**aprovado pelo Richard em 04/11**) | Cover Suno; compor; filtro em tempo real | Mesma harmonia e duração por construção; filtro em tempo real pegaria todas as camadas do mesmo player |
| `AudioStreamSynchronized` | vários players; `AudioStreamInteractive` | Sincronia por construção; Interactive troca clipes inteiros |
| Gatilho por página no v1 | vida, monstros, combo | Sem oscilação, fácil de testar; o resto depois |
| Jingle depois da música sair | ducking por cima | Tom dos jingles não conferido |
