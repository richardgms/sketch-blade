# Clareza da trilha e feedback de combate — 04/11/2026

Pedido: começo das fases audível sem filtro abafado, vida baixa perceptível,
raiva do chefe clara, dano junto do chefe e clique junto do zíper no Estojo.

Etapas: ajustar ganhos das faixas originais; integrar arte com alfa nas bordas;
reposicionar dano e reforçar raiva; somar clique ao zíper; importar e testar.

Arte: imagegen nativo, sem API externa. Prompt: overlay retrato 9:16 de vida
baixa, vinheta de tinta vermelha #c62828 e fissuras finas nos cantos, centro
transparente, sem texto, sangue ou fundo; preservar resolução e canal alfa.
Arquivo de uso: `assets/ui/vida_baixa_vinheta.png`.

Concluído: importação, testes de música e 13 verificações de combate/hub,
zero falhas. Execução OpenGL também terminou normalmente. Save restaurado
com hash idêntico. Escuta subjetiva no celular pendente.

Aprendizado: Godot 4.7 caiu com sinal 11 após falhar ao abrir logs no sandbox;
reexecução autorizada com log explícito terminou sem crash. A execução headless
reportou recursos residuais ao encerrar; a execução OpenGL não reportou esses erros.

Detalhes vigentes por assunto: `plano-musica-adaptativa.md`, `sons.md`, `chefes.md`.
Original arquivado fora do repo, sem redimensionamento nem recompressão.
