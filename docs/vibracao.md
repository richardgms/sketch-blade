# Vibração

Tudo passa por `Vibracao.tocar(nome)` (`Vibracao.gd`), que respeita a chave
"Vibração" das Configurações e não faz nada fora do celular. Padrão = lista de
`[ms, força 0..1, pausa ms]`; a força só vale no Android 8+.

| Momento | Padrão | Onde |
|---|---|---|
| Batida do coração com 1 vida | 28 ms, 0,35 | `VidaCritica.gd` (volta do ciclo do som) |
| Dano | 100 ms, 1,0 (o de sempre) | `Main._on_player_dano` |
| Escudo de Borracha quebra | 45 + 25 ms | `Player.gd` |
| Elite derrotado | 40 ms, 0,55 | `WaveManager.gd` |
| Upgrade escolhido | 22 ms, 0,4 | `Main._aplicar_upgrade` |
| "JÁ!" da contagem | 45 ms, 0,6 | `Main` (contagem) |
| Chefe surge | 3 pulsos, o último longo | `WaveManager.gd` |
| Chefe derrotado | 240 ms forte + 2 ecos | `Main` |
| Reviver | 2 pulsos | `Main` |
| Vitória / derrota | 3 pulsos subindo / 320 ms, 0,6 | `Main` |
| Compra (loja, estojo, canetas) | 2 toques curtos | `Hub.gd` |
| Missão / recompensa diária coletada | 30 ms, 0,45 | `Hub.gd` |

Fora de propósito: morte de monstro comum, tiro, gota e chefe atacando
(frequentes demais; viraria zumbido constante). Testar só no celular (no PC é
silencioso). Criado em 06/11/2026; ajustes depois do teste no aparelho.
