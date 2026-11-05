# Ajuste visual das miniaturas

1. Abra `ajuste_retratos.tscn` no Godot, na aba **2D**. Não precisa dar Play.
2. No painel **Cena**, expanda o chefe e selecione **Rosto** (Sprite2D).
3. Use **Mover** para arrastar o rosto. Use **Escalar** para o zoom, mantendo
   X e Y iguais. O Inspector → Transform → Scale também permite ajuste fino.
4. **Ctrl+S** salva todos os transforms na cena. Avise que terminou.

Mantenha os círculos/`ChefeNN` parados: ajuste só o filho **Rosto**, com rotação
zero. Uma escala maior aproxima a imagem; o excesso desaparece fora do círculo.
O círculo desta folha é ampliado para facilitar o ajuste; o jogo mantém seu
tamanho original. As artes originais não são alteradas.

O Codex lê a cena salva e transfere os enquadramentos para `Hub.ROSTOS_TRILHA`.
A cena não é lida pelo jogo e está excluída do export Android. Salvar esta cena
não muda as miniaturas do jogo até a transferência.

Leitura exata pelo Godot, sem gravar nada:

```powershell
& 'D:/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe' --headless --path . -s tools/ajuste_retratos/ler_recortes.gd
```

Se deformar o rosto sem querer, iguale Scale X/Y no Inspector; o leitor recusa
escala desigual, escala negativa e rotação para evitar resultado diferente do
que a tabela de recortes do jogo consegue representar.
