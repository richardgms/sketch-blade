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
CL={k:load(f"{C}/{k}.wav") for k in ["baixo","metronomo","bateria","guitarras_leve","guitarras","alien"]}; NC=len(CL["baixo"]); BC=barras(C)
def babs(B,N,b): return (b//len(B))*N+B[b%len(B)]
# partida nivel 3: 8 compassos. No 9o o chefe surge (rugido): a partida vai abafando (passa-baixa fechando
# de 18 kHz para 500 Hz no compasso) e desce 3 dB; a musica do chefe entra no "1" do compasso seguinte e a
# partida (ja abafada) some em 1 batida por baixo dela.
p_saida=babs(BP,NP,8); p_fim=babs(BP,NP,9)
BATIDA=int(np.load(P+"/_ataques.npy")[37]-np.load(P+"/_ataques.npy")[36])
SOBRA=BATIDA
part=sum(np.tile(x,(2,1))[:p_fim+SOBRA] for x in PL.values()).astype(np.float64)
fi=int(1.0*SR); part[:fi]*=ss(np.arange(fi)/fi)[:,None]
def passa_baixa_variavel(x,fc):  # biquad (RBJ) com corte por amostra
    y=np.zeros_like(x); z1=np.zeros(x.shape[1]); z2=np.zeros(x.shape[1]); q=0.707
    for i in range(len(x)):
        w=2*np.pi*fc[i]/SR; al=np.sin(w)/(2*q); cw=np.cos(w); a0=1+al
        b0=(1-cw)/2/a0; b1=(1-cw)/a0; b2=b0; a1=-2*cw/a0; a2=(1-al)/a0
        xi=x[i]; yi=b0*xi+z1; z1=b1*xi-a1*yi+z2; z2=b2*xi-a2*yi; y[i]=yi
    return y
seg=part[p_saida:]
fc=np.full(len(seg),500.0); zz=p_fim-p_saida
fc[:zz]=np.exp(np.log(18000)+(np.log(500)-np.log(18000))*ss(np.arange(zz)/zz))
part[p_saida:]=passa_baixa_variavel(seg,fc)
PRE = "--sem-pre" not in sys.argv  # pre-entrada: o chefe comeca 1 compasso antes, por baixo
g=np.ones(len(part)); d=zz
if PRE:  # partida desce ate -6 dB no compasso do rugido e some em 150 ms depois do "1"
    g[p_saida:p_fim]=1+(10**(-6/20)-1)*ss(np.arange(d)/d); g[p_fim:]=10**(-6/20)
    z=min(int(0.15*SR),len(part)-p_fim); g[p_fim:p_fim+z]*=1-ss(np.arange(z)/z); g[p_fim+z:]=0
else:
    g[p_saida:p_fim]=1+(10**(-3/20)-1)*ss(np.arange(d)/d); g[p_fim:]=10**(-3/20)
    g[p_fim:]*=1-ss(np.arange(len(part)-p_fim)/(len(part)-p_fim))
part=(part*g[:,None]).astype(np.float32)
# chefe: normal 16 compassos, raiva em 1 compasso, mais 16, vitoria
RAIVA=16; FIM=34
T=babs(BC,NC,FIM)
LEAD=(p_fim-p_saida) if PRE else 0   # pre-entrada = 1 compasso da partida antes do "1" do chefe
def ganhos(k):
    g=np.zeros(LEAD+T,np.float32); a=LEAD+babs(BC,NC,RAIVA); z=babs(BC,NC,RAIVA+1)-babs(BC,NC,RAIVA); r=ss(np.arange(z)/z)
    normal={"baixo":1,"metronomo":1,"bateria":1,"guitarras_leve":1,"guitarras":0,"alien":0.5}[k]
    raiva={"baixo":1,"metronomo":1,"bateria":1,"guitarras_leve":0,"guitarras":1,"alien":1}[k]
    g[LEAD:a]=normal; g[a:a+z]=normal+(raiva-normal)*r; g[a+z:]=raiva
    if LEAD:  # na pre-entrada: guitarra abafada sobe no compasso todo, baixo so na metade final, sem bateria/metronomo
        if k=="guitarras_leve": g[:LEAD]=ss(np.arange(LEAD)/LEAD)
        if k=="baixo": h=LEAD//2; g[h:LEAD]=ss(np.arange(LEAD-h)/(LEAD-h))
    return g
GANHO_CHEFE=10**(2.5/20)  # chefe normal fica no volume da partida nivel 3
idx=(np.arange(LEAD+T)-LEAD)%NC   # a pre-entrada toca o fim do loop, que emenda no "1"
chef=sum(x[idx]*ganhos(k)[:,None] for k,x in CL.items()).astype(np.float32)*GANHO_CHEFE
fo=int(1.0*SR); chef[-fo:]*=(1-ss(np.arange(fo)/fo))[:,None]
surge=load(os.path.join(SONS,"chefe_surge.ogg")); vit=load(os.path.join(SONS,"vitoria.ogg"))
tot=p_fim+T+len(vit)+SR
mix=np.zeros((tot,2),np.float32)
mix[:len(part)]+=part
mix[p_saida:p_saida+len(surge)]+=surge*0.9
mix[p_fim-LEAD:p_fim+T]+=chef
mix[p_fim+T-int(0.3*SR):p_fim+T-int(0.3*SR)+len(vit)]+=vit
pk=np.abs(mix).max(); mix*=min(1,0.95/pk)
p=OUT+("/TESTE partida - chefe - raiva - vitoria (pre-entrada).ogg" if PRE else "/TESTE partida - chefe - raiva - vitoria.ogg")
subprocess.run(["ffmpeg","-v","error","-y","-f","f32le","-ar",str(SR),"-ac","2","-i","-","-c:a","libvorbis","-q:a","8",p],input=mix.tobytes())
marcas={"chefe surge (rugido)":p_saida/SR,"musica do chefe entra":p_fim/SR,"raiva":(p_fim+babs(BC,NC,RAIVA))/SR,"vitoria":(p_fim+T)/SR}
print("duracao %.1f s"%(tot/SR),{k:round(v,1) for k,v in marcas.items()})
def rms(x): return 20*np.log10(np.sqrt((x**2).mean()))
g=GANHO_CHEFE; print("volume: partida n3 %.1f | chefe normal %.1f | chefe raiva %.1f dB"%(rms(sum(PL.values())),rms(g*(CL["baixo"]+CL["bateria"]+CL["guitarras_leve"]+0.5*CL["alien"])),rms(g*(CL["baixo"]+CL["bateria"]+CL["guitarras"]+CL["alien"]))))
