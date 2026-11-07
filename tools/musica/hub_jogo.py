# Música do hub (docs/plano-musica-adaptativa.md, seção "Música do hub").
# Junta as camadas do loop de 24 compassos (cortar_loop.py com MUSICA=hub) em
# um arquivo só, em duas versões: "original" (soma das camadas, como veio da Suno)
# e "calma" (bateria abafada e mais baixa, teclado à frente). As duas saem no
# mesmo volume percebido (LUFS), para comparar o clima e não o volume.
# Uso: python tools/musica/hub_jogo.py   (saída na pasta "04 Hub/jogo", fora do repo)
import os, subprocess, json, numpy as np
SR = 48000
BASE = "C:/Users/joalh/Videos/sons sketch blade/26 musica/04 Hub"
LOOP = BASE + "/loop 24 compassos"
OUT = BASE + "/jogo"; os.makedirs(OUT, exist_ok=True)
ALVO_LUFS = -16.0

def load(f):
    r = subprocess.run(["ffmpeg", "-v", "error", "-i", f, "-ac", "2", "-ar", str(SR), "-f", "f32le", "-"], capture_output=True).stdout
    return np.frombuffer(r, np.float32).reshape(-1, 2).copy()

def lufs(x):
    p = OUT + "/_medir.wav"; save_wav(x, p)
    e = subprocess.run(["ffmpeg", "-nostats", "-i", p, "-af", "ebur128", "-f", "null", "-"], capture_output=True, text=True).stderr
    os.remove(p)
    return float(e.split("Integrated loudness:")[1].split("I:")[1].split("LUFS")[0])

def save_wav(x, p): subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "f32le", "-ar", str(SR), "-ac", "2", "-i", "-", "-c:a", "pcm_s24le", p], input=x.astype(np.float32).tobytes())
def save_ogg(x, p, q=4): subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "f32le", "-ar", str(SR), "-ac", "2", "-i", "-", "-c:a", "libvorbis", "-q:a", str(q), p], input=x.astype(np.float32).tobytes())

# Passa-baixa sem defasagem e circular (FFT do loop inteiro): não estraga a emenda.
def passa_baixa(x, fc, ordem):
    X = np.fft.rfft(x, axis=0); f = np.fft.rfftfreq(len(x), 1 / SR)
    return np.fft.irfft(X * (1 / np.sqrt(1 + (f / fc) ** (2 * ordem)))[:, None], n=len(x), axis=0).astype(np.float32)

db = lambda g: 10 ** (g / 20)
C = {k: load(f"{LOOP}/{k}.wav") for k in ["bateria", "baixo", "guitarras", "teclado", "outros"]}  # cordas: vazia (-86 dB)
N = len(C["bateria"]); assert all(len(v) == N for v in C.values())
versoes = {
    "original": sum(C.values()),
    "calma": passa_baixa(C["bateria"], 1200, 3) * db(-9) + C["baixo"] * db(-2) + C["guitarras"]
             + C["teclado"] * db(1.5) + passa_baixa(C["outros"], 6000, 2) * db(-3),
}
rel = {}
for nome, x in versoes.items():
    g = ALVO_LUFS - lufs(x); y = x * db(g)
    pk = float(np.abs(y).max())
    if pk > 0.95: y *= 0.95 / pk
    save_wav(y, f"{OUT}/hub_{nome}.wav"); p = f"{OUT}/hub_{nome}.ogg"; save_ogg(y, p)
    rel[nome] = {"ganho_db": round(g, 2), "pico": round(min(pk, 0.95), 3), "lufs": round(lufs(y), 1), "kb": round(os.path.getsize(p) / 1024)}
    print(nome, rel[nome])
grade = json.load(open(LOOP + "/grade_batidas.json"))["batidas_s"]
json.dump({"amostras": N, "duracao_s": N / SR, "batidas": len(grade), "versoes": rel}, open(OUT + "/hub.json", "w"), indent=1)
print("duração %.6f s" % (N / SR))
