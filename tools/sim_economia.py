# -*- coding: utf-8 -*-
"""
Simulador de progressão econômica do Sketch Blade.

Lê as curvas data-driven direto de GameData.gd (custos do Estojo, dano/HP/
cadência por nível, receita das páginas). Valores que vivem em código (HP dos
inimigos, drops de tinta, fórmulas de escala por capítulo) são espelhados aqui
com citação de arquivo:linha — se mudar lá, atualize aqui.

Uso:  python tools/sim_economia.py [--runs N] [--uptime F]

Roda dois cenários lado a lado:
  ATUAL    — curvas exatamente como estão no jogo
  PROPOSTA — recalibração alvo (arco de ~30 vitórias / ~1 semana)
"""

import argparse
import math
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")  # console Windows padrão é cp1252

RAIZ = Path(__file__).resolve().parent.parent
GAMEDATA = RAIZ / "GameData.gd"

# ============================================================
# Valores espelhados do código (não são data-driven no projeto)
# ============================================================
HP_BASE = {"COMUM": 20, "NANQUIM": 10, "RESPINGO": 20, "GUACHE": 50}  # Enemy.gd:51-73
DROPS_KILL = (2, 4)                    # Main.gd:300  — 2 gotas × 4 tinta por kill
DROPS_BOSS = (10, 8)                   # Main.gd:689  — 10 gotas × 8
DROPS_ELITE_EXTRA = (6, 8)             # WaveManager.gd:132 — jackpot do elite
BONUS_VIDA_PCT = 0.10                  # Main.gd:732 — +10% por vida restante (só vitória)
DANO_CONTATO_BOSS = 2                  # Boss.gd:9 (3 a partir do cap 6, WaveManager.gd:254)


@dataclass
class Cenario:
    """Um conjunto de curvas econômicas/combate a simular.
    Os defaults espelham o JOGO ATUAL (pós-recalibração de jul/2026)."""
    nome: str
    # None = usa o CUSTOS_ESTOJO lido do GameData.gd
    custos: list | None = None
    # Renda: multiplicador por capítulo acima do 1 (Main.gd:739)
    bonus_cap_mult: float = 0.10
    # Escala de HP dos inimigos: ("linear", a) → 1+(c-1)*a  |  ("geo", b) → b^(c-1)
    hp_escala: tuple = ("geo", 1.28)             # WaveManager.gd (mult_hp)
    boss_hp_base: int = 300                      # Boss.gd
    boss_escala: tuple = ("geo", 1.26)           # WaveManager.gd (_preparar_boss)
    # Tinta do descanso e da página perfeita: valor = base + por_cap × capítulo
    descanso: tuple = (40, 20)                   # GameData.tinta_descanso
    perfeita: tuple = (10, 5)                    # GameData.bonus_pagina_perfeita
    # Renda média de missões diárias/streak amortizada por run (igual nos 2 cenários)
    renda_extra_run: int = 40
    # Heurística: boss acerta o jogador a cada N segundos de luta
    boss_hit_intervalo: float = 18.0


