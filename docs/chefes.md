# Chefes e combate — Sketch Blade

Fonte única sobre chefes, tiros inimigos e "sensação de acerto". O `plano-publicacao.md` só aponta para cá.
Atualizado em 28/10/2026 (todos os 10 chefes feitos).

## Regras de design (decididas com o conselho de LLMs e o teste do Richard)
O jogador é uma caneta que **só anda na horizontal** e **atira sozinha** para cima. Por isso:
- **Posição, não mira:** cada ataque testa onde a caneta está, nunca a pontaria.
- **Sempre há saída no eixo X:** paredes/zonas deixam brecha de pelo menos 2× a caneta.
- **Ficar parado não pode compensar** (a caneta é fina, 42 px de colisão): usar tiros mirados, gota perseguidora, lacaios e ataques na coluna da caneta.
- **Aviso:** tiro comum avisa só com o atirador **inchando** 0,5 s antes (a linha tracejada poluía a tela). Linha/círculo só para ameaças rápidas ou de área (rasante e mergulho do Avião, círculo do Compasso, zonas marcadas dos próximos chefes).
- Luta de 30 a 60 s. Upgrade da roleta pode ser **bônus** contra um chefe, nunca requisito (a roleta é sorteada).
- Variedade: o chefe sorteia ataques sem repetir o último (pedido do Richard: o Avião ficava repetitivo).
- Ao matar o chefe: tela limpa (tiros somem, reforços morrem) e a caneta fica protegida.
- **Raiva** (metade da vida): aviso "COM RAIVA!" no topo, tremor, som e o chefe pulsa em vermelho (`Boss._entrar_raiva`). Mancha e Estojo não usam (anunciam as fases deles). Tsuru e Fantasma: o Richard viu a versão B (escudo/cadeado; sombra forte e cópias transparentes) e preferiu manter como estão.
- **Vida:** `Boss.FICHAS[cap]["vida"]` multiplica a escala por capítulo; calibrada pela bateria (`docs/equilibrio-chefes.md`). Mudou ataque ou vida: rodar a bateria de novo.

## Situação dos chefes
| Cap. | Chefe | Mecânica | Situação |
|---|---|---|---|
| 1 | Borrão | patrulha, leque **mirado** (até 40°) e mergulho | Feito (comportamento padrão do `Boss.gd`) |
| 2 | Avião de papel | topo com leque (tempo variável) → sorteia **rasante** (linha de aviso, bombas com brecha de 300 px), **mergulho mirado** (linha travada na caneta) ou **esquadrilha** (3 gotas perseguidoras, 5 com raiva) | Feito, testado pelo Richard |
| 3 | Mancha de 4 lobos | leque mirado + perseguidora; com 50% vira 2 pedaços **com vida própria**, cada grande vira 2 pequenos ao perder metade; último fica bravo; barra = soma | Feito, testado |
| 5 | Compasso | anda, dá corda (círculo de aviso), espiral só para baixo; descanso com 2 perseguidoras; com raiva 3 braços, inverte a espiral e invoca 2 lacaios | Feito, testado |
| 4 | Monstro da grade | no alto, balança e atira leque mirado; sorteia **esmagar** (a coluna da caneta enche 1,2 s e explode; com raiva + 1 coluna longe), **xadrez** (3 colunas alternadas com a da caneta; com raiva as outras 3 logo depois) ou **pedras** (2 leques; com raiva + 2 perseguidoras). Chão em 6 colunas de 180 px (`chefes/ZonaGrade.gd`) | Feito, testado |
| 6 | Pirata do mapa | sem fase invulnerável; no alto, balança e atira leque mirado; sorteia **tesouro** (X na caneta, bomba em arco explode com raio 105; com raiva 3 X seguidos), **chuva** (X a cada 360 px a partir da caneta, caem em ordem aleatória; com raiva 2ª chuva nas brechas) ou **canhão** (3 balas miradas; com raiva + 2 perseguidoras). `chefes/ZonaBomba.gd` | Feito, testado |
| 9 | Pena de escrever | no alto, balança e atira leque mirado; sorteia **parede** (vai a um canto e atravessa escrevendo uma linha de tinta = aviso; fresta de 230 px a 130–220 px da caneta; a linha desce e fere fora da fresta; com raiva 2ª parede na volta, fresta do outro lado), **chuva** (pingos "tinta" caem do alto por 2 s, 1 em 3 na caneta) ou **mergulho** (linha tracejada travada, crava a ponta no papel 0,55 s e volta; com raiva 2 vezes). `chefes/ParedeTinta.gd` | Feito, testado |
| 7 | Tsuru | ritmo fixo: **aberto** 2,4 s (2,0 com raiva; coração brilha, só aqui toma dano; leque mirado; asas tremem 0,4 s antes de fechar) e **fechado** 3,0 s (tiros mostram "BLOQUEADO"; sorteia **mergulho** mirado, **dobras** = 3/5 perseguidoras ou **rajada** = 4/6 tiros mirados). Som ao abrir e fechar. Desenho recortado em 4 partes (`_montar_partes`) | Feito, testado |
| 8 | Fantasma de página | meio transparente, com **sombra** no papel; balança e atira leque mirado; sorteia **cópias** (3 fantasmas, só o verdadeiro tem sombra, todos incham e atiram igual; cópia some com 1 tiro; 6 s ou até sumirem as cópias; com raiva todos piscam e **trocam de lugar** no meio), **folhas** (páginas caem balançando, a 1ª na caneta; 4/6) ou **uivo** (3/5 perseguidoras). `CopiaFantasma.gd`, `FolhaFantasma.gd` | Feito, testado |
| 10 | Estojo | "desfile" em 3 fases pela vida (nome no topo, treme 1,2 s na troca): **1** (100–67%) esmagar, tesouro, espiral 2 braços; **2** (67–34%) parede, chuva de X, folhas; **3** (<34%) xadrez duplo, parede dupla, espiral 3 braços, 3 X + perseguidoras. Reaproveita `ZonaGrade`, `ZonaBomba`, `ParedeTinta`, `FolhaFantasma`; cada ataque é uma agenda de eventos `[tempo, função]` | Feito, testado |

