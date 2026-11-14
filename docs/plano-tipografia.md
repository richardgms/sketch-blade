# Tipografia: troca de fontes e revisão tela por tela

Iniciado em 13/11/2026. Página com todos os prints: https://claude.ai/artifact/CLaPTwznyGYyLuizVgxoZu (seções "Kalam…" e "Legibilidade…").

## Situação
- Hoje: texto em `assets/fonts/ArchitectsDaughter-Regular.ttf` (carregada por caminho em vários scripts: Hub, Main, TelaFim, SeloDerrotado, cenas .tscn) e números/destaques em `assets/fonts/Caveat/static/Caveat-Bold.ttf` (constantes `FONTE_NUMEROS` / `NUM`).
- Problema: as duas são difíceis de ler no celular (dono testou 11 fontes).
- **Escolhida: Kalam** (OFL) — Regular para texto/títulos/botões, Bold para números e destaques. Uma família só por tela. Arquivos fora do projeto: `Documentos\Sketch Blade\design\tipografia\fontes\Kalam-Regular.ttf` e `Kalam-Bold.ttf`.

## Como testar sem mexer no código
Copiar a Kalam por cima dos dois .ttf, `--import`, `bash tools/capturar_telas.sh <pasta> <telas>`, restaurar os originais (backup antes) e `--import` de novo; conferir `git status assets/` limpo. Prints em `Documentos\Sketch Blade\design\tipografia\kalam\` (`antes`, `kalam`, `numeros`).

## Feedback do dono (14/11) sobre a Kalam Bold nos números
- **Pausa:** ficou muito boa, melhor que antes.
- **Missões de hoje:** bom, mas botões muito apertados; ícones de clipe, tinta (versão branca) e check ficaram menores/mais finos e destoam do traço da fonte.
- **Loja:** vantagens das canetas em duas linhas ficaram cortadas; botões sem espaçamento.
- **Estojo:** no botão de comprar upgrade, o número ficou grosso demais perto do ícone e do texto.
- **Regra geral:** a grossura do número não pode destoar da do texto nem do traço dos ícones, principalmente em botões. Considerar Kalam Regular nos números dentro de botões, ou ajustar tamanho/ícone junto.
- Refinamento cauteloso, **tela por tela**, com print antes/depois na página.

## Plano
1. Pôr Kalam-Regular e Kalam-Bold em `assets/fonts/Kalam/` e trocar as referências (um só lugar de constante, se possível).
2. Revisar cada tela com print (Hub, Missões, Loja, Estojo, Pausa, Roleta, Vitória, Derrota, Descanso, Configurações, Recompensa, Novidades, Avaliação, Prova do dia, HUD): espaço dos botões, textos cortados, peso número × texto × ícone, tamanho dos ícones ao lado de números.
3. Uma tela por vez: mostrar na página, aprovar, commitar.
4. Na próxima versão: atualizar `VERSAO_NOME`/`NOVIDADES` (letras mais legíveis) e subir o código.

## Feito
- Pausa: cartas de melhoria com folga entre nome, bolinhas e bordas (commit eb9f170).
- Prova do dia: letras de 46 px entre pautas (`JanelaDesafio.gd`).
