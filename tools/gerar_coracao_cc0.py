"""Coração da vida crítica a partir da gravação CC0 "Heartbeat #1" (BigSoundBank s0243).
Uso: python tools/gerar_coracao_cc0.py "<wav original>"
Recorta um ciclo tum-tá começando no ataque, encaixa em 0,85 s (VidaCritica.CICLO),
equaliza para alto-falante de celular e grava assets/sons/coracao_critico.ogg (q8)
na mesma loudness do coração anterior (-24,6 LUFS). Master PCM24 em
Documentos/Sketch Blade - audio/vida-critica/coracao_critico_cc0.wav.
"""
from pathlib import Path
import subprocess, sys
import numpy as np

SR = 44100
CICLO = 0.85
N = int(CICLO * SR)
RAIZ = Path(__file__).resolve().parent.parent
OGG = RAIZ / 'assets' / 'sons' / 'coracao_critico.ogg'
MASTER = Path.home() / 'Documentos' / 'Sketch Blade - audio' / 'vida-critica' / 'coracao_critico_cc0.wav'
# Grave limpo (tira subgrave que só gasta volume), corpo em 150/320 Hz e "estalo"
# da válvula em 1,8 kHz: é o que o alto-falante do celular consegue tocar.
EQ = ('highpass=f=38:poles=2,equalizer=f=150:t=q:w=1.1:g=4,equalizer=f=320:t=q:w=1.0:g=4,'
      'equalizer=f=1800:t=q:w=0.9:g=3,acompressor=threshold=-22dB:ratio=3:attack=4:release=90:makeup=1')

def ler(p):
    r = subprocess.run(['ffmpeg', '-v', 'error', '-i', str(p), '-af', 'pan=mono|c0=0.5*c0+0.5*c1',
                        '-f', 'f32le', '-ar', str(SR), '-'], capture_output=True, check=True)
    return np.frombuffer(r.stdout, '<f4').astype(float)

def envelope(x):
    h = int(0.003 * SR)
    return np.sqrt(np.convolve(x * x, np.ones(h) / h, 'same'))

def ataques(x):
    """Começo das duas batidas: onde o envelope passa de 3% do pico de cada uma."""
    e = envelope(x); limiar = 0.25 * e.max(); res = []; i = 0
    while i < len(e) and len(res) < 2:
        if e[i] > limiar:
            p = i + int(np.argmax(e[i:i + int(0.06 * SR)]))
            j = p
            while j > 0 and e[j] > e[p] * 0.03:
                j -= 1
            res.append((j, e[p])); i = p + int(0.07 * SR)
        else:
            i += 1
    return res

x = ler(sys.argv[1])
(a1, e1), (a2, e2) = ataques(x)
inicio = max(0, a1 - int(0.002 * SR))
c = x[inicio:inicio + N].copy()
c = np.concatenate([c, np.zeros(max(0, N - len(c)))])
f = int(0.004 * SR); c[:f] *= np.linspace(0, 1, f)          # entrada sem clique
g = int(0.06 * SR); c[-g:] *= np.linspace(1, 0, g) ** 2      # cauda zera antes da emenda
print('segundo ataque: %.3f s | força relativa: %.2f' % ((a2 - inicio) / SR, e2 / e1))

# Equaliza sobre 3 ciclos e fica com o do meio: o compressor e os filtros já
# chegam "aquecidos" e o loop emenda igual ao que toca no jogo.
raw = np.tile(c, 3).astype('<f4').tobytes()
r = subprocess.run(['ffmpeg', '-v', 'error', '-f', 'f32le', '-ar', str(SR), '-ac', '1', '-i', '-',
                    '-af', EQ, '-f', 'f32le', '-'], input=raw, capture_output=True, check=True)
y = np.frombuffer(r.stdout, '<f4').astype(float)[N:2 * N]

def lufs(sinal):
    raw = np.tile(sinal, 8).astype('<f4').tobytes()
    e = subprocess.run(['ffmpeg', '-hide_banner', '-f', 'f32le', '-ar', str(SR), '-ac', '1', '-i', '-',
                        '-af', 'ebur128', '-f', 'null', '-'], input=raw, capture_output=True).stderr.decode()
    import re
    return float(re.findall(r'I:\s+(-?[\d.]+) LUFS', e)[-1])

y *= 10 ** ((-24.6 - lufs(y)) / 20)
print('pico: %.1f dBFS | LUFS: %.1f' % (20 * np.log10(np.abs(y).max()), lufs(y)))
raw = y.astype('<f4').tobytes()
base = ['ffmpeg', '-v', 'error', '-y', '-f', 'f32le', '-ar', str(SR), '-ac', '1', '-i', '-']
MASTER.parent.mkdir(parents=True, exist_ok=True)
subprocess.run(base + ['-c:a', 'pcm_s24le', str(MASTER)], input=raw, check=True)
subprocess.run(base + ['-c:a', 'libvorbis', '-q:a', '8', str(OGG)], input=raw, check=True)
print('ok:', OGG, MASTER)
