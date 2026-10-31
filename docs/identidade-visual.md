# Identidade visual — o que funciona no Sketch Blade

Guia geral (não é regra fixa: cada tela é um caso). Tirado do que o Richard aprovou e pediu para mudar no hub novo, na partida em andamento e na vitória (29/10/2026). Exemplos aprovados: página "Melhorias visuais" (https://claude.ai/artifact/VdK88T7PA2HgKCCBubEKrg) e prints em `Documentos\Sketch Blade - design\`.

## A pegada
**Um caderno escolar de verdade, desenhado à caneta.** Tudo parece feito à mão em cima do papel da fase: nada de interface "de aplicativo" (cartões chapados, sombras, gradientes, fundos transparentes mostrando o jogo atrás).

## Papel e fundo
- O fundo é sempre o **papel da fase** (`Paper.gd`: pautado ou quadriculado conforme o capítulo), inclusive em popups e telas de fim. Ele foi pedido explicitamente no cartão "Partida em andamento".
- Telas de fim cobrem o combate por inteiro: nada de HUD apagado ou caneta fantasma ao fundo.
- Botões e cartões que ficam por cima do papel têm **miolo branco**, para o quadriculado não aparecer por dentro.

## Cores (tinta de caneta)
- **Um azul só: `#0047ab`**, em bolinhas, botões, números, textos de ação, barra de XP, gota de tinta e LUTAR da barra. Tons de azul diferentes incomodam: ele mandou unificar todos.
- `#002867` (azul mais carregado) só em contornos e títulos.
- Verde `#2e7d32`: "concluído", "MODO NORMAL". O verde de destaque (página atual) precisa ser **claro** (`#6fd877`), senão confunde com o azul de longe.
- Vermelho `#c62828`: selo/carimbo, ações destrutivas (ABANDONAR) e **vida** (coração e barra de vida do combate: preenchimento riscado `assets/ui/barra_vida_riscada.png`, gerado no ChatGPT a partir do botão azul; original 720x160 em `Documentos\Sketch Blade - design\hub-novo\gerados\`).
- Amarelo marca-texto: uma novidade por tela ("Capítulo N desbloqueado!"), **sem enfeites** em volta (tracinhos foram cortados).

## Traço e formas
- Linhas levemente onduladas, contornos de caneta um pouco deslocados, círculos com tremor. Nada perfeitamente geométrico.
- Destaque de texto: **dois traços** (acima e abaixo), sem fechar as laterais; sublinhado só em título.
- Fundo riscado de verdade: quando o código não consegue parecer à mão, **gerar a textura no ChatGPT** (skill `gerar-imagem`) e pôr o texto por cima (como o `assets/ui/botao_riscado.png`), recolorida para o azul padrão.

## Botões
- **Uma ação principal por tela:** botão cheio com fundo azul riscado e letra branca.
- Secundário: contorno de caneta, fundo branco, mesma largura do principal.
- Nada de colchetes `[ TEXTO ]` (estilo antigo).
- Texto centrado na vertical de verdade (a moldura desenhada desloca o olho: compensar).
- Espaços **iguais** entre o último bloco, os botões e o fim do cartão.

## Cartas (roleta, descanso e pausa)
- Card desenhado no ChatGPT: contorno de caneta com sombra hachurada **sobre textura de papel** (`assets/ui/card_roleta.png`), no lugar do branco chapado. Pedido: "caneta + papel".
- A **tocada** ganha um véu **azul bem clarinho** (`#e3edfc`) e ✓ (destacar no papel, sem acinzentar a textura).
- Ordem dos textos: nome → nível ("Nv. 1 → 2" ou NOVO em marca-texto) → descrição → efeito, com **o mesmo espaço entre todos** (medido pela tinta das letras, porque Caveat e Architects Daughter têm folgas diferentes) e o bloco centrado; em cima e embaixo pode sobrar mais.
- Rodapé de contexto ("Nesta partida") grande: letra 50, ícones 100, até 3 por linha e o resto centrado na linha de baixo.
- Tocar na carta escolhe (um toque); a trava depois da animação já evita o toque sem querer.
- Com duas opções (descanso), cartas em pé lado a lado com desenho grande; nome de 1 linha centrado na altura do nome de 2 linhas, para descrição e efeito ficarem alinhados. Cada carta mostra o resultado ("5 → 7 corações").
- Estado do jogador em desenho, não só em número: corações cheios e apagados.
- Coleção (pausa): cartas grandes 2 por linha, nível em bolinhas (●●○), seção centrada no espaço livre; vazio = espaços tracejados com "?".
- Ação destrutiva (abandonar) sempre com confirmação, nunca num toque só. Ajustes rápidos (som, vibração) longe do botão principal, como ícones nos cantos do título.

## Fichas (Estojo)
- Melhoria permanente = ficha larga com cara de **etiqueta**: card da roleta + margem vermelha vertical + furo à esquerda.
- Nível em **tracinhos de contagem** (grupos de 5, o 5º corta na diagonal), os que faltam bem apagados; ele preferiu aos círculos.
- Cada estado do botão tem o próprio fundo riscado do ChatGPT: azul (dá para fazer), papel com hachura clarinha e **uma borda só** (falta algo, ainda tocável; a borda dupla incomodou) e verde (concluído, sem toque). Texto nunca encosta na borda desenhada: alargar o botão antes de diminuir a letra.

## Loja
- Mesma ficha de etiqueta do Estojo, uma por caneta (5 em lista, sem rolagem); as abas viram o título da tela ("CANETAS | PACOTES").
- Estado da caneta no botão, cada um com o fundo riscado dele: EM USO verde, EQUIPAR contorno de caneta com miolo branco (`botao_equipar.png`), COMPRAR azul com a moeda em caneta branca, falta de saldo em papel riscado clarinho. Nada de cadeado nem cartão cinzento.
- Centralização conferida **medindo a tinta nos prints** (script de medição: faixa de pixels escuros por coluna): desenho, textos e botão de cada ficha na mesma altura; o botão sobe para o meio da ficha quando nenhum texto passa por cima dele (Corações), senão fica no meio das linhas de baixo. Janela com espaços iguais entre título, desenho, nome + nota e botões, e desenhos recortados na parte visível para ocuparem a mesma altura.
- Janela de compra: card da roleta sobre o hub escurecido, o preço dentro do botão principal ("COMPRAR · R$ 4,90") e "Agora não" com contorno; nunca colchetes.

## Missões
- Janela sobre o Hub escurecido numa **folha arrancada do caderno** (picotes, pingo de tinta, ponta dobrada), não no card da roleta.
- Lista de tarefas: caixinha desenhada (vazia / ✓), tarefa paga **riscada à caneta**, progresso na mesma barra da XP do Hub.
- Aqui ele pediu botões **mais simples** que os riscados (azul liso, verde liso, rótulo tracejado para o que não é botão, "Fechar" com uma borda só): numa tela cheia de peças, o riscado pesado fica exagerado.

## Texto
- Architects Daughter para palavras; Caveat para números (com espaço extra depois do número, senão gruda: "página 6  de 8").
- **Legibilidade no celular manda:** textos azuis de informação em 42/40 (`TAM_TEXTO_AZUL`), rótulos nunca abaixo de ~40. Toda vez que algo ficou pequeno (34, 36, letras do selo), ele pediu para aumentar.
- Números grandes com ponto de milhar ("+1.058").
- Cortar o que repete: se o título, a arte e o selo já dizem, a frase sai.

## Ilustração
- Desenho grande no centro, ocupando o espaço livre; os elementos de texto descem para perto do botão.
- Sempre os desenhos do jogo (`assets/inimigos/chefe_N.png`, `stage N`), não os do rascunho.
- **Selo redondo vermelho "DERROTADO"** no canto de baixo da arte, inclinado, grande o bastante para ler o anel (capítulo e nome do chefe), **sem cobrir o rosto**.
- Vitória: o chefe entra colorido e, quando o selo bate, perde parte da cor (~50%, os olhos continuam vermelhos, sem transparência).
- Derrota: irmã da vitória com título vermelho; mostra até onde chegou (trilha com X vermelho) e o recorde, para motivar a revanche. Frases azuis de motivação grandes (52/50): ele pediu para aumentar de 42/40.

## Ícones
- Estilo do rascunho do amigo: **simples**, contorno grosso de caneta, hachura leve, miolo branco, poucos detalhes (a asa ficou boa com 3 dobras; a detalhada não). Sem brilhinhos nem rabiscos em volta.
- Ícone ao lado do valor que ele representa (gota + "+1.058 tinta").
- Em cima do azul (botão cheio), ícone em **caneta branca com o miolo vazado**, nunca silhueta branca cheia: `assets/ui/gota_branca.png` (gerada por `tools/gerar_gota_branca.gd`; o mesmo método serve para outros ícones).

## Informação e recompensa
- Um "herói" por bloco (o total de tinta), com um rótulo legível ("Tinta conquistada").
- Detalhar quando ensina algo: os bônus separados (coletada, vidas, capítulo) ficaram, porque mostram que vale terminar com corações.
- Progressão como barra (XP), não como linha de texto. A linha "Nv. 6 [barra] +23 XP" fica **centrada na página como um bloco só**.
- Exceção: na "Segunda chance?" (reviver) o anúncio é o botão cheio, porque a tela só existe para oferecê-lo; mesmo assim, com ícone de anúncio no botão, aviso escrito acima e botões travados ~0,8 s.
- Anúncio: sempre **opcional e explícito** ("Ver anúncio · +1.058"), nunca o botão principal, só funciona depois que a animação termina, e mostra "Bônus recebido ✓" depois.

## Como ele decide
- Rascunho do amigo designer como base; conselho de LLMs para cortar excesso; ele escolhe misturando as duas coisas.
- Sempre **print real do jogo** (1080x1920) antes/depois na página "Melhorias visuais"; uma tela por vez; ajustes finos em rodadas curtas (tamanho, posição, cor, espaço).
- Protótipo primeiro (script `extends SceneTree` montando por cima da tela real, sem mexer no jogo), implementação depois do OK.
