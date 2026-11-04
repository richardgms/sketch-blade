# Etapa 3 da musica adaptativa: mixagem offline dos niveis e passagens, como o jogo faria.
# Uso: python tools/musica/demo_niveis.py
import sys, os, json, subprocess; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import numpy as np
from common import BASE
SR=48000; E2=BASE+"/etapa 2 - camadas do jogo"; OUT=BASE+"/etapa 3 - niveis"; os.makedirs(OUT,exist_ok=True)
def load(f):
    raw=subprocess.run(["ffmpeg","-v","error","-i",f,"-ac","2","-ar",str(SR),"-f","f32le","-"],capture_output=True).stdout
    return np.frombuffer(raw,np.float32).reshape(-1,2)
CAM=["baixo","metronomo","bateria_leve","bateria","guitarras_leve","guitarras","outros"]
X={k:load(f"{E2}/{k}.wav") for k in CAM}; N=len(X["baixo"])
at=np.load(E2+"/_ataques.npy"); barras=[int(at[i])-int(0.05*SR) for i in range(0,96,4)]  # 24 compassos por volta
def barra_abs(b): return (b//24)*N+barras[b%24]
NIVEIS={1:{"baixo","metronomo","guitarras_leve"},
        2:{"baixo","metronomo","bateria_leve","guitarras"},
        3:{"baixo","metronomo","bateria","guitarras","outros"}}
roteiro=[(0,1),(12,2),(28,3),(44,1)]   # (compasso, nivel)
FIM=56; T=barra_abs(FIM)
def ss(t): t=np.clip(t,0,1); return t*t*(3-2*t)
gan={k:np.zeros(T,np.float32) for k in CAM}
for k in CAM:
    g=np.zeros(T,np.float32); atual=0.0
    for j,(b,n) in enumerate(roteiro):
        alvo=1.0 if k in NIVEIS[n] else 0.0
        a=barra_abs(b); dur_b=1 if j==0 or n>roteiro[j-1][1] else 2
        z=barra_abs(b+dur_b)-a; prox=barra_abs(roteiro[j+1][0]) if j+1<len(roteiro) else T
        if j==0: g[a:prox]=alvo; atual=alvo; continue
        r=ss(np.arange(z)/z); g[a:a+z]=atual+(alvo-atual)*r; g[a+z:prox]=alvo; atual=alvo
    gan[k]=g
mix=np.zeros((T,2),np.float32)
for k in CAM:
    reps=int(np.ceil(T/N)); mix+=np.tile(X[k],(reps,1))[:T]*gan[k][:,None]
fi=int(2.0*SR); mix[:fi]*=ss(np.arange(fi)/fi)[:,None]; mix[-fi:]*=ss(np.arange(fi)/fi)[::-1][:,None]
pk=np.abs(mix).max(); mix*=min(1,0.95/pk)
p=OUT+"/TESTE niveis 1-2-3-1.ogg"
subprocess.run(["ffmpeg","-v","error","-y","-f","f32le","-ar",str(SR),"-ac","2","-i","-","-c:a","libvorbis","-q:a","8",p],input=mix.tobytes())
marcas={f"compasso {b} -> nivel {n}":round(barra_abs(b)/SR,2) for b,n in roteiro}
print("duracao %.1f s"%(T/SR),"pico %.2f"%pk,marcas)
# volume medio de cada nivel (para ver se os degraus fazem sentido)
for n,cams in NIVEIS.items():
    s=sum(X[k] for k in cams); print("nivel",n,"%.1f dB RMS"%(20*np.log10(np.sqrt((s**2).mean()))))
json.dump({"marcas_s":marcas,"niveis":{n:sorted(c) for n,c in NIVEIS.items()}},open(OUT+"/demo.json","w"),indent=1,ensure_ascii=False)
