# 📓 Sketch Blade — Archero de Caderno

**Sketch Blade** é um jogo mobile de ação/roguelite vertical (portrait) desenvolvido na engine **Godot 4.x**, ambientado inteiramente dentro de páginas de um caderno escolar desenhado à mão. O jogador controla uma Caneta esferográfica que atira projéteis de tinta contra monstros rabiscados de canetinha que caem do topo da folha.

---

## 🎨 Identidade Visual e Estética
O jogo se destaca pelo visual analógico e procedural:
*   **Papel Dinâmico (`Paper.gd`):** O fundo se transforma conforme o capítulo (páginas pautadas de redação, quadriculado de matemática, folhas kraft beges de agenda e papel milimetrado de desenho técnico no capítulo final).
*   **Traços de Caneta:** Toda a interface do usuário (UI), setas de navegação, ícones do rodapé, moedas de tinta e inimigos utilizam assets retina desenhados à mão com contornos azuis BIC e grafite.
*   **Design Orgânico de UI:** A aba ativa no menu inferior é indicada por um risco rabiscado duplo azul BIC (`risco.png`) e opacidade total, sem colchetes de texto para manter o minimalismo elegante.

---

## 🛠️ Stack Técnica e Arquitetura

O projeto é modular e de alta performance, utilizando as melhores práticas do Godot 4:
*   **`Hub.gd` / `hub.tscn`:** Gerenciador do menu principal. Controla a economia de tinta, o salvamento persistente, upgrades RPG (Dano, Vida e Cadência) e navegação entre capítulos por setas laterais.
*   **`Main.gd` / `main.tscn`:** Loop principal de combate. Gerencia as fases de spawn, HP do jogador, barra de tinta e transições de Game Over / Vitória.
*   **`WaveManager.gd`:** Controla as ondas de monstros comuns e o surgimento do Chefe no final da página, aplicando multiplicadores progressivos de HP e velocidade por capítulo.
*   **`Paper.gd`:** Renderizador procedural baseado em canvas 2D para desenhar pautas, grids quadriculados e linhas tracejadas limites de movimento em tempo real.
*   **`Enemy.gd`:** Concentra os comportamentos de IA e aparências dos 4 inimigos (Comum, Nanquim Rápido, Respingo Senoidal e Guache Tanque).
*   **`PaperSave`:** Sistema baseado em JSON (`user://save_data.json`) que persiste a tinta coletada, nível do jogador, XP e níveis de upgrades da caneta.

---

## 💎 Configuração de Nitidez para Assets Retina (Mipmaps)
Para que os ícones desenhados à mão fiquem nítidos e suaves (sem serrilhado de redução) em qualquer resolução de celular, siga os passos no editor da Godot:
1. No painel **FileSystem**, selecione as imagens em `res://assets/images/` (`icon_estojo.png`, `icon_lutar.png`, `icon_loja.png`, `risco.png`, `arrow_left.png`, `arrow_right.png`).
2. No painel superior esquerdo, abra a aba **Import**.
3. Altere o campo **`Mipmaps / Generate`** para **`On`**.
4. Altere o campo **`Limite`** (Limit) para **`-1`**.
5. Clique no botão **`Reimport`**.

*Nota: Todos os nós de textura do menu inferior já utilizam a propriedade `texture_filter = 4` (Linear com Mipmaps) para garantir renderização cristalina.*

---

## 📱 Controles e Gameplay
*   **Movimento:** Toque e arraste o dedo (ou mouse) em qualquer lugar da tela para mover a caneta.
*   **Mecânica Move-and-Shoot:** A caneta dispara automaticamente projéteis de tinta contra o inimigo mais próximo, mas **somente quando estiver parada**. Para desviar de ataques, o jogador precisa se mover, pausando os disparos temporariamente.
*   **Barreira Física:** O jogador não pode mover a caneta acima da linha limite tracejada (Y = 1440).

---

## 📦 Como Buildar e Exportar para Android
Para gerar o arquivo APK do jogo:
1. Garanta que o **Android SDK** e o **JDK 17** estejam instalados e configurados nas preferências do Godot em `Editor -> Editor Settings -> Export -> Android`.
2. Configure as keystores de debug e release.
3. No menu principal da Godot, vá em `Project -> Export`.
4. Adicione um preset para **Android**.
5. Em **Options**, garanta que o formato de renderização esteja como `Mobile` (Vulkan) ou `Compatibility` (OpenGL 3) dependendo do público-alvo.
6. Clique em **Export Project** para gerar o arquivo `.apk`.
