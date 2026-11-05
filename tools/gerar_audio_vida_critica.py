"""Áudio original sintetizado, sem API. Uso: python tools/gerar_audio_vida_critica.py.
OGG do jogo em assets/sons; masters PCM24 no diretório temporário indicado.
"""
from pathlib import Path
import os
import subprocess
import tempfile
import numpy as np

SR = 44100
OUT = Path(__file__).resolve().parent.parent / 'assets' / 'sons'
MASTER = Path(tempfile.gettempdir()) / 'sketch-blade-vida-critica-masters'
MASTER.mkdir(exist_ok=True)

def salvar(nome, x):
    x = x * min(1, 0.75 / max(np.max(np.abs(x)), 1e-9))
    raw = x.astype('<f4').tobytes()
    cmd = ['ffmpeg', '-v', 'error', '-y', '-f', 'f32le', '-ar', str(SR), '-ac', '1', '-i', '-']
    subprocess.run(cmd + ['-c:a', 'pcm_s24le', str(MASTER / (nome + '.wav'))], input=raw, check=True)
    subprocess.run(cmd + ['-c:a', 'libvorbis', '-q:a', '8', str(OUT / (nome + '.ogg'))], input=raw, check=True)
    print(nome, 'duracao', len(x)/SR, 'pico', np.max(np.abs(x)), 'RMS dB', 20*np.log10(np.sqrt(np.mean(x*x))+1e-12))

# Um ciclo de 0,85 s exatos, dois ataques em 0 e 0,16 s; harmônicos audíveis no celular.
t = np.arange(int(0.85 * SR)) / SR
coracao = np.zeros(len(t))
for inicio, ganho, freq in [(0, 1, 78), (0.16, 0.65, 68)]:
    u = np.maximum(t-inicio, 0)
    fase = 2*np.pi*(freq*u + freq*0.012*(1-np.exp(-u/0.02)))
    env = (1-np.exp(-u/0.0025))*np.exp(-u/0.045)*(t>=inicio)
    coracao += ganho * (np.sin(fase)+0.34*np.sin(2*fase)+0.17*np.sin(3*fase))*env
coracao *= 0.56
salvar('coracao_critico', coracao)

# Impacto de pressão: ruído entre 180 e 1800 Hz, ressonância larga; sem apito puro.
t = np.arange(int(1.2*SR))/SR
rng = np.random.default_rng(20261104)
ruido = rng.normal(0, 1, len(t))
f = np.fft.rfftfreq(len(t), 1/SR)
filtro = (1-np.exp(-(f/180)**4)) / np.sqrt(1+(f/1800)**8)
filtro *= 0.45 + np.exp(-((f-650)/380)**2)
x = np.fft.irfft(np.fft.rfft(ruido)*filtro, n=len(t))
x /= np.sqrt(np.mean(x*x))
env = (1-np.exp(-t/0.018))*np.exp(-t/0.32)*np.minimum(1, (1.2-t)/0.2)**2
salvar('zumbido_critico', 0.12*x*env)
print('Masters:', MASTER)
