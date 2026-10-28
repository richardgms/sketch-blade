import json, sys, statistics as st
from pathlib import Path
sys.stdout.reconfigure(encoding="utf-8")
pasta = Path(sys.argv[1])
rs = []
for b in ["esquiva", "segue", "parado"]:
    f = pasta / f"{b}.jsonl"
    if f.exists():
        rs += [json.loads(l) for l in f.read_text(encoding="utf-8").splitlines() if l.strip()]
NOMES = {1: "Borrão", 2: "Avião", 3: "Mancha", 4: "Grade", 5: "Compasso", 6: "Pirata",
         7: "Tsuru", 8: "Fantasma", 9: "Pena", 10: "Estojo"}

def g(cen, cap, bot):
    return [r for r in rs if r["cen"] == cen and r["cap"] == cap and r["bot"] == bot]

for cen in ["zerado", "progressao"]:
    print(f"\n=== {cen.upper()} ===")
    print("cap chefe     vida  D/int  | ESQUIVA: tempo  mortes  dano/vidas  aprov | SEGUE dano | PARADO dano | pressão(dano/min esquiva)")
    for cap in range(1, 11):
        e, s, p = g(cen, cap, "esquiva"), g(cen, cap, "segue"), g(cen, cap, "parado")
        if not e:
            continue
        ttk = st.mean(r["ttk"] for r in e)
        mortos = sum(r["matou"] for r in e)
        dano = st.mean(r["dano"] for r in e)
        vidas = e[0]["vidas"]
        aprov = st.mean(r["aproveitamento"] for r in e)
        ds = st.mean(r["dano"] for r in s) if s else float("nan")
        dp = st.mean(r["dano"] for r in p) if p else float("nan")
        ts = st.mean(r["ttk"] for r in s) if s else float("nan")
        tp = st.mean(r["ttk"] for r in p) if p else float("nan")
        pressao = dano / max(ttk, 1) * 60
        print(f"{cap:>3} {NOMES[cap]:<9} {e[0]['hp_boss']:>5} {e[0]['dano_caneta']:>2}/{e[0]['intervalo']:.2f} |"
              f" {ttk:6.1f}s  {mortos}/{len(e)}  {dano:5.1f}/{vidas:<2}  {aprov:3.0f}% |"
              f" {ds:5.1f} ({ts:5.1f}s) | {dp:5.1f} ({tp:5.1f}s) | {pressao:5.1f}")
