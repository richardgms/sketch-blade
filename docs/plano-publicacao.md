# Plano de publicação — Sketch Blade (Play Store)

Atualizado em 2026-10-24. Fonte única do plano; marque cada item ao concluir.

## Estado encontrado (investigação)
| Item | Estado |
|---|---|
| Pacote | `com.richardgms.sketchblade`, versão 1 / "1.0", só arm64 |
| Build de teste (APK debug) | Gerado e instalado no celular em 24/10/2026 |
| Preset de release (AAB) | Pronto, mas **sem keystore de release** (só a de debug do Godot) |
| Plugin AdMob | **Não instalado**. `AdsManager.gd` está em `MODO_MOCK = true` com IDs de teste |
| Código do AdMob real | Escrito de memória (`Engine.get_singleton("AdMob")`); precisa ser conferido contra a API real do plugin |
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

## Decisões em aberto
- Confirmar o nome na loja (Tinta & Papel ou Roguelite).
- Quem serão os 12 testadores (precisam de Android e conta Google).
- Compra falsa: remover botões ou implementar Play Billing.

## Histórico
- 2026-10-24: investigação feita, plano criado.
