# Plano de publicação — Sketch Blade (Play Store)

Atualizado em 2026-11-04. Fonte única do plano; marque cada item ao concluir.

## Build 1.8.1 (código 16) — teste fechado (04/11/2026)
- Pedido do Richard: novo build para testar a trilha sem o metrônomo na partida e nos chefes.
- [x] Atualizar versão 1.8.1 e sincronizar os códigos do preset e de `GameData` em 16.
- [x] Importar e testar música, sons e hub: 7 verificações de sons, 17 de música sem metrônomo e abertura/navegação do hub passaram, código de saída 0. Save restaurado e bytes/hash conferidos. Logs em `%TEMP%/sketchblade-181-kwy0qbb6/`.
- [x] Exportar AAB de release assinado em `Documentos/Sketch Blade - builds/sketchblade-1.8.1-vc16.aab`: **68.029.850 bytes (68,0 MB)**. O processo deste export foi encerrado após o pacote assinado ficar íntegro e estável por 15 s, como no build anterior.
- [x] Conferir assinatura, manifesto, 11 camadas de música, ausência do metrônomo e maiores arquivos: ZIP íntegro; assinatura validada por `jarsigner`, mesmo certificado de upload dos builds anteriores; manifesto com versão **1.8.1 (16)**. Os **40 sons + 11 camadas** correspondem aos importados locais. Nenhum arquivo do metrônomo, foto, rascunho ou credencial no pacote.
- [x] Disponível no teste fechado: Richard confirmou que o link da Play exibe ATUALIZAR.
- [ ] Concluir o teste de áudio no celular.
- [x] Aviso público atualizado para **1.8.1 (16)** após essa confirmação: antes ainda anunciava 15, por isso o app 1.8.0 não mostrava atualização. Push isolado do JSON, commit `c27193c`; nenhum outro código foi publicado.
- Validação do aviso: `tools/teste_aviso_atualizacao.gd` passou nas **7 verificações**, incluindo HTTP 200 no endereço real e correspondência com o JSON local, código maior abrindo a janela e versão igual sem aviso. Save restaurado e conferido. Logs em `%TEMP%/sketch-blade-continuacao-juh7dyfz/`. O teste agora compara com o JSON do projeto, sem fixar um número de versão no script.
- O app busca o aviso ao abrir o hub na inicialização; fechar completamente e abrir com internet força a nova consulta. Quem já estiver na 1.8.1 não verá aviso dessa mesma versão.
- [x] **Confirmado no celular pelo Richard: “funcionou”**, após a publicação do aviso da 1.8.1 (16). Isso confirma o fluxo do aviso; o teste completo do áudio continua pendente.
- SHA-256: `b4282e5d134a6fce1d15771f164457363f00e0bcab3b8540cd762f31be518e29`. Relatório: `sketchblade-1.8.1-vc16.validacao.json`, ao lado do AAB.
- Maiores arquivos (descomprimidos): motor Godot 71,15 MB; DEX 10,18 / 7,49 / 3,53 MB; ícone 2,37 MB; splash 2,32 MB; texturas seguintes até 1,81 MB.
- Notas para a Play: “Ajustes na trilha sonora para uma experiência mais agradável durante as partidas.”

## Build 1.8.0 (código 15) — teste fechado (04/11/2026)
- Destino confirmado pelo Richard: teste fechado da Play Console. Música e sons aprovados; marimba aprovada para a contagem.
- [x] Atualizar `version/code` e `GameData.VERSAO_CODIGO` para 15, versão 1.8.0.
- [x] Ligar a marimba aprovada no 3-2-1-JÁ e manter o tratamento reproduzível em `tools/sons_lote2.py`.
- [x] Importar e validar música, sons e hub no PC, preservando o save: 7 verificações de sons, 17 de música e hub passaram; save restaurado e conferido. Logs em `%TEMP%/sketchblade-180-frtbq_pj/`.
- [x] Exportar AAB de release assinado para `Documentos/Sketch Blade - builds/sketchblade-1.8.0-vc15.aab`: **68.196.260 bytes (68,2 MB)**. O Godot permaneceu aberto depois de gravar o pacote; só o processo deste export foi encerrado após o ZIP assinado ficar íntegro e estável por 15 s.
- [x] Conferir integridade, assinatura, versão, áudios novos e maiores arquivos do AAB: ZIP íntegro; `jarsigner -verify` confirmou a assinatura; certificado de upload igual ao AAB 1.7.4. Manifesto protobuf conferido com as classes do `aapt2-proto` já instalado: pacote `com.richardgms.sketchblade`, versão 1.8.0, código 15. **40 sons + 13 camadas de música** coincidem byte a byte com os recursos importados locais. Sem JPG/JPEG/PSD, `store/`, rascunhos, credenciais, saves ou morte 7/8.
- [x] Disponível na faixa fechada: Richard relatou que atualizou pela Play pelo link salvo.
- [ ] Concluir o teste no celular: música por 10 min, pausa/retomada, segundo plano, chefe/raiva, sons e contagem. A escuta motivou a retirada do metrônomo, já incluída no AAB 1.8.1 (16).
- Manter `MODO_TESTE = true` e anúncios de teste para esta faixa. Atualizar `atualizacao/versao.json` somente depois de a Play disponibilizar esta versão.
- Ajuste de escuta posterior: metrônomo retirado do código e dos assets a pedido do Richard. **Este AAB 1.8.0 ainda tem o metrônomo**; a alteração já está no AAB 1.8.1 (16), descrito acima. Detalhes em `plano-musica-adaptativa.md`.
- SHA-256: `4a24895c7b6991adf092ff035c1f5952cac2a8f0d301ac7e949deeb6adfaaac0`. Relatório ao lado do AAB: `sketchblade-1.8.0-vc15.validacao.json`.
- Maiores arquivos (tamanho descomprimido): motor Godot 71,15 MB; três DEX 10,18 / 7,49 / 3,53 MB; ícone 2,37 MB; splash 2,32 MB; demais maiores são texturas do jogo (até 1,81 MB).
- Notas para a Play: “Nova trilha sonora que acompanha a intensidade das partidas e das batalhas contra os chefes. Novos efeitos sonoros deixam o combate e a navegação mais envolventes.”

