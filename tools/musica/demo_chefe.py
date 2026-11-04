# Etapa C2 da musica adaptativa: demonstracao offline partida (nivel 3) -> chefe surge -> chefe normal -> raiva -> vitoria.
# Uso: python tools/musica/demo_chefe.py
import sys, os, json, subprocess; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import numpy as np
from common import RAIZ
SR=48000
P=RAIZ+"/01 Sala sci-fi (escolhida)/etapa 2 - camadas do jogo"; C=RAIZ+"/03 Chefe/C2 - camadas do jogo"
OUT=RAIZ+"/03 Chefe/C2 - demonstracao"; os.makedirs(OUT,exist_ok=True)
SONS=os.path.join(os.path.dirname(os.path.abspath(__file__)),"..","..","assets","sons")
def load(f):
    raw=subprocess.run(["ffmpeg","-v","error","-i",f,"-ac","2","-ar",str(SR),"-f","f32le","-"],capture_output=True).stdout
    return np.frombuffer(raw,np.float32).reshape(-1,2)
def ss(t): t=np.clip(t,0,1); return t*t*(3-2*t)
def barras(d):
    at=np.load(d+"/_ataques.npy"); return [int(a)-int(0.05*SR) for a in at[::4]]
PL={k:load(f"{P}/{k}.wav") for k in ["baixo","metronomo","bateria","guitarras","outros"]}; NP=len(PL["baixo"]); BP=barras(P)
CL={k:load(f"{C}/{k}.wav") for k in ["baixo","bateria","guitarras_leve","guitarras","alien"]}; NC=len(CL["baixo"]); BC=barras(C)
def babs(B,N,b): return (b//len(B))*N+B[b%len(B)]
# partida nivel 3: 8 compassos, sai em 1 compasso
p_fim=babs(BP,NP,9); p_saida=babs(BP,NP,8)
part=sum(np.tile(x,(2,1))[:p_fim] for x in PL.values()).copy()
fi=int(1.0*SR); part[:fi]*=ss(np.arange(fi)/fi)[:,None]
z=p_fim-p_saida; part[p_saida:]*=(1-ss(np.arange(z)/z))[:,None]
# chefe: entra no fim da saida; normal 16 compassos, raiva em 1 compasso, mais 16, vitoria
RAIVA=16; FIM=34
T=babs(BC,NC,FIM)
def ganhos(k):
    g=np.zeros(T,np.float32); a=babs(BC,NC,RAIVA); z=babs(BC,NC,RAIVA+1)-a; r=ss(np.arange(z)/z)
    normal={"baixo":1,"bateria":1,"guitarras_leve":1,"guitarras":0,"alien":0.5}[k]
    raiva={"baixo":1,"bateria":1,"guitarras_leve":0,"guitarras":1,"alien":1}[k]
    g[:a]=normal; g[a:a+z]=normal+(raiva-normal)*r; g[a+z:]=raiva; return g
reps=int(np.ceil(T/NC))+1
GANHO_CHEFE=10**(2.5/20)  # chefe normal fica no volume da partida nivel 3
chef=sum(np.tile(x,(reps,1))[:T]*ganhos(k)[:,None] for k,x in CL.items()).copy()*GANHO_CHEFE
fo=int(1.0*SR); chef[-fo:]*=(1-ss(np.arange(fo)/fo))[:,None]
surge=load(os.path.join(SONS,"chefe_surge.ogg")); vit=load(os.path.join(SONS,"vitoria.ogg"))
tot=p_fim+T+len(vit)+SR
mix=np.zeros((tot,2),np.float32)
mix[:p_fim]+=part
mix[p_saida:p_saida+len(surge)]+=surge*0.9
mix[p_fim:p_fim+T]+=chef
mix[p_fim+T-int(0.3*SR):p_fim+T-int(0.3*SR)+len(vit)]+=vit
pk=np.abs(mix).max(); mix*=min(1,0.95/pk)
p=OUT+"/TESTE partida - chefe - raiva - vitoria.ogg"
subprocess.run(["ffmpeg","-v","error","-y","-f","f32le","-ar",str(SR),"-ac","2","-i","-","-c:a","libvorbis","-q:a","8",p],input=mix.tobytes())
marcas={"chefe surge (partida sai)":p_saida/SR,"musica do chefe entra":p_fim/SR,"raiva":(p_fim+babs(BC,NC,RAIVA))/SR,"vitoria":(p_fim+T)/SR}
print("duracao %.1f s"%(tot/SR),{k:round(v,1) for k,v in marcas.items()})
def rms(x): return 20*np.log10(np.sqrt((x**2).mean()))
g=GANHO_CHEFE; print("volume: partida n3 %.1f | chefe normal %.1f | chefe raiva %.1f dB"%(rms(sum(PL.values())),rms(g*(CL["baixo"]+CL["bateria"]+CL["guitarras_leve"]+0.5*CL["alien"])),rms(g*(CL["baixo"]+CL["bateria"]+CL["guitarras"]+CL["alien"]))))
