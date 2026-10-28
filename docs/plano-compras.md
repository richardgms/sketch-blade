# Plano — compras reais (Google Play Billing)

Criado em 2026-10-25. Decisão do Richard: implementar compra real em vez de esconder os botões.
Contexto: os botões "comprar tinta/clipes" do Hub (`Hub.gd`, `_on_confirmar_compra_pressed`) entregam o item de graça. A Play Store não aceita; precisa virar compra real.

## Investigação
- Plugin oficial: **godot-sdk-integrations/godot-google-play-billing**, última versão **3.3.0** (27/07/2026), arquivo `godot-google-play-billing.zip` (menos de 1 MB). Exige Godot 4.2+ (o projeto usa 4.7) e build Android por Gradle (o preset já usa).
- Fluxo da API: conectar → `query_product_details` → comprar → `consume_purchase` (consumível; já confirma a compra) → só então entregar o item. Se a compra não for confirmada em 3 dias, o Google reembolsa.
- Itens do jogo: 100 Clipes de Ouro e 5.000 Gotas de Tinta, ambos R$ 4,90 hoje. Ambos consumíveis (podem ser comprados várias vezes).
- O jogo já tem `AdsManager.gd` com modo simulado no PC; `BillingManager.gd` seguirá o mesmo padrão (simulado no PC, real no Android).

## Etapas
1. **Play Console (Richard):** conferir perfil de pagamentos / conta de comerciante (necessário para vender) e criar 2 produtos no app, consumíveis. IDs sugeridos: `clipes_100` e `tinta_5000`; preço a confirmar. Possível exigência de já haver um build com permissão de cobrança enviado antes de criar produtos (conferir no painel).
2. **Plugin (Claude):** baixar o release 3.3.0 do GitHub (pede ok do Richard), instalar em `addons/`, ativar e marcar no preset Android.
3. **Código (Claude):** `BillingManager.gd` (autoload): conecta, busca preços reais, compra, consome e só então entrega o item. Retoma compras pendentes ao abrir o jogo. Hub passa a chamar o BillingManager e mostra o preço vindo da loja. Modo simulado no PC.
4. **Build:** AAB com a permissão de cobrança, para o teste fechado.
5. **Teste (Richard):** cadastrar o próprio e-mail como testador de licença no Play Console, instalar pela faixa de teste e comprar de verdade (sem cobrança de testador).
6. **Políticas:** atualizar Segurança dos dados e política de privacidade se a cobrança mudar as respostas.

## Andamento do Play Console (25/10/2026)
- Perfil de comerciante criado. Conta bancária adicionada; falta confirmar o depósito de teste (até R$ 0,35, em até 3 dias).
- Grupo de contas "RichardGms" criado (pré-requisito da taxa de 15%). O botão para aceitar os termos da taxa ainda não apareceu no Perfil para pagamentos; rever depois de recarregar a página.
- Contatos: política de privacidade já usa richardgomes.dev@gmail.com. Falta trocar o e-mail da conta de desenvolvedor (Gerenciar conta → Detalhes da conta) e o do app.
- Plugin de cobrança 3.3.0 instalado em `addons/GodotGooglePlayBilling` e ativo no `project.godot`. `BillingManager.gd` (autoload) pronto: simulado no PC, real no Android, entrega só após confirmação, uma vez por token (guardado em `compras_tokens` no save), consome a compra depois. Hub usa o preço vindo da loja. Testado no modo simulado (entrega, token duplicado, compra pendente).
- Build Android conferido: permissão `com.android.vending.BILLING` e classes do plugin presentes.
- AAB de release assinado (chave de upload) gerado: `Documentos\Sketch Blade - builds\sketchblade-1.0-vc1.aab` (191 MB), versão 1 / "1.0". Ainda com anúncios simulados (`MODO_MOCK`).
- Descoberta no painel: a página Monetizar leva ao Painel enquanto não há versão enviada. Ordem real: enviar o AAB (Teste interno) → criar produtos → testar compra com testador de licença.
- Commits locais feitos; push pendente (envolve pagamento, aguardando ok do Richard).

## Produtos criados (28/10/2026)
- Depósito de teste confirmado pelo Richard.
- `clipes_100` e `tinta_5000` criados e **ativos** em Produtos únicos: opção de compra `compra` (tipo Comprar, "Compatível com versões anteriores", que é a usada pelo plugin), 174 países, Brasil R$ 4,90. O preço em massa vira R$ 4,89 no Brasil por arredondamento; foi corrigido à mão.
- Teste de licença (Gerenciar conta → Teste de licença): marcar a lista `Interno` e salvar. Isso afeta todos os apps da conta. Depois: instalar pela faixa de teste e fazer uma compra de teste.

## Decisões em aberto
- Ordem: fazer a cobrança antes do primeiro AAB do teste fechado, ou subir o AAB antes e entregar a cobrança como atualização durante os 14 dias.
- Preços finais dos dois produtos.
