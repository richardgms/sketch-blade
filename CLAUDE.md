# Sketch Blade

Jogo mobile (Android, retrato) em **Godot 4.7** (GL Compatibility), GDScript. Roguelite de caderno: caneta que atira tinta.

## Comandos
- Godot: `D:\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe` (rode pela linha de comando; o editor aberto reescreve `project.godot`).
- AAB de release: `timeout 540 ... --headless --path . --export-release "Android" "<saida>.aab"` (o Godot não fecha sozinho depois de gravar; confira o arquivo) (chave de upload em `Documentos\keys`, senha em `.godot/export_credentials.cfg`, fora do git).
- Prints da loja (1080x1920): `-s tools/capturar_prints.gd -- <pasta> [LxA]` — faça backup do save do PC antes.
- Imagem nova em `assets/` ou script novo: rode `--headless --path . --import` antes dos prints e do commit (sem isso `ResourceLoader.exists` dá falso e o `.uid` não existe).
- Economia: `python tools/sim_economia.py`.
- Música adaptativa: `Musica.gd` (chave `ATIVA`, volume `VOLUME_DB`); teste sem tela `--headless --path . -s tools/teste_musica.gd`; camadas refeitas por `tools/musica/` (ver `docs/plano-musica-adaptativa.md`).
- Equilíbrio dos chefes (robô joga sem tela): ver `docs/equilibrio-chefes.md`.
- Prints das telas: `bash tools/capturar_telas.sh <pasta> <telas>` (faz backup e restaura o save do PC; flags de autoload passam de uma partida de teste para a outra). Se o Godot de teste travar, encerre só esse processo pelo PID (`Get-CimInstance Win32_Process`): o editor aberto também se chama Godot.
- Imagens geradas no ChatGPT: original em `Documentos\Sketch Blade - design\<tela>\gerados\`, versão de uso em `assets/ui/`.
- Ouvir a mistura real de uma luta antes do build (música, tiros, dano, vida crítica, vitória): `tools/gravar_ambiente.gd` com `--write-movie <saida.avi> --fixed-fps 60 --resolution 540x960` (instruções no topo do script; backup do save). Página de escuta: https://claude.ai/artifact/H8hfV3XBanRAJt7Nr1Mo9k
- Ouvir a música do hub no jogo (hub → antes da partida → COMEÇAR): `tools/gravar_hub.gd`, mesmo uso do `gravar_ambiente` (aceita um .ogg alternativo). Página de escuta: https://claude.ai/artifact/KDHR8YQvfu54BmRo2CfXeG
- Testar chefe no jogo: Configurações → Stats de teste → "Testar chefe" / "Zerar Estojo" (só com `GameData.MODO_TESTE`). Teste por script: ver `docs/chefes.md`.

## Regras que importam
- **Nenhum arquivo que não seja do jogo dentro desta pasta** (fotos, PSD, prints de cliente): o export leva tudo para o APK/AAB. Antes de enviar um build, listar os maiores arquivos do AAB.
- Rascunhos e referências do jogo vão em `referencias/` (tem `.gdignore`: o Godot não importa nem exporta).
- Subir o `version/code` em `export_presets.cfg` **e** `GameData.VERSAO_CODIGO` a cada envio para a Play Store; desde a 1.8.3, a Play detecta atualização automaticamente (`docs/plano-atualizacao-play.md`). Depois da publicação, `atualizacao/versao.json` serve para novidades e compatibilidade com versões antigas; não controla a detecção nas novas.
- Compras: `BillingManager.gd` (simulado fora do Android). Anúncios: `AdsManager.gd` + plugin `addons/admob` (poing-studios 5.1.0; simulado fora do Android; `USAR_BLOCOS_TESTE = true` até a produção).
- Push que envolva pagamento ou anúncios: perguntar antes.

## Documentação
- Publicação e histórico: `docs/plano-publicacao.md` · Compras: `docs/plano-compras.md` · Loja: `docs/ficha-da-loja.md` · Chefes e combate: `docs/chefes.md` · Sons (fontes e licenças): `docs/sons.md` · Música adaptativa (plano): `docs/plano-musica-adaptativa.md` · Próximas melhorias: `docs/proximas-melhorias.md` · **Próximo chat (prompt pronto + lições técnicas): `docs/prompt-proximo-chat.md`** · **Identidade visual (ler antes de qualquer tela nova): `docs/identidade-visual.md`**
- Página de acompanhamento: https://claude.ai/artifact/XvFoxxh9Kpb1AynTtDaumW · Melhorias visuais: https://claude.ai/artifact/VdK88T7PA2HgKCCBubEKrg · Sons: https://claude.ai/artifact/YUAvgQ6UbbRQ3YMqvN3db4 · Estojo novo (aprovado; página própria porque a "Melhorias visuais" não abre no perfil do Orca): https://claude.ai/artifact/8RoURc1XDar9rXL972U5ed · Loja nova (aprovada): https://claude.ai/artifact/U8gtN7USeJXuhRPTYZkY4w · Missões novas (aprovadas): https://claude.ai/artifact/Ga1oRGb4hLwngFmQLG7KSV · Recompensa diária nova (aprovada): https://claude.ai/artifact/KsrLfzbfumyddBcoJtpHi2 · Configurações novas (aprovadas): https://claude.ai/artifact/Rev44ka2wMKjG8ydbH6yZv · Tela antes da partida (aprovada): https://claude.ai/artifact/P5d5Y8fUvVUnA5pZXEAjuS · Virada de página (aprovada): https://claude.ai/artifact/FjrLcpv9sK6LVmkUFGm4z4 · Mancha de tinta na morte (aprovada): https://claude.ai/artifact/1YsGSJ4dCq3pzJfSj34V9B · Fundo da página (aprovado): https://claude.ai/artifact/Jo7YDiYsHRTHkM8VfjV6ZR · Linha-limite da caneta (aprovada): https://claude.ai/artifact/N18sdy3TAhfTsoFQHf5rzf · Aviso de atualização (aprovado): https://claude.ai/artifact/DW93hYy2bsenc71zB8oLHP · Upgrades novos (aprovados, build 1.8.5; plano e método de folha de quadros em `docs/plano-upgrades.md`): https://claude.ai/artifact/TJVaMr4MGn6EGpBcQjzUyZ