def parse_gamedata(texto: str) -> dict:
    """Extrai as constantes data-driven do GameData.gd."""
    dados = {}

    def array_num(nome):
        m = re.search(rf"const {nome}: Array = \[(.*?)\]", texto, re.S)
        if not m:
            sys.exit(f"ERRO: não achei {nome} em GameData.gd")
        return [float(x) if "." in x else int(x)
                for x in re.findall(r"-?\d+\.?\d*", m.group(1))]

    def escalar(nome, cast=float):
        m = re.search(rf"const {nome}:\s*\w+\s*=\s*([\d.]+)", texto)
        if not m:
            sys.exit(f"ERRO: não achei {nome} em GameData.gd")
        return cast(m.group(1))

    dados["custos"] = array_num("CUSTOS_ESTOJO")
    dados["dano"] = array_num("DANO_POR_NIVEL")
    dados["hp"] = array_num("HP_POR_NIVEL")
    dados["cadencia"] = array_num("CADENCIA_POR_NIVEL")
    dados["nivel_max"] = int(escalar("NIVEL_MAX_ESTOJO"))
    dados["elite_mult_hp"] = escalar("ELITE_MULT_HP")

    m = re.search(r"const PAGINAS: Array = \[(.*?)\n\]", texto, re.S)
    if not m:
        sys.exit("ERRO: não achei PAGINAS em GameData.gd")
    paginas = []
    for linha in m.group(1).splitlines():
        if '"tipo"' not in linha:
            continue
        pag = {"tipo": re.search(r'"tipo":\s*"(\w+)"', linha).group(1)}
        for chave in ("quantidade", "intervalo", "intensidade"):
            km = re.search(rf'"{chave}":\s*([\d.]+)', linha)
            if km:
                v = km.group(1)
                pag[chave] = float(v) if "." in v else int(v)
        pag["elite"] = '"elite": true' in linha
        paginas.append(pag)
    dados["paginas"] = paginas
    return dados


def escala(cap: int, modo: tuple) -> float:
    tipo, valor = modo
    return 1.0 + (cap - 1) * valor if tipo == "linear" else valor ** (cap - 1)


# ============================================================
# Distribuição de inimigos — espelho analítico de
# WaveManager._sortear_tipo_inimigo (WaveManager.gd:144)
# Retorna HP base ESPERADO (média ponderada pelas chances).
# ============================================================
def hp_base_esperado(cap: int, pagina: int) -> float:
    C, N, R, G = HP_BASE["COMUM"], HP_BASE["NANQUIM"], HP_BASE["RESPINGO"], HP_BASE["GUACHE"]
    fase = 3 if pagina >= 7 else (2 if pagina >= 5 else 1)

    if cap == 1:
        return 0.2 * N + 0.8 * C if fase == 3 else C
    if cap in (2, 3):
        p = 0.2 + 0.15 * (fase - 1)
        return p * N + (1 - p) * C
    if cap in (4, 5):
        if fase == 1:
            return 0.3 * N + 0.7 * C
        if fase == 2:
            return 0.4 * R + 0.6 * C
        return 0.3 * N + 0.3 * R + 0.4 * C
    if cap in (6, 7):
        if fase == 1:
            return 0.3 * N + 0.2 * R + 0.5 * C
        if fase == 2:
            return 0.5 * R + 0.5 * C
        return 0.4 * G + 0.3 * N + 0.3 * C
    if fase == 1:
        return 0.3 * N + 0.3 * R + 0.4 * C
    if fase == 2:
        return 0.4 * R + 0.3 * G + 0.3 * C
    return 0.3 * G + 0.3 * N + 0.2 * R + 0.2 * C