## Estado encontrado (investigação)
| Item | Estado |
|---|---|
| Pacote | `com.richardgms.sketchblade`, versão 1 / "1.0", só arm64 |
| Build de teste (APK debug) | Gerado e instalado no celular em 24/10/2026 |
| Preset de release (AAB) | Pronto, mas **sem keystore de release** (só a de debug do Godot) |
| Plugin AdMob | Instalado em 28/10/2026 (ver Versão 1.2.0) |
| Código do AdMob real | `AdsManager.gd` reescrito com a API do plugin (28/10/2026) |
| Política de privacidade | Pronta em `docs/privacy.html` (GitHub Pages) |
| Ícone 512 e recurso gráfico 1024x500 | Prontos em `store/` |
| Screenshots da loja, textos, classificação, Data Safety | Não feitos |
| Conta Google Play Console | Não confirmado |

## Etapas
1. **Conta de desenvolvedor Google Play** (taxa única de US$ 25, verificação de identidade). Só o Richard pode fazer. Começar já: a verificação demora.
2. **AdMob**: criar conta, cadastrar o app, criar o bloco de anúncio premiado (rewarded) e anotar os IDs reais.
3. **Plugin AdMob no projeto**: instalar, ajustar `AdsManager.gd` à API real, testar com os IDs de teste num APK no celular, só então trocar pelos IDs reais.
4. **Keystore de release**: gerar, guardar fora do repositório, com cópia de segurança em dois lugares. Perder a chave = não conseguir mais atualizar o jogo.
5. **Build de release (AAB)** assinado, versão 1 / "1.0".
6. **Ficha da loja**: nome, descrição curta e longa, 2+ screenshots do celular, ícone, recurso gráfico, categoria, e-mail de contato, link da política de privacidade.
7. **Formulários do Play Console**: classificação etária, segurança dos dados (Data Safety), declaração de anúncios, público-alvo.
8. **Teste fechado**: contas novas de pessoa física costumam exigir um teste fechado com testadores por um período mínimo antes da produção (conferir a regra atual no Play Console).
9. **Produção**: enviar para revisão e acompanhar.

## Etapa 1 — conferir a conta (a conta já existe)
Passo a passo completo na página de acompanhamento (Artifact). Resumo: abrir o Play Console, anotar avisos pendentes, conferir detalhes da conta, perfil de pagamentos e tipo (pessoal/organização), criar o app "Sketch Blade" (Jogo, Gratuito, pt-BR) e anotar o que a lista "Configurar seu app" mostra pendente.

Resultado (24/10/2026): conta **pessoal**, sem avisos de verificação/pagamento no topo; app "Sketch Blade" (`com.richardgms.sketchblade`) já criado em **rascunho** (última atualização 21/07/2026). Falta: lista "Configurar seu app" e a regra de teste fechado exibida no painel.

Atualização: "Configurar seu app" está em **10 de 11** (política, login, anúncios, classificação, público-alvo, segurança dos dados, governamentais, financeiros, saúde, categoria/contato: feitos). Falta só a página "Detalhes do app" (textos em `docs/ficha-da-loja.md` + 2–8 prints do celular).

Regra do teste fechado (lida no painel): mínimo de **12 testadores** por **14 dias**; só libera depois de terminar a configuração do app. É o gargalo do prazo.
- **08/11/2026:** Painel → "Solicitar o acesso de produção" mostra **10 testadores participando**; faltam 2. Os 14 dias só contam depois de 12. Só conta quem aceitou o convite pelo link (não basta estar na lista de e-mails nem instalar).
- **09/11/2026:** **12 testadores** aceitos (os dois primeiros itens do Painel marcados). Falta o último: manter o teste fechado com 12 por **14 dias** → previsão de liberar "Solicitar a produção" a partir de **23/11/2026**. Manter os 12 ativos até lá (se alguém sair, o prazo pode recomeçar).

A conferir depois: se o que foi declarado em Anúncios e Segurança dos dados (feitos em jul/2026) bate com o AdMob real (ID de publicidade etc.).

