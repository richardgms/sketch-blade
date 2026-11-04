# Caminhos e funcoes comuns dos scripts de musica (fora do repo: pasta 26 musica).
import subprocess, numpy as np
BASE="C:/Users/joalh/Videos/sons sketch blade/26 musica/01 Sala sci-fi (escolhida)"
MO=BASE+"/camadas do Moises (zips)/Escolar 7 - Cheia-E minor-120bpm-440hz/Escolar 7 - Cheia-"
SUF="-E minor-120bpm-440hz.wav"
STEMS={"bateria":"Drums","baixo":"Bass","guitarras":"Electric Guitars","cordas":"Strings","outros":"Other","metronomo_moises":"Metronome"}
ORIG=BASE+"/originais suno/Escolar 7 - Cheia.wav"
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