# ============================================================
# Bot ganancioso: joga o capítulo mais alto desbloqueado e,
# entre runs, compra sempre o upgrade mais barato disponível.
# ============================================================
def simular(gd: dict, cen: Cenario, uptime: float, max_runs: int):
    custos = cen.custos if cen.custos else gd["custos"]
    nmax = gd["nivel_max"]
    dano_nv, cad_nv = gd["dano"], gd["cadencia"]

    def tiros(hp_alvo, nvd):
        return max(1, math.ceil(hp_alvo / dano_nv[nvd]))

    def ttk(hp_alvo, nvd, nvc):
        return tiros(hp_alvo, nvd) * cad_nv[nvc] / uptime

    nv = {"dano": 1, "hp": 1, "cad": 1}
    tinta_banco = 0
    cap_desbloq = 1
    linhas, achados = [], {}
    gasto_total = 0

    for run in range(1, max_runs + 1):
        cap = cap_desbloq
        tinta_run = float(cen.renda_extra_run)
        hits = 0.0
        vidas = gd["hp"][nv["hp"]]
        derrota_na_pag = None
        dur = 0.0

        for i, pag in enumerate(gd["paginas"], start=1):
            if pag["tipo"] == "descanso":
                if hits < vidas * 0.4:
                    tinta_run += cen.descanso[0] + cen.descanso[1] * cap
                else:
                    hits = max(0.0, hits - 2)  # cura 2 corações
                continue

            if pag["tipo"] == "boss":
                hp_boss = cen.boss_hp_base * escala(cap, cen.boss_escala)
                ttk_boss = ttk(hp_boss, nv["dano"], nv["cad"])
                dur += ttk_boss + 2.5
                dano_boss = 3 if cap >= 6 else DANO_CONTATO_BOSS
                hits_boss = (ttk_boss / cen.boss_hit_intervalo) * dano_boss
                hits += hits_boss
                if hits >= vidas:
                    derrota_na_pag = i
                    break
                if hits_boss < 0.5:
                    tinta_run += cen.perfeita[0] + cen.perfeita[1] * cap
                tinta_run += DROPS_BOSS[0] * DROPS_BOSS[1]
                continue

            hp_alvo = hp_base_esperado(cap, i) * escala(cap, cen.hp_escala) * pag["intensidade"]
            ttk_um = ttk(hp_alvo, nv["dano"], nv["cad"])
            qtd = pag["quantidade"]
            dur += 1.2 + max(qtd * pag["intervalo"], qtd * ttk_um)

            # Pressão: se mata mais devagar do que nasce, acumula fila → dano
            pressao = ttk_um / pag["intervalo"]
            hits_pag = max(0.0, (pressao - 1.0) * qtd * 0.35)

            tinta_run += qtd * DROPS_KILL[0] * DROPS_KILL[1]
            if pag["elite"]:
                hp_elite = hp_alvo * gd["elite_mult_hp"]
                ttk_elite = ttk(hp_elite, nv["dano"], nv["cad"])
                dur += ttk_elite
                hits_pag += max(0.0, (ttk_elite / 10.0) - 0.5)
                tinta_run += (DROPS_KILL[0] * DROPS_KILL[1]
                              + DROPS_ELITE_EXTRA[0] * DROPS_ELITE_EXTRA[1])

            hits += hits_pag
            if hits >= vidas:
                derrota_na_pag = i
                break
            if hits_pag < 0.5:
                tinta_run += cen.perfeita[0] + cen.perfeita[1] * cap

        venceu = derrota_na_pag is None
        if venceu:
            vidas_rest = max(0, math.floor(vidas - hits))
            tinta_run *= 1.0 + vidas_rest * BONUS_VIDA_PCT
        tinta_run *= 1.0 + (cap - 1) * cen.bonus_cap_mult
        tinta_banco += int(tinta_run)

        hp_comum = HP_BASE["COMUM"] * escala(cap, cen.hp_escala)
        tiros_comum = tiros(hp_comum, nv["dano"])
        ttk_boss_atual = ttk(cen.boss_hp_base * escala(cap, cen.boss_escala),
                             nv["dano"], nv["cad"])

        linhas.append({
            "run": run, "cap": cap, "venceu": venceu, "pag_morte": derrota_na_pag,
            "nv": dict(nv), "tinta": int(tinta_run), "banco": tinta_banco,
            "tiros_comum": tiros_comum, "ttk_boss": ttk_boss_atual, "dur": dur,
        })

        if tiros_comum == 1 and "hitkill" not in achados:
            achados["hitkill"] = (run, cap)
        if ttk_boss_atual < 12 and "boss_trivial" not in achados:
            achados["boss_trivial"] = (run, cap, ttk_boss_atual)

        if venceu and cap_desbloq < 10:
            cap_desbloq += 1

        while True:
            opcoes = [(custos[nv[k] - 1], k) for k in nv if nv[k] < nmax]
            if not opcoes:
                break
            custo, chave = min(opcoes)
            if tinta_banco < custo:
                break
            tinta_banco -= custo
            gasto_total += custo
            nv[chave] += 1

        if all(nv[k] >= nmax for k in nv) and "estojo_max" not in achados:
            achados["estojo_max"] = run
        if venceu and cap == 10 and "cap10" not in achados:
            achados["cap10"] = run
        if "cap10" in achados and "estojo_max" in achados:
            break

    return linhas, achados, gasto_total, custos


