# Prompt para o próximo chat: roleta de upgrades no estilo caderno

Copie o bloco abaixo num chat novo do Claude Code, nesta pasta.

```
Continuação do Sketch Blade (Godot 4.7, pasta atual). Leia primeiro:
- CLAUDE.md
- docs/identidade-visual.md (a pegada visual aprovada: base para tudo)
- docs/proximas-melhorias.md (seções do topo: conselho de 29/10 à noite, sons, chefe legível, HUD, reviver)

Contexto: em 29/10 redesenhamos e aprovamos no estilo "caderno à caneta" o hub (3 telas), a vitória, a derrota ("Página arruinada"), o reviver ("Segunda chance?"), o HUD do combate (coração novo, barra de vida riscada vermelha), o chefe legível e 10 sons gravados. As telas de fim usam a base TelaFim.gd (papel da fase, _botao_cheio com assets/ui/botao_riscado.png, _botao_contorno, _txt, _traco, _marca_texto, _barra_xp, botões travados até a animação). Tudo no GitHub; a 1.6.0 (código 9) está no Teste fechado e ainda NÃO tem nada disso (sem build novo desde então).

Agora quero redesenhar a ROLETA DE UPGRADES (aparece nas páginas 2, 4 e 6 de cada partida: 3 cartas para escolher 1 melhoria) no mesmo estilo. Código atual em Main.gd: _criar_menu_upgrades, _abrir_roleta_upgrades, _aplicar_upgrade, TAM_CARTA_ROLETA, _topo_bloco_roleta. Upgrades e textos em GameData.gd (ids tiro_duplo, leque, ricochete, etc.), ícones em assets/.

O que eu quero:
1. Tire um print real da roleta atual (bash tools/capturar_telas.sh <pasta> roleta; faz backup e restaura o save do PC).
2. Me traga uma sugestão (2 ou 3 versões se valer a pena), seguindo docs/identidade-visual.md: cartas com miolo branco e contorno de caneta sobre o papel da fase, uma ação clara, textos legíveis no celular (nunca abaixo de ~40), nível do upgrade visível ("Nv. 2 → 3" quando já tem), sem colchetes. Se faltar ícone ou fundo riscado, gere no ChatGPT (skill gerar-imagem) passando referências do jogo.
3. Monte por cima da tela real (ou direto num script novo, como TelaReviver.gd), tire prints 1080x1920 e publique antes/depois na página "Melhorias visuais" (https://claude.ai/artifact/VdK88T7PA2HgKCCBubEKrg), lendo a página antes (imagens em arquivos separados, não em base64). Página de sons: https://claude.ai/artifact/YUAvgQ6UbbRQ3YMqvN3db4
4. Espere meu OK ou ajustes; só depois finalize e faça push.

Regras:
- nada novo no save; não mudar a economia nem os upgrades (só o visual);
- a escolha não pode acontecer sem querer: cartas só aceitam toque depois da animação de entrada (~0,5 s), como nas telas de fim;
- teste com o robô (tools/bateria_chefes.gd usa a roleta) e com prints; toda captura com backup e restauração do save do PC;
- não gerar build/AAB ainda; um commit por item; atualizar docs e a página no fim;
- se eu disser que mandei uma imagem e ela não aparecer, procure em %TEMP%\orca-paste-*.png.
```

## Lições do chat de 29/10 (valem para o próximo)
- Prints: o `capturar_telas.gd` preenche "Página 8 / 8" no combate e zera `AdsManager.revive_usado_na_run` antes de cada caso de reviver; flags globais (autoloads) passam de uma partida de teste para a outra.
- Se o Godot de teste travar, encerre só o processo do teste pelo PID (veja a linha de comando com `Get-CimInstance Win32_Process`): o editor aberto pelo Richard também se chama Godot.
- Imagens geradas: original grande em `Documentos\Sketch Blade - design\<tela>\gerados\`, versão recortada/no tamanho de uso em `assets/ui/`.