## Correções da investigação (24/10/2026, após ler memória do projeto)
- **Keystore de release existe**: `C:\Users\joalh\Documentos\keys\sketchblade-upload.jks` (jul/2026), ligada no preset via `.godot/export_credentials.cfg` (ignorado pelo git). A tabela inicial dizia que não existia: estava errada. Falta conferir cópia de segurança.
- **AdMob etapa 2 feita** em 21/07/2026: conta, app e 3 blocos premiados (Reviver, Dobrar Tinta, Dobrar Diária). IDs na memória do projeto (`admob_ids`; não são segredo). Pendente do usuário: perfil de pagamento do AdMob. Plano original: o closed test vai com anúncios simulados; plugin e IDs reais entram durante os 14 dias; IDs de teste do Google durante o desenvolvimento (clicar em anúncio real = risco de ban).
- **Nome na loja**: decisão de jul/2026 = "Sketch Blade: Tinta & Papel".

## Riscos para resolver antes da produção
- **Compra falsa no Hub** (`Hub.gd` `_on_confirmar_compra_pressed`): botões "R$ 4,90" dão 100 clipes / 5000 tinta sem cobrança. Não passa na política da Play Store; remover ou implementar Google Play Billing.
- **Marca BIC**: nome da caneta trocado para "Caneta Azul" em `GameData.gd` (feito em 25/10/2026; o id interno `bic_azul` e os nomes de arquivo foram mantidos para não quebrar saves). Textos da loja sem "BIC". Comentários de código com "azul BIC" não aparecem ao jogador. Resta avaliar se o desenho da caneta (tipo Cristal) é problema.

## Página "Detalhes do app" (25/10/2026)
Preenchida no Play Console: nome "Sketch Blade: Roguelite", descrições, ícone, recurso gráfico, 7 prints (celular, tablet 7" e 10"). Na tela de Avaliação o Google pede a **declaração de recursos de IA**: a arte do jogo, o ícone e o gráfico foram gerados com IA (ChatGPT), então marcar "Rotular os recursos como criados ou editados com IA" e rotular ícone, gráfico e capturas.

## ID de publicidade (25/10/2026)
O envio do Teste fechado exigiu a declaração de ID de publicidade (Android 13+). O AAB atual não tem AdMob (MODO_MOCK) e portanto não tem a permissão `com.google.android.gms.permission.AD_ID`. Decisão final (25/10/2026): declarar **Sim** (o jogo final usa AdMob), finalidade **Publicidade ou marketing**, e marcar "Desativar os erros de lançamento" apenas para esta versão sem anúncios; é o caminho que a própria tela do Google indica. Quando o AdMob real entrar, a permissão `AD_ID` vem com ele e a caixa não é mais necessária. Rever a Segurança dos dados nessa hora.

## Incidente: fotos de cliente dentro do build (26/10/2026)
Oito fotos de outro cliente (antes/depois de cirurgia, rosto) estavam soltas na raiz do projeto e o export (`all_resources`) as empacotou no AAB v1 (115 dos 191 MB) e no APK de debug. A v1 chegou ao Teste interno e foi aprovada no Teste fechado (25/10 20:06); só os 3 da lista `Interno` tinham acesso. Ações: faixa do Teste fechado pausada; fotos e cópias (`.godot/imported`, `android/build`) movidas para a Lixeira; `exclude_filter` no preset; AAB **1.0.1 (código 2)** gerado e conferido sem as fotos: **68,3 MB**. Falta: pausar/atualizar o Teste interno, subir a v2 nas duas faixas, apagar o APK de debug do Drive e do celular, apagar os pacotes antigos da pasta de builds. O pacote v1 continua na biblioteca do Google.

## Teste fechado em andamento (26/10/2026)
- Versão 1.0.2 (código 3) no Teste fechado (a 1.0.1 ficou "Substituída por outra versão" e não liberava o link; resolvido com código novo só para o fechado). Teste interno com 1.0.1 (2). Esposa e primo instalaram.
- Relato do primo: o jogo fechou sozinho uma vez na página 7 (horda) e voltou do zero. Causa do fechamento ainda desconhecida (suspeita: memória do celular dele). Android vitals só libera após produção; aguardar o Relatório de pré-lançamento e o modelo do celular.
- Corrigido no código (não publicado ainda): checkpoint da run no início de cada página (`Main._on_pagina_iniciada`); antes só salvava ao ir para segundo plano. Testado: restaura página, tinta e upgrades. Vai na versão 4 junto com a correção do fechamento.

## Versão 1.1.0 (código 4) — 27/10/2026
AAB: `Documentos\Sketch Blade - builds\sketchblade-1.1.0-vc4.aab` (43,8 MB; antes 68,3). Inclui checkpoint por página, roleta redesenhada, missões no layout limpo, janela de compra corrigida, telas de resultado enxutas, HUD maior, imagens no tamanho de tela (~52 MB de memória de vídeo, antes ~209). Conferido: sem fotos de cliente, com BILLING, assinado. Detalhes em `docs/revisao-visual.md`. Antes da produção: `GameData.MODO_TESTE = false`.

