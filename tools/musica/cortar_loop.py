# Etapa 1 da musica adaptativa (docs/plano-musica-adaptativa.md). Uso: python tools/musica/cortar_loop.py <pasta de trabalho fora do repo>
import sys, os, json, subprocess; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import *
SR=48000; S0,E0=52,148
OUT=BASE+"/etapa 1 - loop 24 compassos"; os.makedirs(OUT,exist_ok=True)
g=json.load(open(sys.argv[1]+"/grid.json")); bt=np.array(g["beats"])
X={k:stem(k,SR,2) for k in ["bateria","baixo","guitarras","cordas","outros"]}
orig=load(ORIG,SR,2)
L=min(len(v) for v in X.values()); print("amostras stems",{k:len(v) for k,v in X.items()},"orig",len(orig))
dm=X["bateria"].mean(1)
def attack(t,win=0.06):
    a=int((t-win)*SR); b=int((t+win)*SR); seg=dm[a:b]
    hop=48; n=480
    env=np.array([np.sqrt((seg[i:i+n]**2).mean()) for i in range(0,len(seg)-n,hop)])
    d=np.diff(env); j=d.argmax(); return a+j*hop+n//2
as_=attack(bt[S0]); ae=attack(bt[E0])
# refine lag by xcorr of drum waveform over 1 beat
W=int(0.5*SR); best=(-2,0)
ref=dm[as_:as_+W]
for lag in range(-int(0.015*SR),int(0.015*SR)):
    seg=dm[ae+lag:ae+lag+W]; c=float(ref@seg/np.sqrt((ref@ref)*(seg@seg)))
    if c>best[0]: best=(c,lag)
ae2=ae+best[1]
print(f"ataque inicio {as_/SR:.4f}s fim {ae/SR:.4f}s ajuste {best[1]/SR*1000:.2f} ms corr bateria {best[0]:.3f}")
PRE=int(0.050*SR); T=int(0.045*SR)
ts=as_-PRE; te=ae2-PRE; N=te-ts
print(f"corte {ts/SR:.4f}s -> {te/SR:.4f}s  N={N} amostras = {N/SR:.4f}s = 96 batidas -> {60*96/(N/SR):.3f} BPM")
ang=np.linspace(0,np.pi/2,T)[:,None]; fin=np.sin(ang); fout=np.cos(ang)
info={}
cut={}
for k,x in list(X.items())+[("original_suno",orig)]:
    y=x[ts:te].copy(); cont=x[te:te+T]
    c=float((cont.ravel()@y[:T].ravel())/np.sqrt((cont.ravel()@cont.ravel())*(y[:T].ravel()@y[:T].ravel())+1e-12))
    y[:T]=cont*fout+y[:T]*fin
    # wrap discontinuity vs typical step
    jump=np.abs(y[0]-y[-1]).max(); typ=np.percentile(np.abs(np.diff(y,axis=0)).max(1),99)
    info[k]={"corr_regiao_cruzamento":round(c,3),"salto_emenda":round(float(jump),4),"passo_p99":round(float(typ),4)}
    cut[k]=y
for k,v in info.items(): print(k,v)
for k in X:
    p=OUT+f"/{k}.wav"
    subprocess.run(["ffmpeg","-v","error","-y","-f","f32le","-ar",str(SR),"-ac","2","-i","-","-c:a","pcm_s24le",p],input=cut[k].astype(np.float32).tobytes())
mix=sum(cut[k] for k in X); pk=np.abs(mix).max(); print("pico soma camadas",round(float(pk),3))
if pk>0.98: mix*=0.98/pk
def save(arr,name,q=8):
    subprocess.run(["ffmpeg","-v","error","-y","-f","f32le","-ar",str(SR),"-ac","2","-i","-","-c:a","libvorbis","-q:a",str(q),OUT+"/"+name],input=arr.astype(np.float32).tobytes())
save(np.concatenate([mix]*3),"TESTE loop 24 compassos - 3 voltas (soma das camadas).ogg")
o=cut["original_suno"]; save(np.concatenate([o]*3),"TESTE loop 24 compassos - 3 voltas (mix original).ogg")
k8=8*SR; gap=np.zeros((int(1.5*SR),2),np.float32)
foco=np.concatenate([mix[-k8:],mix[:k8],gap]*3); save(foco,"TESTE so a emenda - 8s antes e 8s depois, 3x.ogg")
json.dump({"inicio_s":ts/SR,"fim_s":te/SR,"amostras":int(N),"sr":SR,"batidas":96,"bpm":60*96/(N/SR),"cruzamento_ms":45,"curva":"potencia igual (seno/cosseno)","pre_ataque_ms":50,"info":info},open(OUT+"/corte.json","w"),indent=1)
# beat grid relative to loop start
grid=[(bt[i]-ts/SR) for i in range(S0,E0)]; json.dump({"batidas_s":[round(x,4) for x in grid]},open(OUT+"/grade_batidas.json","w"))
print("emendas no arquivo de 3 voltas: %.2f s e %.2f s"%(N/SR,2*N/SR))
