# Desafio do dia ("Prova surpresa")

Aprovado em 13/11/2026 (conselho de LLMs + visual A, prancheta). Página: https://claude.ai/artifact/CLaPTwznyGYyLuizVgxoZu

## Como funciona
- Uma regra por dia, igual para todos, sorteada pela data do aparelho (`GameData.desafio_do_dia`).
- Partida curta: 3 páginas + o chefe do capítulo selecionado no Hub; roleta depois das páginas 1 e 2; sem descanso.
- Tentativas à vontade. Só a 1ª vitória do dia (`desafio_vencido_data`) paga o prêmio e dá um visto na cartela (`desafio_vistos`); o 3º visto dá +5 clipes e zera a cartela.
- Não conta para recorde, desbloqueio de capítulo nem retomada de partida (sem snapshot).

## Regras da 1ª versão
| id | Nome | Efeito |
|---|---|---|
| vidro | Caneta de vidro | metade dos corações; toda tinta vale o triplo (1 coração só seria loteria no chefe: a bateria mostra 3 a 8 acertos por luta) |
| chuva | Chuva de borrões | borrões caem do alto a cada ~1,4 s |
| ricochete | Só ricochete | começa com Ricochete; Tiro Duplo e Leque fora da roleta |
| turbinado | Chefe turbinado | só o chefe, com +50% de vida; começa com 2 upgrades sorteados |

Depois, uma por atualização: Gigantes, Roleta maluca, Tinta que acaba.

## Arquivos
- Dados e sorteio: `GameData.gd` (DESAFIOS, DESAFIO_PAGINAS, prêmio). Save: `desafio_vencido_data`, `desafio_vistos`.
- Partida: `Main.gd` (`desafio`, `_configurar_desafio`), `WaveManager.gd` (`paginas`, `mult_vida_chefe`).
- Hub: entrada (bilhete abaixo da seta direita) e `JanelaDesafio.gd` (prova na prancheta).
- Peças: `assets/ui/desafio/` (originais em `Documentos\Sketch Blade\design\desafio-do-dia\gerados\`).

## Pendências
- **Relógio do celular:** o dia vem do relógio do aparelho; quem adianta o relógio pega o desafio de amanhã. Resolver antes da produção (ex.: hora da rede/Play, ou não aceitar data menor que a última vista).
- Medir: abriu / venceu / voltou no dia seguinte.
- Desligar regra remotamente (via `atualizacao/versao.json`) se uma regra sair quebrada.
- Prêmio passar pela simulação da economia (`tools/sim_economia.py`).