# ============================================================
# Saída
# ============================================================
def tabela_a(gd: dict, cen: Cenario):
    print(f"\nTABELA A [{cen.nome}] — tiros p/ matar 1 COMUM (pág. 3, intens. 1.0)")
    print("           capítulo →")
    print("Dano nv   " + "".join(f"{c:>5}" for c in range(1, 11)))
    for nvd in range(1, gd["nivel_max"] + 1):
        linha = f"  {nvd:>2} ({gd['dano'][nvd]:>2}) "
        for cap in range(1, 11):
            hp = HP_BASE["COMUM"] * escala(cap, cen.hp_escala)
            linha += f"{max(1, math.ceil(hp / gd['dano'][nvd])):>5}"
        print(linha)


def tabela_b(linhas, cen: Cenario):
    print(f"\nTABELA B [{cen.nome}] — bot ganancioso, run a run")
    print(f"{'run':>4} {'cap':>4} {'result':>10} {'D/H/C':>9} {'tiros':>6} "
          f"{'boss(s)':>8} {'tinta':>7} {'banco':>7}")
    for l in linhas:
        res = "VITÓRIA" if l["venceu"] else f"morreu p{l['pag_morte']}"
        nvs = f"{l['nv']['dano']}/{l['nv']['hp']}/{l['nv']['cad']}"
        print(f"{l['run']:>4} {l['cap']:>4} {res:>10} {nvs:>9} {l['tiros_comum']:>6} "
              f"{l['ttk_boss']:>8.1f} {l['tinta']:>7} {l['banco']:>7}")


def resumo(nome, linhas, achados, gasto, custos):
    total_sink = sum(custos) * 3
    print(f"\nACHADOS [{nome}]  (sink Estojo total: {total_sink})")
    if "hitkill" in achados:
        r, c = achados["hitkill"]
        print(f"  • HITKILL no comum a partir da run {r} (capítulo {c})")
    if "boss_trivial" in achados:
        r, c, t = achados["boss_trivial"]
        print(f"  • Boss trivial (<12s) na run {r} (cap {c}, {t:.0f}s)")
    print(f"  • Cap 10 vencido: run {achados.get('cap10', '— (não venceu)')}")
    print(f"  • Estojo maxado: run {achados.get('estojo_max', '— (não maxou)')}")
    ultimo = linhas[-1]
    print(f"  • Fim da simulação: run {ultimo['run']}, banco ocioso = {ultimo['banco']}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--runs", type=int, default=60)
    ap.add_argument("--uptime", type=float, default=0.65,
                    help="fração do tempo atirando (parado). Padrão 0.65")
    args = ap.parse_args()

    gd = parse_gamedata(GAMEDATA.read_text(encoding="utf-8"))

    cenarios = [
        # Curvas de antes da recalibração de jul/2026, para comparação
        Cenario(
            nome="LEGADO",
            custos=[50, 85, 145, 245, 420, 715, 1215, 2065, 3510],
            bonus_cap_mult=0.50,
            hp_escala=("linear", 0.40),
            boss_hp_base=100,
            boss_escala=("linear", 0.50),
            descanso=(0, 80),
            perfeita=(0, 15),
        ),
        Cenario(nome="ATUAL"),  # defaults = jogo como está no código
    ]

    print("=" * 70)
    print("SIMULADOR DE ECONOMIA — Sketch Blade")
    print(f"Uptime de tiro assumido: {args.uptime:.0%} "
          "(DPS e tinta são exatos; sobrevivência é heurística;")
    print(" upgrades roguelite in-run NÃO modelados → jogo real é mais fácil)")
    print("=" * 70)

    for cen in cenarios:
        tabela_a(gd, cen)
        linhas, achados, gasto, custos = simular(gd, cen, args.uptime, args.runs)
        tabela_b(linhas, cen)
        resumo(cen.nome, linhas, achados, gasto, custos)


if __name__ == "__main__":
    main()