Arte de todos já existe: `assets/inimigos/chefe_1..10.png` (512 px) e `chefe_3_pedaco.png` (256 px). Originais em `Documentos\Sketch Blade - arte original\inimigos` (fora do projeto).

## Arquitetura
- `Boss.gd` = chefe-base: entrada, vida, flash, DoT, morte, `atirar(pos, dir, vel, raio, estilo)`, `mira(de)`, `_avisar_leque()`/`_disparar_leque()` (o aviso decide o ângulo e o tiro usa o mesmo), `definir_raio_acerto(r)`, `dano_compartilhado(...)`.
- `Boss.FICHAS[cap]` = `{arte, fator (tamanho do desenho), raio (círculo de acerto), vida (multiplicador), comportamento}`. Capítulo sem ficha usa a do 1 (Borrão).
- `chefes/<Nome>.gd` (`extends RefCounted`, recebe o `boss` no `_init`, tem `processar(delta)`): o `Boss._process` delega tudo a ele. Se o comportamento gira o desenho, declarar `var controla_rotacao := true`.
- Defesa (Tsuru): o comportamento pode ter `bloqueia_dano(pos) -> bool`; o `Boss._aplicar_dano` pergunta antes de tirar vida (`spawn_damage_number(0, ...)` mostra "BLOQUEADO").
- Partes móveis do desenho (asas do Tsuru): recortes da mesma imagem com `region_rect`, filhos do `_arte` com `use_parent_material` (piscam juntos); a parte que gira entra uns px por baixo da vizinha e fica atrás (`show_behind_parent`), senão a emenda abre fresta branca.
- Cópias falsas (Fantasma): `Area2D` na camada 2 e grupo `enemies` com `morrer()` e `morrendo` (a limpeza da vitória as mata); 4 desenhos grandes não cabem lado a lado na tela, por isso o máximo é 3.
- Áreas de acerto extras (ex.: pernas do Compasso): `CollisionShape2D` filhos do chefe, adicionados com `call_deferred` e reposicionados a cada quadro.
- Pedaços/peças com vida própria (Mancha): nó `Area2D` próprio na camada 2, grupo `enemies`, com `receber_dano`, `receber_dano_detalhado`, `aplicar_dot`, `morre_no_contato = false`. O nó do chefe vira só "controle" (invisível, sem colisão, fora do grupo `enemies`).
- Tiros: `EnemyProjectile.setup(dir, vel, raio, estilo)`; estilos `respingo` (gota verde), `tinta` (gota azul-petróleo da Pena), `elite` (losango laranja), `chefe` (bola vermelha com espinhos), `perseguidora` (roxa com olho; curva 75°/s por 2 s). Sempre pelo pool do `Main` (`obter_projetil_inimigo`).
- Lacaios: `enemy.tscn` com `configurar_tipo(2)` (Respingo) e `estilo_tiro = "perseguidora"`.
- Avisos no alto da tela (sem cobrir a área de desvio): `Main.aviso_topo(texto, cor)`.
- Zonas no chão (Grade, Pirata) e paredes (Pena): `Node2D` no `Main`, posto logo antes da caneta na árvore (por cima do papel, por baixo da caneta); fere checando o X da caneta na hora da explosão e some sozinho se o chefe morrer.
- `AvisoTiro.gd`: linha tracejada; `atras_do_atirador = false` quando o aviso fica solto no cenário (senão vai para trás do papel).

**Como adicionar um chefe:** criar `chefes/<Nome>.gd` com `processar` (copiar a fase ENTRADA do `Aviao.gd`/`Compasso.gd`), pôr a ficha em `Boss.FICHAS` (medir o `raio` no desenho), incluir o capítulo na lista do atalho "Testar chefe" (`Hub._abrir_painel_stats`), testar por script (abaixo) e com o Richard no Godot do PC.

