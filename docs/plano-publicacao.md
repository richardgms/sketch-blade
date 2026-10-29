# Plano de publicação — Sketch Blade (Play Store)

Atualizado em 2026-10-24. Fonte única do plano; marque cada item ao concluir.

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

## Decisões em aberto
- Confirmar o nome na loja (Tinta & Papel ou Roguelite).
- Quem serão os 12 testadores (precisam de Android e conta Google).
- Compra falsa: remover botões ou implementar Play Billing.

## Histórico
- 2026-10-24: investigação feita, plano criado.

## Chefes e combate
Fonte única: `docs/chefes.md` (regras de design, situação de cada chefe, arquitetura, como testar). Versão 1.4.0 (código 7) gerada em 28/10 com chefes 2, 3 e 5. Depois dela: os 10 chefes prontos e calibrados (`docs/equilibrio-chefes.md`), sinal de raiva e contador de vitórias/derrotas por capítulo no painel "Stats de teste" (o atalho "Testar chefe" não conta). **Build 1.5.0 (código 8) gerado em 28/10**: `Documentos\Sketch Blade - builds\sketchblade-1.5.0-vc8.aab` (58,7 MB). Conferido: assinado, 10 chefes, sem fotos; maiores arquivos = motor, código Android, ícone, splash e música. Ainda com `MODO_TESTE = true` e anúncios de teste. **Enviado ao Teste fechado em 29/10.** Falta: jogar no celular e mandar print do "Stats de teste".
