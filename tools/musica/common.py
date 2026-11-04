# Caminhos e funcoes comuns dos scripts de musica (arquivos fora do repo: pasta 26 musica).
# Escolha a musica com a variavel de ambiente MUSICA=partida (padrao) ou MUSICA=chefe.
import os, subprocess, numpy as np
RAIZ="C:/Users/joalh/Videos/sons sketch blade/26 musica"
MUSICAS={
    "partida":{"base":RAIZ+"/01 Sala sci-fi (escolhida)",
               "mo":"/camadas do Moises (zips)/Escolar 7 - Cheia-E minor-120bpm-440hz/Escolar 7 - Cheia-",
               "suf":"-E minor-120bpm-440hz.wav","orig":"/originais suno/Escolar 7 - Cheia.wav",
               "stems":{"bateria":"Drums","baixo":"Bass","guitarras":"Electric Guitars","cordas":"Strings","outros":"Other","metronomo_moises":"Metronome"}},
    "chefe":{"base":RAIZ+"/03 Chefe",
             "mo":"/camadas do Moises (zip)/Boss Fight/Boss Fight-",
             "suf":"-E minor-118bpm-440hz.wav","orig":"/originais suno/Boss Fight.wav",
             "stems":{"bateria":"Drums","baixo":"Bass","guitarras":"Guitars","teclado":"Keys","outros":"Other","metronomo_moises":"Metronome"}},
}
NOME=os.environ.get("MUSICA","partida"); M=MUSICAS[NOME]
BASE=M["base"]; MO=M["base"]+M["mo"]; SUF=M["suf"]; ORIG=M["base"]+M["orig"]; STEMS=M["stems"]
CAMADAS=[k for k in STEMS if k!="metronomo_moises"]
def load(f,sr=22050,ch=1):
    raw=subprocess.run(["ffmpeg","-v","error","-i",f,"-ac",str(ch),"-ar",str(sr),"-f","f32le","-"],capture_output=True).stdout
    x=np.frombuffer(raw,dtype=np.float32)
    return x.reshape(-1,ch) if ch>1 else x
def stem(k,sr=22050,ch=1): return load(MO+STEMS[k]+SUF,sr,ch)
def flux(x,sr,hop=128,n=1024,fmin=0,fmax=None):
    w=np.hanning(n); fr=np.fft.rfftfreq(n,1/sr)
    m=(fr>=fmin)&(fr<=(fmax or sr/2))
    frames=np.lib.stride_tricks.sliding_window_view(x,n)[::hop]
    S=np.abs(np.fft.rfft(frames*w,axis=1))[:,m]
    S=np.log1p(10*S)
    f=np.maximum(0,np.diff(S,axis=0)).sum(1)
    return np.concatenate([[0],f]), hop/sr
