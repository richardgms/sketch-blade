# Prompt para o próximo chat

Copie o bloco abaixo num chat novo do Claude Code, nesta pasta. Atualize este arquivo no fim de cada chat (ele substitui o antigo `prompt-roleta.md`).

```
Continuação do Sketch Blade (Godot 4.7, pasta atual). Leia primeiro:
- CLAUDE.md
- docs/identidade-visual.md (a pegada visual aprovada: base para tudo, inclusive a seção "Cartas")
- docs/proximas-melhorias.md (topo: "Próximo" e as entradas de 29–30/10: roleta, descanso, pausa, Estojo)
- docs/plano-publicacao.md (fim: builds 1.7.0 e 1.7.1)

Onde estamos (31/10): todo o visual de DENTRO da partida está no estilo "caderno à caneta":
hub (3 telas), vitória, derrota, reviver, HUD, chefe legível, sons, roleta (TelaRoleta.gd),
descanso (TelaDescanso.gd) e pausa (TelaPausa.gd). Fora da partida, o Estojo (TelaEstojo.gd) e a
Loja (TelaLoja.gd, abas Canetas | Pacotes, + JanelaCompra.gd) as Missões (JanelaMissoes.gd,
folha arrancada sobre o Hub) e a Recompensa diária (JanelaRecompensa.gd, mesma folha) também: fichas de etiqueta,
tracinhos e botões riscados por estado (azul / falta / máximo ou EM USO). As telas novas usam a
base TelaFim.gd (papel da fase, _botao_cheio riscado, _botao_contorno, _txt, _traco) e o card
desenhado assets/ui/card_roleta.png (caneta + papel, nine-patch 40/40/55/55); botões:
assets/ui/botao_riscado.png, botao_falta.png, botao_maximo.png, botao_equipar.png; ícones brancos em cima do azul:
gota_branca.png e clipe_branco.png (tools/gerar_gota_branca.gd).
A 1.7.0 (código 10) está no Teste fechado; a 1.7.1 (código 11, descanso + pausa) foi gerada e
pode já ter sido enviada: me pergunte antes de gerar outra. Estojo, Loja, Missões e Recompensa diária novos ainda sem build.

Próximo: a definir comigo. Tela antiga que sobra fora da partida: configurações
(painel do Hub.gd). Compras e anúncios: só o visual; push que envolva
pagamento ou anúncio: me pergunte antes.

Como trabalhamos (o mesmo processo da roleta, do descanso e da pausa):
1. Print real da tela atual (tools/capturar_telas.sh <pasta> loja,compra; faz backup e restaura o
   save do PC). Prints e originais em Documentos\Sketch Blade - design\<tela>\.
2. Me traga 2 versões (e mais 2 de ângulos diferentes se eu pedir) como protótipo num script
   novo (ex.: TelaEstojo.gd) + tools/prototipo_<tela>.gd, prints 1080x1920.
3. Publique antes/depois na página "Melhorias visuais"
   (https://claude.ai/artifact/VdK88T7PA2HgKCCBubEKrg) numa seção nova no topo, lendo a página
   antes; imagens em arquivos separados (img/...), nunca base64. Se ela não abrir (no perfil do
   Orca a lista de artifacts vem vazia), crie uma página nova da tela, fundo escuro de caderno à
   noite, como a do Estojo (https://claude.ai/artifact/8RoURc1XDar9rXL972U5ed), e me avise. Atualize a página a cada
   rodada de ajuste (versão nova em cima, as antigas embaixo, na mesma seção).
4. Espere minha escolha/ajustes; depois ligue no jogo, teste com caso de fluxo no
   capturar_telas.gd + robô (tools/bateria_chefes.gd), commit por item, docs e push.
5. Página de acompanhamento geral: https://claude.ai/artifact/XvFoxxh9Kpb1AynTtDaumW

Regras:
- nada novo no save; não mudar economia, preços nem upgrades (só o visual);
- textos nunca abaixo de ~40; um azul só (#0047ab), #002867 em contornos e títulos;
- ação destrutiva sempre com confirmação; botões/cartas só aceitam toque depois da animação;
- não gerar build sem eu pedir;
- se eu disser que mandei uma imagem e ela não aparecer, procure em %TEMP%\orca-paste-*.png.
```

