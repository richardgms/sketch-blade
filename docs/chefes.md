# Chefes e combate — Sketch Blade

Fonte única sobre chefes, tiros inimigos e "sensação de acerto". O `plano-publicacao.md` só aponta para cá.
Atualizado em 28/10/2026 (chefes 4 e 6).

## Regras de design (decididas com o conselho de LLMs e o teste do Richard)
O jogador é uma caneta que **só anda na horizontal** e **atira sozinha** para cima. Por isso:
- **Posição, não mira:** cada ataque testa onde a caneta está, nunca a pontaria.
- **Sempre há saída no eixo X:** paredes/zonas deixam brecha de pelo menos 2× a caneta.
- **Ficar parado não pode compensar** (a caneta é fina, 42 px de colisão): usar tiros mirados, gota perseguidora, lacaios e ataques na coluna da caneta.
- **Aviso:** tiro comum avisa só com o atirador **inchando** 0,5 s antes (a linha tracejada poluía a tela). Linha/círculo só para ameaças rápidas ou de área (rasante e mergulho do Avião, círculo do Compasso, zonas marcadas dos próximos chefes).
- Luta de 30 a 60 s. Upgrade da roleta pode ser **bônus** contra um chefe, nunca requisito (a roleta é sorteada).
- Variedade: o chefe sorteia ataques sem repetir o último (pedido do Richard: o Avião ficava repetitivo).
- Ao matar o chefe: tela limpa (tiros somem, reforços morrem) e a caneta fica protegida.

## Situação dos chefes
| Cap. | Chefe | Mecânica | Situação |
|---|---|---|---|
| 1 | Borrão | patrulha, leque **mirado** (até 40°) e mergulho | Feito (comportamento padrão do `Boss.gd`) |
| 2 | Avião de papel | topo com leque (tempo variável) → sorteia **rasante** (linha de aviso, bombas com brecha de 300 px), **mergulho mirado** (linha travada na caneta) ou **esquadrilha** (3 gotas perseguidoras, 5 com raiva) | Feito, testado pelo Richard |
| 3 | Mancha de 4 lobos | leque mirado + perseguidora; com 50% vira 2 pedaços **com vida própria**, cada grande vira 2 pequenos ao perder metade; último fica bravo; barra = soma | Feito, testado |
| 5 | Compasso | anda, dá corda (círculo de aviso), espiral só para baixo; descanso com 2 perseguidoras; com raiva 3 braços, inverte a espiral e invoca 2 lacaios | Feito, testado |
| 4 | Monstro da grade | no alto, balança e atira leque mirado; sorteia **esmagar** (a coluna da caneta enche 1,2 s e explode; com raiva + 1 coluna longe), **xadrez** (3 colunas alternadas com a da caneta; com raiva as outras 3 logo depois) ou **pedras** (2 leques; com raiva + 2 perseguidoras). Chão em 6 colunas de 180 px (`chefes/ZonaGrade.gd`) | Feito, testado |
| 6 | Pirata do mapa | sem fase invulnerável; no alto, balança e atira leque mirado; sorteia **tesouro** (X na caneta, bomba em arco explode com raio 105; com raiva 3 X seguidos), **chuva** (X a cada 360 px a partir da caneta, caem em ordem aleatória; com raiva 2ª chuva nas brechas) ou **canhão** (3 balas miradas; com raiva + 2 perseguidoras). `chefes/ZonaBomba.gd` | Feito, **falta o teste do Richard** |
| 9 | Pena de escrever | paredes de tinta que descem com fresta (fresta nasce perto da caneta, não do outro lado) | **A fazer (1.5)** |
| 7 | Tsuru | asas abrem/fecham em ritmo fixo e visível, com som; só toma dano aberto | A fazer (1.6) |
| 8 | Fantasma de página | cópias translúcidas que somem com 1 tiro; só a verdadeira tem sombra | A fazer (1.6) |
| 10 | Estojo | fases por vida usando ataques dos outros chefes ("desfile") | A fazer (1.6, depois dos outros) |

Arte de todos já existe: `assets/inimigos/chefe_1..10.png` (512 px) e `chefe_3_pedaco.png` (256 px). Originais em `Documentos\Sketch Blade - arte original\inimigos` (fora do projeto).

