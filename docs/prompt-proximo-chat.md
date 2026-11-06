# Prompt para o próximo chat

Resumo atualizado em 05/11/2026. Detalhes nas fontes indicadas; não reler todo o histórico.

```text
Continuação do Sketch Blade, Godot 4.7, nesta pasta. Leia:
- CLAUDE.md (comandos e regras).
- docs/plano-publicacao.md (build, status e notas da versão).
- docs/plano-atualizacao-play.md (consulta automática de atualização).
- docs/sons.md e docs/plano-musica-adaptativa.md (mixagem e vida crítica).
- Para visual: docs/identidade-visual.md; próximos assuntos em docs/proximas-melhorias.md.

Estado atual:
- AAB 1.8.4, código 19, gerado, assinado e validado:
  Documentos/Sketch Blade - builds/sketchblade-1.8.4-vc19.aab (68.783.166 bytes).
  SHA256, conteúdo e notas prontas em plano-publicacao.md.
- Richard NÃO enviou a 1.8.3 (18); está fazendo upload direto da 1.8.4.
  Ainda NÃO confirmou publicação/disponibilidade da 1.8.4. Não assumir que publicou.
- A 1.8.4 inclui a integração automática da Play criada na 1.8.3, efeitos de vida
  crítica, correção dos jingles, som de moedinha nas missões e retratos finais.
- Play Update: mesma notinha de caderno, disponibilidade confirmada pela Play
  para a conta instalada. JSON fornece somente notas da mesma versão; se faltar
  ou estiver antigo, abre aviso genérico. Não depende de publicar JSON nas novas.
  Falta teste real: instalar a 1.8.4 via Play e depois liberar versão superior
  à mesma conta para testar o aviso. 16 testes de lógica passaram.
- Versões anteriores à integração ainda usam JSON para detectar atualização.
  Último JSON publicado por nós: 1.8.2 (17), commit remoto 4413b27. Atualizar
  para 1.8.4 (19) somente após Richard confirmar disponibilidade na Play; assim
  quem está na 1.8.2 também recebe o aviso e instala a integração nova.
- Trilha clara por ganhos dos stems originais; guitarra filtrada saiu dos níveis
  normais. Mortes −7 dB com EQ/compressor e limite de sobreposição.
- Vida crítica aprovada (opção 1): entra com 1 coração, heartbeat duplo mais
  marcado, zumbido curto 1,2 s e vinheta sincronizada. Música −4 dB e filtro
  5 kHz em barramento pai exclusivo; entrada 0,3 s, saída 0,9 s, relógio real.
  Pausa suspende; cura/fim limpam; retomada não repete impacto. 24 testes passaram.
- Vitória/derrota não tocavam porque os players herdavam a pausa. Corrigido com
  PROCESS_MODE_ALWAYS apenas nos dois jingles. 16 verificações nos finais reais
  passaram. Moedinha compra.ogg soma ao check.ogg ao resgatar missão diária.
- Miniaturas da trilha do Hub: rosto ampliado e recorte circular. Richard ajustou
  os dez visualmente e os valores já foram transferidos para Hub.ROSTOS_TRILHA.
  Cena salva: tools/ajuste_retratos/ajuste_retratos.tscn; instruções no LEIA-ME
  dessa pasta. É auxiliar, excluída do export; jogo não a lê diretamente.
  Ajustes finais conferidos lado a lado em OpenGL; evidência na pasta de design.
- Testes no PC passaram; saves restaurados por hash. Headless ainda reporta
  recursos residuais ao encerrar. Não confundir com validação de áudio no celular.
- MODO_TESTE e anúncios de teste mantidos para a faixa fechada.

Próximo:
- Aguardar confirmação de publicação da 1.8.4 antes de anunciar JSON para versões
  antigas. Notas combinadas de 1.8.3/1.8.4 estão em plano-publicacao.md.
- Receber teste auditivo da 1.8.4 no celular: vida crítica, cura/pausa, chefes,
  jingles de vitória/derrota e resgate de missões. Não presumir aprovação de ouvido.
- Não gerar novo build sem pedido. Subir juntos preset version/code e
  GameData.VERSAO_CODIGO quando houver novo envio.

Git e cuidados:
- Mudanças desta conversa salvas em commits locais. Último build: ca4fc02.
  Outros commits de código continuam sem push; não enviar a branch inteira por
  rotina. Só os avisos JSON foram publicados em pushes isolados.
- Hub contém compras/anúncios: manter confirmação para publicar esse código.
- Chrome: upload automático NÃO ocorreu. A ferramenta interrompeu o controle
  porque não conseguiu confirmar a URL da janela; Richard assumiu o upload.
- Pendências preexistentes preservadas: .serena/project.yml, docs/guia-busca-sons.md,
  imports de store/ e tools/__pycache__/. Não apagar/incluir por rotina.
- Builds e originais ficam fora do repo, em Documentos/Sketch Blade - builds,
  Sketch Blade - design e Sketch Blade - audio. Caminhos exatos nas fontes.
- Aplicar as instruções globais da sessão. Nada de economia/save/compras/anúncios
  fora do escopo. Delegação só pelo Orca quando autorizada; sem subagentes nativos.
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
