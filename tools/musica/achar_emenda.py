# Etapa 1 da musica adaptativa (docs/plano-musica-adaptativa.md). Uso: MUSICA=partida|chefe python tools/musica/achar_emenda.py <pasta de trabalho> (depois de grade_batidas.py)
import sys, os, json; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import *
sr=22050
g=json.load(open(sys.argv[1]+"/grid.json")); bt=np.array(g["beats"]); nb=len(bt)
st={k:stem(k,sr) for k in CAMADAS}
DUR=len(st['bateria'])/sr
n=1024; hop=256; fr=np.fft.rfftfreq(n,1/sr); edges=np.geomspace(40,11000,33)
M=np.array([(fr>=a)&(fr<b) for a,b in zip(edges[:-1],edges[1:])]).astype(float)
SUB=12
def beatfeat(x):
    fr_=np.lib.stride_tricks.sliding_window_view(x,n)[::hop]
    S=(np.abs(np.fft.rfft(fr_*np.hanning(n),axis=1))**2)@M.T
    S=np.log10(S+1e-6); t=(np.arange(len(S))*hop+n/2)/sr
    out=[]
    for i in range(nb-1):
        ts=np.linspace(bt[i],bt[i+1],SUB,endpoint=False)
        idx=np.clip(np.searchsorted(t,ts),0,len(S)-1); v=S[idx].ravel(); out.append(v)
    out=np.array(out); return out
FS={k:beatfeat(x) for k,x in st.items()}
def cos(a,b):
    a=a-a.mean(); b=b-b.mean(); return float(a@b/(np.linalg.norm(a)*np.linalg.norm(b)+1e-9))
rng=np.random.default_rng(0); pairs=rng.integers(16,nb-1,(600,2))
for k,F in FS.items():
    r=np.mean([cos(F[i],F[j]) for i,j in pairs]); l=np.mean([cos(F[i],F[i+32]) for i in range(16,nb-1-32)]); l4=np.mean([cos(F[i],F[i+4]) for i in range(16,nb-5)])
    print(f"{k:10s} aleatorio {r:.2f} lag4 {l4:.2f} lag32 {l:.2f}")
def S(F,s,e,w=4):
    ks=[k for k in range(-w,w) if 0<=s+k<nb-1 and 0<=e+k<nb-1]
    if len(ks)<2*w: return None
    return np.mean([cos(F[s+k],F[e+k]) for k in ks])
res=[]
for L in (64,96,128,144,160):
    for s in range(0,nb,4):
        e=s+L
        if e+4>=nb-1 or bt[e]+0.6>DUR-2.0: continue
        ds={k:S(F,s,e) for k,F in FS.items() if k!="cordas"}
        if any(v is None for v in ds.values()): continue
        res.append((min(ds.values()),np.mean(list(ds.values())),L,s,e,ds))
res.sort(key=lambda r:-r[0])
for mn,av,L,s,e,ds in res[:15]:
    print(f"L={L:3d} s={s:3d} ({bt[s]:5.2f}s) e={e:3d} ({bt[e]:5.2f}s) pior {mn:.2f} media {av:.2f}",{k:round(v,2) for k,v in ds.items()})
json.dump([[r[2],r[3],r[4],r[0],r[1]] for r in res],open(sys.argv[1]+"/cands.json","w"))
print("--- melhores candidatos, so para frente (o que o ouvido espera depois da emenda)")
for mn,av,L,s0,e0,ds in res[:4]:
    for W in (4,8,16):
        d={k:np.mean([cos(F[s0+j],F[e0+j]) for j in range(W) if e0+j<nb-1]) for k,F in FS.items() if k!="cordas"}
        print(f"L={L} s={s0} e={e0} W={W}",{k:round(v,2) for k,v in d.items()})