## Sensação de acerto (já feita, vale para todos)
Tiro do jogador em cometa de tinta; respingo no impacto (`ImpactoTinta.gd`); flash branco por shader (`flash.gdshader`, também faz o "tremido" de desenho à mão); empurrão; números de dano brancos/laranja com contorno; tremor curto no crítico; barra do chefe vermelha com contorno.

## Como testar
- **No jogo (modo de teste):** Configurações → Stats de teste → "Chefe: [1]…[10]" (2 linhas de 5 botões; a caixa tem altura fixa de 1280 px). Abaixo, vitórias/derrotas por capítulo (`SaveManager.registrar_capitulo`; "chefe" = derrotas na página do chefe; partidas do atalho não contam; o [ ZERAR ] limpa) abre a partida direto no chefe; "Zerar Estojo" volta Dano/Corações/Cadência ao nível 1. Só aparecem com `GameData.MODO_TESTE = true` (desligar antes da produção).
- **Por script (Claude):** copiar `tools/capturar_telas.gd` para um `tools/_tmp_*.gd`, trocar o bloco `if _quer("hud")` por um roteiro (abrir `main.tscn`, `wave_manager.iniciar_fase_na_pagina(cap, GameData.PAGINAS.size())`, achar o chefe, `player.dano = 1` para ele não morrer, `angulos_leque = []` para isolar o dano de zona, forçar ataques com `_comportamento._iniciar_ataque(nome)`, `_foto(...)`), rodar `Godot --path . -s tools/_tmp_x.gd -- <pasta> hud` e apagar o arquivo. Para lógica sem imagem, `--headless` com um `SceneTree` em `SubViewport`. Sempre copiar o save do PC antes e restaurar depois.
- Cuidados nos testes: o tiro automático da caneta pode matar cópias/peças antes do roteiro (`attack_timer.stop()`); o chefe só toma dano depois da entrada (`entrada_concluida`); a invencibilidade forçada na caneta é desligada pelo tween de dano do `Player` após o primeiro golpe (não é bug do jogo).

## Pendências e ideias
- Os 10 chefes estão feitos, testados e calibrados (`docs/equilibrio-chefes.md`). Próximo: build e teste no celular.
- Opção 3 (área de dano maior da caneta): prévia em `Documentos\Sketch Blade - arte original\previa-area-de-dano-caneta.png`; decidir depois de testar a opção 1.
- Olhos dos monstros animados por código (pupila seguindo a caneta, piscar): ideia aprovada pelo conselho, não feita.
- Se o "inchar" for fraco como aviso: piscar em vermelho enquanto incha.
- Ajustes finos de dificuldade só no celular (velocidade das bombas, curva da perseguidora, brecha).

## Erros já resolvidos (não repetir)
- Criar `Area2D`/`CollisionShape2D` dentro de um callback de colisão gera "Can't change this state while flushing queries": usar `call_deferred`.
- Apagar (`queue_free`) tiros que estão no pool deixa "previously freed instance": devolver ao pool (`devolver_projetil_inimigo`).
- Tiros ignoravam a invencibilidade da caneta: agora `Player.receber_dano` checa `invencivel` e `protegido_fim_de_fase`.
- Círculo de acerto único não cobre chefe largo ou que gira: `raio` por ficha + áreas extras.
- Pedaços com relógios próprios se sobrepõem: usar um relógio só (o do comportamento).
- Escrever texto com `\n` via script Python pode gerar quebra de linha real dentro de string do GDScript: conferir a linha depois.

## Fluxo da partida (capítulo)
Confirmado no código em 29/10/2026 (`Main.gd`, `Hub.gd`).
- **Partida = capítulo inteiro**: páginas 1 → 8 (8 = chefe). Vence só quem passa todas as páginas e mata o chefe na mesma partida.
- **Morreu**: 1 vez por partida dá para **reviver com anúncio** (volta com 3 corações). Na 2ª morte, ou recusando, é derrota: a partida acaba e a próxima começa da **página 1**, sem os upgrades da roleta.
- **O que fica na derrota**: tinta coletada (+ bônus do capítulo, sem bônus de vidas; dá para dobrar com anúncio), XP e níveis do Estojo. Perde: upgrades da roleta e a página alcançada.
- **Vitória**: tinta + bônus de vidas (10% por coração) + bônus do capítulo; XP; desbloqueia o próximo capítulo (só na 1ª vez).
- **Sair pelo menu de pausa**: abandona a partida (sem tinta, sem retomar).
- **App fechado ou em segundo plano** (home, ligação, Android mata o app): a partida fica salva no início de cada página (`run_snapshot`). Ao abrir o hub aparece "Partida em andamento": volta no **começo da mesma página**, com capítulo, corações, tinta, upgrades da roleta e o revive usado ou não. só "Abandonar partida" apaga a partida salva; tocar em **LUTAR** com partida salva reabre esse aviso (desde 29/10).
