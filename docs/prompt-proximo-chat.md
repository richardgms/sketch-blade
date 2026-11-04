# Prompt para o próximo chat

Resumo atualizado em 04/11/2026. Pode ser usado no Codex ou Claude Code; os detalhes ficam nas fontes indicadas.

```text
Continuação do Sketch Blade, Godot 4.7, nesta pasta. Leia:
- CLAUDE.md (comandos e regras do projeto).
- docs/plano-publicacao.md (build atual e aviso de atualização).
- docs/plano-musica-adaptativa.md (trilha e teste pendente no celular).
- docs/sons.md (efeitos aprovados e suas origens).
- Para mexer em telas: docs/identidade-visual.md; próximos assuntos em docs/proximas-melhorias.md.

Estado atual:
- AAB 1.8.1, código 16, gerado, assinado e conferido. Está disponível no teste fechado da Play.
  Arquivo: Documentos/Sketch Blade - builds/sketchblade-1.8.1-vc16.aab.
  Relatório de validação ao lado do AAB; detalhes em plano-publicacao.md.
- Música adaptativa e música própria dos chefes/raiva. Metrônomo removido da partida,
  dos chefes, dos assets e dos geradores/demonstrações: 6 camadas na partida e 5 no chefe.
- Sons aprovados: seis variações de morte (7 e 8 removidas), krw ao inchar antes do tiro,
  derrota inteira e marimba na contagem. Fontes/licenças em sons.md.
- Testes no PC passaram: 17 de música, 7 de sons, hub e 7 do aviso de atualização.
  Saves dos testes restaurados e conferidos; isso não equivale a aprovação do áudio no celular.
- O JSON público atualizacao/versao.json já anuncia 1.8.1 (16).
  Richard confirmou no celular que o aviso funcionou após essa correção.
  O jogo consulta ao iniciar: fechar completamente e abrir com internet força nova consulta.
- MODO_TESTE = true e anúncios de teste mantidos para a faixa fechada.

Próximo:
- Receber o relato do áudio da 1.8.1 no celular: música por 10 min, chefe/raiva, pausa,
  retomada e segundo plano. Não marcar esse teste como concluído pelo “funcionou” do aviso.
- Notas de versão para jogadores devem descrever a melhoria geral, evitando detalhes como
  “marimba” ou “derrota inteira”; texto aprovado de cada versão em plano-publicacao.md.
- Não gerar novo build sem pedido. Em nova publicação, subir juntos o código no preset
  e GameData.VERSAO_CODIGO; atualizar/publicar o JSON do aviso somente após a Play liberar.

Git e cuidados:
- Só os JSON de aviso das versões 15 e 16 foram publicados em pushes isolados.
  Os demais commits de áudio/build/documentação continuam locais; verificar antes de push.
  Há mudança de som no Hub.gd que trata compras: manter a confirmação para publicar esse código.
- Pendências preexistentes preservadas: .serena/project.yml, docs/guia-busca-sons.md,
  imports de store/ e tools/__pycache__/. Conferir git status e não apagar/incluir por rotina.
- Builds, originais e referências grandes ficam fora do repo, nos caminhos documentados.
- Aplicar as instruções globais da sessão. Nada de economia/save/compras/anúncios fora do escopo.
```

## Lições técnicas dos chats de 29–30/10
- **Música em camadas (04/11):** loop só fecha onde a música repete um trecho (achar por semelhança batida a batida, `tools/musica/achar_emenda.py`); metrônomo do Moises escorrega ou atrasa (medir os ataques da própria bateria); duas gerações da Suno não são a mesma composição (Sol# contra Sol); `play(posição)` funciona com `AudioStreamSynchronized`; player pausado responde `playing = false`.
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
- **Imagem do jogo nunca em `.jpg`:** o `exclude_filter` do export tira `*.jpg` (para não levar fotos); um `preload` de JPG funciona no PC e quebra no celular. Use PNG; textura com grão fino (papel) importa sem perda (`compress/mode=0`), o WebP com perda apaga a fibra.
- **Testes de fluxo:** a contagem 3-2-1 da pausa leva ~4 s; na pausa, `_btns` = [som, vibração, CONTINUAR, Abandonar].
- **Edições por script Python:** cuidado com `\n` dentro de heredoc (virou quebra de linha literal dentro de uma string GDScript) e com substituições que não acham o texto: confira com `assert`.
- **Card gerado no ChatGPT:** gerar 2–3 opções passando o botão riscado e um print do jogo como referência; recortar o fundo branco de fora (flood fill), reduzir para a altura de uso e esticar como nine-patch. Juntar duas imagens (contorno de uma + textura de outra) por multiplicação funcionou melhor que pedir de novo.