## Lições técnicas dos chats de 29–30/10
- **Conferir centralização:** medir nos prints a faixa vertical de pixels de tinta (escuros ou azul forte) por coluna (desenho, texto, botão) e comparar com o centro da moldura; ignorar a hachura de sombra da base do card. Ícones com sobra transparente diferente (pote x clipe): recortar pela parte com alfa > 0,5 (`JanelaCompra._area_visivel`); `get_used_rect` conta a sombra quase transparente.
- **Fundo riscado (StyleBoxTexture) em botão com texto:** sem `set_content_margin` a margem da textura (48) vira margem do texto e o botão alarga além do `size` (aconteceu no EQUIPAR); `TelaEstojo._estilo_riscado` já põe 6.
- **Botão do ChatGPT com borda fina:** recorte por flood fill nos cantos, abertura (MinFilter 5 + MaxFilter 5) para tirar os pontinhos da hachura e MaxFilter para engrossar o contorno antes de reduzir para 720 (script em `Documentos\Sketch Blade - design\loja-nova\gerados\`).
- **Control direto num CanvasLayer (HUD do Hub) dentro do SubViewport dos prints:** as âncoras não resolvem e o tamanho fica 0; um ColorRect "tela inteira" precisa de `size = get_viewport_rect().size` (foi o fundo escuro da `JanelaCompra`).
- **Botão desabilitado:** sem estilo "disabled" o Godot desenha um cinza chapado; `TelaFim._botao_cheio` agora usa o mesmo riscado e quem chama esmaece com `modulate`.
- **Teste de toque na Loja:** a ficha em uso não tem botão, então `_btns` muda de ordem depois de cada compra; ache o botão pela caneta (`_btn_caneta(loja, id)` no `capturar_telas.gd`).
- **Ícone em cima do azul:** não pintar a silhueta de branco (vira mancha). Gerar a versão branca com contorno grosso e miolo vazado por distância até a borda (`tools/gerar_gota_branca.gd`); dilatar o desenho todo junta os rabiscos de dentro.
- **Fundo de botão por estado (ChatGPT):** passar `botao_riscado.png` como referência e pedir a mesma forma em outra tinta ou com hachura clarinha; recortar o branco de fora com flood fill a partir dos cantos e reduzir para 720 de largura (margens 48/36 iguais ao azul).
- **Edição por Python no Bash:** a barra invertida dentro de heredoc vira outra coisa; para trocar texto com `\n` ou caminhos do Windows, escreva o script num arquivo (scratchpad) e rode.
- **Teste de toque real:** `_tocar(controle)` no `capturar_telas.gd` empurra clique de mouse no SubViewport; pega botão coberto por outro controle (`mouse_filter`), o que `pressed.emit()` não pega.
- **Label com quebra de linha (Godot):** ligue `autowrap_mode` e só depois defina `size`. Se o rótulo nasce sem quebra, ele cresce até a largura do texto e não encolhe de volta (os nomes longos saíam da carta na pausa).
- **Espaço igual entre textos de fontes diferentes:** posicione pela faixa de tinta (topo das letras até a linha de base), não pela caixa do rótulo. Medidas (rótulo de uma linha): Architects Daughter 52 = tinta 16→52; 42 = 13→42 (linha seguinte +53 com `line_spacing -6`); Caveat Bold 54 = 13→52; Caveat 50 "Nv." = 18→48. Código em `TelaRoleta._preencher_textos`.
- **Script novo carregado por `set_script(preload(...))`:** o `.uid` só aparece depois de `--headless --path . --import`; rode antes do commit.
- **Imagem nova em `assets/`:** também precisa do `--import` antes dos prints.
- **Export do AAB:** o arquivo sai, mas o Godot não fecha; rode com `timeout 540` e confira o AAB com `zipfile` (íntegro, `META-INF/UPLOAD.RSA`, versão no manifest, telas novas dentro, sem `.jpg`).
- **Testes de fluxo:** a contagem 3-2-1 da pausa leva ~4 s; na pausa, `_btns` = [som, vibração, CONTINUAR, Abandonar].
- **Edições por script Python:** cuidado com `\n` dentro de heredoc (virou quebra de linha literal dentro de uma string GDScript) e com substituições que não acham o texto: confira com `assert`.
- **Card gerado no ChatGPT:** gerar 2–3 opções passando o botão riscado e um print do jogo como referência; recortar o fundo branco de fora (flood fill), reduzir para a altura de uso e esticar como nine-patch. Juntar duas imagens (contorno de uma + textura de outra) por multiplicação funcionou melhor que pedir de novo.