## Versão 1.2.0 (código 5) — plano (28/10/2026)
1. [x] **[+] de compra sem resposta**: as telas do Hub (`TelaLutar/Estojo/Loja` e o container da loja) cobriam o topo com `mouse_filter` STOP. Corrigido e testado por script (toque simulado nas 3 abas).
2. [x] **Aba "Pacotes" na Loja**: título vira abas Canetas | Pacotes; cartões com preço da Play Store; os [+] do topo abrem Pacotes (`Hub._montar_pacotes`).
3. [x] **Oferta quando faltar saldo**: upgrade do Estojo ou caneta sem saldo abre a confirmação do pacote, 1x por moeda a cada visita ao Hub (`Hub._oferecer_pacote`).
4. [x] **AdMob real**: plugin poing-studios v5.1.0 em `addons/admob` (só Android; binários em `android/bin/ads`, `package.gd` criado à mão para o plugin não baixar nada no export headless; C#, iOS, docs e skills com `.gdignore`). App ID real em `project.godot` (`admob/general/android/app_id`). `AdsManager` pré-carrega um anúncio por placement e só concede no `on_user_earned_reward`; `USAR_BLOCOS_TESTE = true` usa o bloco de teste do Google — trocar para false só antes da produção. Recompensa diária: botão não trava mais se o anúncio falhar.
5. [x] Build 1.2.0 (código 5) **gerado**: `Documentos\Sketch Blade - builds\sketchblade-1.2.0-vc5.aab` (54,7 MB; +8,8 MB do SDK de anúncios). Conferido: SDK de anúncios, App ID, AD_ID, BILLING, sem fotos. Falta: enviar ao Teste fechado/interno, testar compra e anúncio no celular, rever Segurança dos dados. **Testado no celular pelo Richard (28/10): compra de teste e anúncio de teste funcionando.**
6. [ ] **Combate (versão 1.3.0)**. Etapa 1 feita (28/10): tiro em cometa de tinta (`Projectile._draw`), respingo no acerto (`ImpactoTinta.gd`), piscar branco por shader (`flash.gdshader`; o `modulate` antigo não clareava tinta escura), empurrão leve, números 46/64 px, tremor curto no crítico. Etapa 2 feita (28/10, decidida por conselho de LLMs): desenho por IA por tipo (`assets/inimigos/*.png`, 256 px; chefe 512 px; originais em `Documentos\Sketch Blade - arte original\inimigos`), animação por código (respira/balança) e tremido de desenho à mão no `flash.gdshader` (8 passos/s). Elite: auréola dourada atrás do desenho. Medido no PC com 30+ inimigos: 120 fps, 110 draw calls, 35 MB de VRAM de texturas. Falta: medir no celular. Blender/After Effects/HTML ficam para o trailer da loja.

**Build 1.7.4 (código 14) gerado em 01/11**: `Documentos\Sketch Blade - builds\sketchblade-1.7.4-vc14.aab` (62,1 MB). Novidade desde a 1.7.3: aviso de versão nova no Hub (`GameData.VERSAO_CODIGO = 14`); economia, compras e anúncios iguais. Conferido: zip íntegro, assinado (UPLOAD), versão 1.7.4 no manifesto, permissão de internet, `JanelaAtualizacao` dentro, sem `.jpg`, `store/`, `referencias/` nem a pasta `atualizacao/`; maiores arquivos = motor, código Android, ícone e splash. Ainda com `MODO_TESTE = true` e anúncios de teste. Falta: enviar ao Teste fechado (o 14 substitui o 13 se ele não foi enviado) e, depois de publicado, trocar `atualizacao/versao.json` para o código 14 — e ninguém vê aviso por ela, porque é a primeira com o aviso.

## Aviso de atualização (01/11/2026)
O Hub mostra "PÁGINA NOVA!" quando sai versão nova (`JanelaAtualizacao.gd`, versão A aprovada; página: https://claude.ai/artifact/DW93hYy2bsenc71zB8oLHP). Ao abrir o Hub (só no Android, uma vez por abertura do app) o jogo baixa `atualizacao/versao.json` do GitHub público (`Hub.URL_VERSAO`, raw do `main`) e compara `codigo` com `GameData.VERSAO_CODIGO`; se for maior, mostra a versão e até 3 `novidades`, com ATUALIZAR (abre a Play Store) e "Agora não". Espera a recompensa diária fechar. Sem internet ou arquivo ruim: nada aparece. Nada vai para o save. A pasta `atualizacao/` tem `.gdignore` (fora do build).
**A cada versão:** (1) subir `version/code` no `export_presets.cfg` **e** `GameData.VERSAO_CODIGO` juntos (se esquecer o segundo, quem já atualizou vê o aviso para sempre); (2) só depois que a Play publicar, trocar `codigo`, `versao` e `novidades` (as mesmas notas da Play Console, curtas) em `atualizacao/versao.json` e dar push. Se subir antes, o aviso manda para a loja sem atualização disponível. Só chega a quem já tem uma versão com o aviso (a partir da próxima depois da 1.7.3). Teste: `capturar_telas.sh <pasta> atualizacao,atualizacao-fluxo` (inclui a leitura de verdade do arquivo no GitHub).

## Correção do aviso após a publicação da 1.8.0 (04/11/2026)
- Richard relatou que atualizou pela Play pelo link salvo, mas o aviso no jogo não apareceu. A consulta direta ao endereço de `Hub.URL_VERSAO` retornou HTTP 200 ainda anunciando **1.7.3 (13)**. Esse código não supera o de quem estava na 1.7.4 (14), então o aviso fica oculto; aguardar horas não altera essa comparação.
- Correção publicada: **somente** `atualizacao/versao.json` passou a anunciar a versão disponível **1.8.0 (15)** e as notas aprovadas. Commit remoto `0caa6d5`, criado em checkout temporário a partir do `origin/main`; os commits locais de áudio e os arquivos de compras/anúncios não foram enviados.
- `tools/teste_aviso_atualizacao.gd`: **7 verificações passaram**, incluindo a leitura real do endereço público (HTTP 200, versão 15), versão igual sem aviso, código maior com aviso, JSON inválido e não duplicação na mesma abertura. Save restaurado e conferido; logs em `%TEMP%/sketch-blade-continuacao-tjtsjr76/`. A importação e o teste saíram com código 0; houve apenas avisos de recursos ao encerrar.
- Quem já atualizou para a 1.8.0 não recebe aviso dessa mesma versão. O hub consulta ao abrir o jogo; testar a versão anterior exige fechar o app e abrir novamente com internet. Depois de cada publicação disponível na Play, atualizar este JSON com as mesmas notas da versão.
- A remoção posterior do metrônomo entrou no AAB 1.8.1 (16), gerado e validado; aguarda envio à Play.

## Decisões em aberto
- Confirmar o nome na loja (Tinta & Papel ou Roguelite).
- Quem serão os 12 testadores (precisam de Android e conta Google).
- Compra falsa: remover botões ou implementar Play Billing.

## Histórico
- 2026-10-24: investigação feita, plano criado.

## Chefes e combate
Fonte única: `docs/chefes.md` (regras de design, situação de cada chefe, arquitetura, como testar). Versão 1.4.0 (código 7) gerada em 28/10 com chefes 2, 3 e 5. Depois dela: os 10 chefes prontos e calibrados (`docs/equilibrio-chefes.md`), sinal de raiva e contador de vitórias/derrotas por capítulo no painel "Stats de teste" (o atalho "Testar chefe" não conta). **Build 1.5.0 (código 8) gerado em 28/10**: `Documentos\Sketch Blade - builds\sketchblade-1.5.0-vc8.aab` (58,7 MB). Conferido: assinado, 10 chefes, sem fotos; maiores arquivos = motor, código Android, ícone, splash e música. Ainda com `MODO_TESTE = true` e anúncios de teste. **Enviado ao Teste fechado em 29/10.** Falta: jogar no celular e mandar print do "Stats de teste".

**Build 1.6.0 (código 9) gerado em 29/10**: `Documentos\Sketch Blade - builds\sketchblade-1.6.0-vc9.aab` (59,1 MB). Novidades: hub novo (3 telas), vitória e derrota redesenhadas (`docs/proximas-melhorias.md`). Conferido: assinado, versão 1.6.0, telas novas dentro, sem fotos; maiores arquivos = motor, código Android, ícone, splash e música. Ainda com `MODO_TESTE = true` e anúncios de teste. Falta: enviar ao Teste fechado. Obs.: o export terminou o AAB mas o Godot ficou aberto; conferir o arquivo e encerrar o processo.

**Build 1.7.0 (código 10) gerado em 30/10**: `Documentos\Sketch Blade - builds\sketchblade-1.7.0-vc10.aab` (58,1 MB). Novidades desde a 1.6.0: reviver "Segunda chance?", HUD do combate (coração e barra de vida riscada), chefe legível, 10 sons gravados, dica da primeira gota, mortes por página no "Stats de teste", roleta de melhorias nova, música e exemplos do plugin de anúncios fora do pacote (`docs/proximas-melhorias.md`). Conferido: zip íntegro, assinado (UPLOAD), versão 1.7.0, `TelaRoleta` e `card_roleta` dentro, sem fotos, sem `music.ogg`; maiores arquivos = motor, código Android, ícone e splash. Ainda com `MODO_TESTE = true` e anúncios de teste. O export grava o AAB mas o Godot não fecha sozinho: rodar com `timeout` e conferir o arquivo. **Enviada ao Teste fechado em 30/10** e atualizada no celular do Richard ("ficou bem legal"). Falta: jogar mais partidas no aparelho.

**Build 1.7.1 (código 11) gerado em 30/10**: `Documentos\Sketch Blade - builds\sketchblade-1.7.1-vc11.aab` (57,8 MB). Novidades: página de descanso e pausa no estilo caderno (pausa com confirmação para abandonar e som/vibração rápidos); saiu a moldura antiga `assets/backgroundpowerup.png`. Conferido: zip íntegro, assinado (UPLOAD), versão 1.7.1, `TelaDescanso`/`TelaPausa`/`TelaRoleta`/`card_roleta` dentro, sem fotos. Ainda com `MODO_TESTE = true` e anúncios de teste. Falta: enviar ao Teste fechado.

**Build 1.7.2 (código 12) gerado em 31/10**: `Documentos\Sketch Blade - builds\sketchblade-1.7.2-vc12.aab` (60,2 MB). Novidades desde a 1.7.1: Estojo, Loja (Canetas | Pacotes), Missões, Recompensa diária e Configurações no estilo caderno (`docs/proximas-melhorias.md`); compras, preços, prêmios e anúncios iguais. Conferido: zip íntegro, assinado (UPLOAD), versão 1.7.2 no manifesto, telas novas dentro, sem fotos e sem `store/`; maiores arquivos = motor, código Android, ícone, splash e a folha das janelas (`fundo_missoes`, 1,5 MB). Ainda com `MODO_TESTE = true` e anúncios de teste. Falta: enviar ao Teste fechado (se a 1.7.1 não foi enviada, basta a 1.7.2: o código 11 pode ser pulado).

**Build 1.7.3 (código 13) gerado em 31/10**: `Documentos\Sketch Blade - builds\sketchblade-1.7.3-vc13.aab` (62,1 MB). Novidades desde a 1.7.2: topo da partida 30% maior, chefes sem teleporte no balanço (Mancha e Avião), selo DERROTADO do Hub no lugar da vitória, tela antes da partida (ficha colada), virada de página pelo canto, respingo de tinta na morte, papel com textura (limpo; usado nos quadriculados e amarelados) e linha-limite tracejada à mão (`docs/proximas-melhorias.md`); economia, compras e anúncios iguais. Conferido: zip íntegro, assinado (UPLOAD), versão 1.7.3 no manifesto, scripts e imagens novos dentro, sem `.jpg`, `store/` ou rascunhos; maiores arquivos = motor, código Android, ícone e splash. Na 1ª exportação as texturas de papel eram `.jpg` e ficaram de fora (o export exclui `*.jpg`): trocadas por PNG antes do build final. Ainda com `MODO_TESTE = true` e anúncios de teste. Falta: enviar ao Teste fechado (pode pular os códigos 11 e 12 se não foram enviados).

## Build 1.8.2 (17) — 04/11/2026
AAB gerado em `Documentos/Sketch Blade - builds/sketchblade-1.8.2-vc17.aab`
(68.722.773 bytes). Inclui mixagem clara, mortes tratadas, vinheta com alfa,
aviso de raiva, dano junto do chefe e clique com zíper. ZIP íntegro, assinatura
UPLOAD verificada pelo jarsigner, versão 1.8.2 no manifesto e arte nova incluída.
Maiores arquivos: motor ARM64, DEX, ícone e splash; sem JPG, store ou referências.
JDK 25 emite avisos de certificado autoassinado e leitura JarInputStream, mas
retorna `jar verified` e código 0. Mantidas configurações do teste fechado.
Pronto para envio manual; JSON de atualização só muda após publicação na Play.

## Aviso da 1.8.2 publicado — 04/11/2026
Usuário confirmou atualização disponível na Play. JSON público ainda estava
em 1.8.1 (16); publicado apenas `atualizacao/versao.json` com 1.8.2 (17),
commit remoto `4413b27`, em checkout separado dos commits locais.
Primeiro teste HTTP respondeu 200 com conteúdo antigo em cache e falhou na
comparação; não representa aprovação do teste completo. Save restaurado por hash.
A rotina atual depende de atualizar o JSON após a disponibilidade na Play;
gerar o AAB sozinho não aciona o aviso. Automação ainda não implementada.

Conferência posterior: `refs/heads/main` remoto aponta para `4413b278`, e o
JSON pelo SHA responde HTTP 200 com código 17. Endereço `main` ainda retornava
16 por cache no momento da conferência, inclusive com query de verificação.
Automação recomendada para avaliação: Play In-App Updates consultando a
 disponibilidade para a conta instalada; exige integração Android e novo build.
Fonte: https://developer.android.com/guide/playcore/in-app-updates/kotlin-java
Checkout temporário de publicação preservado em `%TEMP%/sketch-blade-aviso-v17`.

## Atualização automática e build 1.8.3 (18) — 04/11/2026
Usuário aprovou manter a notinha, com detecção pela Play. Implementação,
recompilação e teste real pendente em `docs/plano-atualizacao-play.md` (fonte única).
A partir desta versão, publicar JSON deixa de ser necessário para detectar novas
versões; continua útil para os textos e os jogos antigos já instalados.

AAB: `Documentos/Sketch Blade - builds/sketchblade-1.8.3-vc18.aab`,
68.746.548 bytes. Exportação concluída; pacote ZIP íntegro, manifesto 1.8.3,
registro do plugin v2, classe do plugin e biblioteca AppUpdate presentes nos DEX.
Sem JPG ou store; fontes Java/Gradle do plugin excluídas por `.gdignore`.
Scripts de diagnóstico em tools/ continuam no pacote, como nos builds anteriores.
Maiores arquivos: motor, DEX, ícone e splash. Assinatura UPLOAD verificada
pelo jarsigner (retorno 0, `jar verified`).
16 testes de lógica passaram; confirmação em aparelho via Play ainda pendente.
Não publicar anúncio JSON desta versão antes da disponibilidade na Play.

## Build 1.8.4 (19) — 05/11/2026
- AAB: `Documentos/Sketch Blade - builds/sketchblade-1.8.4-vc19.aab`,
  68.783.166 bytes. Inclui enquadramentos finais ajustados pelo usuário,
  heartbeat/zumbido e música em vida crítica, jingles de vitória/derrota
  corrigidos e som de moedinha junto ao check no resgate de missão diária.
- `version/code` e `GameData.VERSAO_CODIGO` em 19; nome 1.8.4. Configurações de
  teste fechado preservadas. Consulta automática de atualização Play incluída.
- Export concluído; ZIP íntegro; versão 1.8.4 no manifesto; plugin da Play e
  os dois novos sons críticos presentes. Assinatura UPLOAD: jarsigner exit 0,
  `jar verified`. Sem store, referências, JPG/JPEG/PSD ou cena auxiliar de ajustes.
- Maiores arquivos: motor ARM64, três DEX, ícone, splash e ícone importado.
- SHA256: `fb39228ce701cea0ece55c32d14d3f6ec082acdcc5c4d02c34556b02f9fbf2cc`.
- Pronto para envio manual à Play. Escuta dos novos sons no celular e teste
  real da detecção de atualização permanecem dependentes da instalação via Play.

### Envio e notas combinadas da 1.8.4
Richard informou em 05/11 que não enviou a 1.8.3 e enviou diretamente esta
1.8.4. Publicação confirmada por ele em 05/11; JSON anunciando 1.8.4 (19)
publicado em push isolado (commit remoto `c9663bd`). O upload pelo
agente não ocorreu: Computer Use foi interrompido por não conseguir determinar
com confiança a URL atual do Chrome. O próprio usuário assumiu o upload.

Notas fornecidas para a Play (incluem as duas versões):

```text
<pt-BR>
• Aviso de atualização integrado à Play Store.
• Alerta de vida crítica com heartbeat reforçado, zumbido e música suavemente abafada.
• Correção dos sons de vitória e derrota.
• Som de moedinha ao resgatar missões diárias.
• Miniaturas dos chefes com foco no rosto e recorte circular.
</pt-BR>
```

Após confirmar a disponibilidade, anunciar código 19 no JSON para instalações
antigas (como 1.8.2), que ainda dependem desse arquivo. Na 1.8.4 instalada, a
consulta automática será comprovada com uma atualização posterior (>19) oferecida
à mesma conta. Não confundir upload iniciado com versão publicada.

## Build 1.8.5 (20) — 06/11/2026
Upgrades da roleta refeitos (`docs/plano-upgrades.md`, página
https://claude.ai/artifact/TJVaMr4MGn6EGpBcQjzUyZ, tudo aprovado pelo Richard).
- Mecânica: Corrosiva 20/35/50% do dano do tiro por s por 3 s; Borrão 40/60/80%
  do dano da caneta, raio 200/240/280. Dano contínuo em pulsos de 0,5 s.
- Visual: escudo em forma de borracha (azul/vermelho) com quebra animada em 10
  quadros; explosão em nuvem animada em 6 quadros; corrosão com vapor e bolhas à
  caneta. Dano de corrosão em verde e de explosão em rosa. Avisos (MORREU!,
  APAGADO!) com contorno e fora do alvo; escudo mostra um texto só.
- Antes do build: cartas da roleta conferidas com os textos novos; robô nos 10
  chefes (esquiva, 1 semente, 30 lutas) achou erro de script na corrosão
  (parâmetro tipado com objeto liberado), corrigido; nova rodada com 0 erros.
- `version/code` e `GameData.VERSAO_CODIGO` em 20; nome 1.8.5. MODO_TESTE e
  anúncios de teste mantidos (teste fechado).
- AAB: `Documentos\Sketch Blade - builds\sketchblade-1.8.5-vc20.aab`
  (69.153.071 bytes). ZIP íntegro; versão 1.8.5 no manifesto; `jar verified`,
  mesmo certificado de upload da 1.8.4; texturas e scripts novos presentes; sem
  store, referências, JPG/PSD, cena de ajuste ou texturas descartadas. Maiores
  arquivos: motor ARM64, três DEX, ícone e splash.
- SHA256: `c54c03356e5247b8c7b6b8b193f1b7e0868aa751095668cfdb476417009d5024`.
- Falta: envio à Play pelo Richard e teste no celular. Depois de publicada,
  anunciar 1.8.5 (20) no `atualizacao/versao.json` (push isolado) para quem
  ainda está em versão anterior à 1.8.3; a 1.8.4 detecta pela própria Play.

Notas sugeridas para a Play:

```text
<pt-BR>
• Escudo de Borracha redesenhado, com animação ao quebrar.
• Borrão Explosivo com explosão animada e alcance maior.
• Tinta Corrosiva mais forte, com vapor e bolhas.
• Dano da corrosão e da explosão com cores próprias.
• Avisos na tela com contorno, sem cobrir os monstros.
</pt-BR>
```


## Build 1.8.6 (21) — 06/11/2026
Ajustes depois da 1.8.5:
- Capítulo 10 vencido mostra o Estojo com o selo DERROTADO no hub e na última
  bolinha da trilha (o último capítulo não libera outro; marca própria no save,
  `SaveManager.capitulo_vencido`).
- Escudo de Borracha sem a faixa branca perto da ponta vermelha.
- Coração da última vida: gravação real CC0 (BigSoundBank *Heartbeat #1*),
  mesmo volume no fone e ~10 dB a mais no alto-falante do celular; vinheta no
  ritmo novo. Mistura real ouvida antes em https://claude.ai/artifact/H8hfV3XBanRAJt7Nr1Mo9k
- Vibração em mais momentos, com força por momento (`docs/vibracao.md`).
- Antes do build: testes de vida crítica, sons da partida, sons do resultado e
  feedback do combate (0 falhas); robô nos 10 chefes (esquiva, 1 semente): 0
  erros de script.
- `version/code` e `GameData.VERSAO_CODIGO` em 21; nome 1.8.6. MODO_TESTE e
  anúncios de teste mantidos (teste fechado).
- AAB: `Documentos\Sketch Blade - builds\sketchblade-1.8.6-vc21.aab`
  (69.166.880 bytes). ZIP íntegro; 1.8.6 no manifesto; `jar verified`, mesmo
  certificado de upload (SHA256 E2:28:70:F9…F7:1C); `Vibracao.gd` e coração novo
  presentes; sem store, referências, JPG/PSD ou `__pycache__`. Maiores
  arquivos: motor ARM64, três DEX, ícone e splash.
- SHA256: `58e91db5cb3c4bb055e9fb072ae585f469350d77739257b4ba81670351fe8f72`.
- Falta: envio à Play pelo Richard e teste no celular (vibração e coração só
  dão para conferir no aparelho).

Notas sugeridas para a Play:

```text
<pt-BR>
• Ao vencer o capítulo 10, o Estojo aparece com o selo de derrotado.
• Novo som de coração na última vida, bem mais audível no celular.
• Vibração em mais momentos: chefe, escudo, vitória, compras e mais.
• Escudo de Borracha com o desenho corrigido.
</pt-BR>
```


## Build 1.8.8 (23) — 12/11/2026
Começo mais fácil (feedback de teste: "caneta demora, monstros descem rápido"):
- Tiro guardado: o tiro que vencia com a caneta em movimento sai assim que ela para.
- Capítulos 1 e 2 com monstros 20% e 10% mais lentos; no 1, monstro comum
  morre em 2 tiros da caneta inicial. Efeito nos chefes em `docs/equilibrio-chefes.md`.
- Antes do build: import sem erros; robô nos 10 chefes (esquiva, chegada+roleta).
- `version/code` e `GameData.VERSAO_CODIGO` em 23; nome 1.8.8. MODO_TESTE e
  anúncios de teste mantidos (teste fechado).
- AAB: `Documentos\Sketch Bladeuilds\sketchblade-1.8.8-vc23.aab`
  (69.791.020 bytes). ZIP íntegro; 1.8.8 no manifesto; `jar verified`, mesmo
  certificado da 1.8.7; sem store, referências, JPG/PSD ou `__pycache__`.
  Maiores arquivos: motor ARM64, três DEX, ícone e splash.
- SHA256: `dd5aa950c4fb0abeb6a6e67afa328ab1b40234d4b11445fdf55b4cb51eb09e9d`.
- Falta: envio à Play pelo Richard e teste do capítulo 1 no celular.

Notas sugeridas para a Play:

```text
<pt-BR>
• Começo mais tranquilo: monstros mais lentos nos capítulos 1 e 2.
• A caneta atira assim que você para de se mexer.
</pt-BR>
```

## Build 1.8.7 (22) — 07/11/2026
Ajustes depois da 1.8.6:
- Música do hub (Suno, versão calma aprovada), também na tela antes da partida;
  desce no COMEÇAR (`docs/plano-musica-adaptativa.md`).
- Descanso: a música da partida acalma na hora, em 1 s; a virada "Página 4"
  passa antes do descanso abrir (antes ficava congelada e saía colada na
  "Página 5"); selo da lua na casa do descanso da trilha.
- Inimigo comum solta tinta azul (`ink-blue.svg`); roxo rápido mais claro e
  puxado para o lilás da gota.
- Antes do build: testes de música, sons da partida, sons do resultado, vida
  crítica e feedback do combate (0 falhas); abrir hub OK; robô nos 10 chefes
  (esquiva, 1 semente, chegada+roleta): 0 erros de script.
- `version/code` e `GameData.VERSAO_CODIGO` em 22; nome 1.8.7. MODO_TESTE e
  anúncios de teste mantidos (teste fechado).
- AAB: `Documentos\Sketch Blade - builds\sketchblade-1.8.7-vc22.aab`
  (69.790.647 bytes). ZIP íntegro; 1.8.7 no manifesto; `jar verified`, mesmo
  certificado de upload (SHA256 E2:28:70:F9…F7:1C); música do hub, selo do
  descanso e gota azul presentes, gota cinza fora; sem store, referências,
  JPG/PSD ou `__pycache__`. Maiores arquivos: motor ARM64, três DEX, ícone e splash.
- SHA256: `b3cde635bf683ae43f3f61ed2e38b3f8dd87806f850bca0cf27d573241137e3f`.
- Falta: envio à Play pelo Richard e escuta no celular (música do hub e do descanso).

Notas sugeridas para a Play:

```text
<pt-BR>
• Música nova no menu e na tela antes da partida.
• Página de descanso com música mais calma.
• A página 4 agora vira antes do descanso: nada de pular duas páginas.
• Símbolo de descanso na trilha de páginas.
• Monstro comum solta tinta azul e o roxo ficou mais claro.
</pt-BR>
```
