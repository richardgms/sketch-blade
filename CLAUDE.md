# Sketch Blade

Jogo mobile (Android, retrato) em **Godot 4.7** (GL Compatibility), GDScript. Roguelite de caderno: caneta que atira tinta.

## Comandos
- Godot: `D:\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe` (rode pela linha de comando; o editor aberto reescreve `project.godot`).
- AAB de release: `--headless --path . --export-release "Android" "<saida>.aab"` (chave de upload em `Documentos\keys`, senha em `.godot/export_credentials.cfg`, fora do git).
- Prints da loja (1080x1920): `-s tools/capturar_prints.gd -- <pasta> [LxA]` — faça backup do save do PC antes.
- Economia: `python tools/sim_economia.py`.

## Regras que importam
- **Nenhum arquivo que não seja do jogo dentro desta pasta** (fotos, PSD, prints de cliente): o export leva tudo para o APK/AAB. Antes de enviar um build, listar os maiores arquivos do AAB.
- Subir o `version/code` em `export_presets.cfg` a cada envio para a Play Store.
- Compras: `BillingManager.gd` (simulado fora do Android). Anúncios: `AdsManager.gd` (`MODO_MOCK`).
- Push que envolva pagamento ou anúncios: perguntar antes.

## Documentação
- Publicação e histórico: `docs/plano-publicacao.md` · Compras: `docs/plano-compras.md` · Loja: `docs/ficha-da-loja.md`
- Página de acompanhamento: https://claude.ai/artifact/XvFoxxh9Kpb1AynTtDaumW