## Arquitetura
- `Boss.gd` = chefe-base: entrada, vida, flash, DoT, morte, `atirar(pos, dir, vel, raio, estilo)`, `mira(de)`, `_avisar_leque()`/`_disparar_leque()` (o aviso decide o ângulo e o tiro usa o mesmo), `definir_raio_acerto(r)`, `dano_compartilhado(...)`.
- `Boss.FICHAS[cap]` = `{arte, fator (tamanho do desenho), raio (círculo de acerto), comportamento}`. Capítulo sem ficha usa a do 1 (Borrão).
- `chefes/<Nome>.gd` (`extends RefCounted`, recebe o `boss` no `_init`, tem `processar(delta)`): o `Boss._process` delega tudo a ele. Se o comportamento gira o desenho, declarar `var controla_rotacao := true`.
- Áreas de acerto extras (ex.: pernas do Compasso): `CollisionShape2D` filhos do chefe, adicionados com `call_deferred` e reposicionados a cada quadro.
- Pedaços/peças com vida própria (Mancha): nó `Area2D` próprio na camada 2, grupo `enemies`, com `receber_dano`, `receber_dano_detalhado`, `aplicar_dot`, `morre_no_contato = false`. O nó do chefe vira só "controle" (invisível, sem colisão, fora do grupo `enemies`).
- Tiros: `EnemyProjectile.setup(dir, vel, raio, estilo)`; estilos `respingo` (gota verde), `elite` (losango laranja), `chefe` (bola vermelha com espinhos), `perseguidora` (roxa com olho; curva 75°/s por 2 s). Sempre pelo pool do `Main` (`obter_projetil_inimigo`).
- Lacaios: `enemy.tscn` com `configurar_tipo(2)` (Respingo) e `estilo_tiro = "perseguidora"`.
- Avisos no alto da tela (sem cobrir a área de desvio): `Main.aviso_topo(texto, cor)`.
- Zonas no chão (Grade, Pirata): `Node2D` no `Main`, posto logo antes da caneta na árvore (por cima do papel, por baixo da caneta); fere checando o X da caneta na hora da explosão e some sozinho se o chefe morrer.
- `AvisoTiro.gd`: linha tracejada; `atras_do_atirador = false` quando o aviso fica solto no cenário (senão vai para trás do papel).

**Como adicionar um chefe:** criar `chefes/<Nome>.gd` com `processar` (copiar a fase ENTRADA do `Aviao.gd`/`Compasso.gd`), pôr a ficha em `Boss.FICHAS` (medir o `raio` no desenho), incluir o capítulo na lista do atalho "Testar chefe" (`Hub._abrir_painel_stats`), testar por script (abaixo) e com o Richard no Godot do PC.

## Sensação de acerto (já feita, vale para todos)
Tiro do jogador em cometa de tinta; respingo no impacto (`ImpactoTinta.gd`); flash branco por shader (`flash.gdshader`, também faz o "tremido" de desenho à mão); empurrão; números de dano brancos/laranja com contorno; tremor curto no crítico; barra do chefe vermelha com contorno.

## Como testar
- **No jogo (modo de teste):** Configurações → Stats de teste → "Testar chefe [1]…[6]" abre a partida direto no chefe; "Zerar Estojo" volta Dano/Corações/Cadência ao nível 1. Só aparecem com `GameData.MODO_TESTE = true` (desligar antes da produção).
- **Por script (Claude):** copiar `tools/capturar_telas.gd` para um `tools/_tmp_*.gd`, trocar o bloco `if _quer("hud")` por um roteiro (abrir `main.tscn`, `wave_manager.iniciar_fase_na_pagina(cap, GameData.PAGINAS.size())`, achar o chefe, `player.dano = 1` para ele não morrer, `angulos_leque = []` para isolar o dano de zona, forçar ataques com `_comportamento._iniciar_ataque(nome)`, `_foto(...)`), rodar `Godot --path . -s tools/_tmp_x.gd -- <pasta> hud` e apagar o arquivo. Para lógica sem imagem, `--headless` com um `SceneTree` em `SubViewport`. Sempre copiar o save do PC antes e restaurar depois.
- Cuidados nos testes: o chefe só toma dano depois da entrada (`entrada_concluida`); a invencibilidade forçada na caneta é desligada pelo tween de dano do `Player` após o primeiro golpe (não é bug do jogo).

## Pendências e ideias
- Chefe 9 (versão 1.5; o 6 aguarda teste) e depois 7, 8, 10 (1.6).
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
