# Etapa 2 da musica adaptativa (docs/plano-musica-adaptativa.md): metronomo no loop novo,
# versoes leves (passa-baixa sem defasagem, circular para nao estragar a emenda), OGG do jogo.
# Uso: MUSICA=partida|chefe python tools/musica/camadas_jogo.py
import sys, os, json, subprocess; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import numpy as np
from common import BASE, NOME, RAIZ
SR=48000
E1=BASE+("/etapa 1 - loop 24 compassos" if NOME=="partida" else "/C2 - loop 24 compassos")
OUT=BASE+("/etapa 2 - camadas do jogo" if NOME=="partida" else "/C2 - camadas do jogo"); os.makedirs(OUT,exist_ok=True)
MET=RAIZ+"/01 Sala sci-fi (escolhida)/receita CapCut - cheia/metronomo.ogg"
def load(f,ch=2):
    raw=subprocess.run(["ffmpeg","-v","error","-i",f,"-ac",str(ch),"-ar",str(SR),"-f","f32le","-"],capture_output=True).stdout
    return np.frombuffer(raw,np.float32).reshape(-1,ch).copy()
def save_wav(x,p): subprocess.run(["ffmpeg","-v","error","-y","-f","f32le","-ar",str(SR),"-ac",str(x.shape[1]),"-i","-","-c:a","pcm_s24le",p],input=x.astype(np.float32).tobytes())
def save_ogg(x,p,q=4): subprocess.run(["ffmpeg","-v","error","-y","-f","f32le","-ar",str(SR),"-ac",str(x.shape[1]),"-i","-","-c:a","libvorbis","-q:a",str(q),p],input=x.astype(np.float32).tobytes())
L={k:load(f"{E1}/{k}.wav") for k in (["bateria","baixo","guitarras","outros"] if NOME=="partida" else ["bateria","baixo","guitarras","outros","teclado"])}
N=len(L["bateria"]); assert all(len(v)==N for v in L.values())
grade=json.load(open(E1+"/grade_batidas.json"))["batidas_s"]
# ataque real da bateria em cada batida (janela +-40 ms)
dm=L["bateria"].mean(1); hop=48; win=480
def ataque(t):
    a=max(int((t-0.04)*SR),0); b=min(int((t+0.04)*SR),N-win)
    env=np.array([np.sqrt((dm[i:i+win]**2).mean()) for i in range(a,b,hop)])
    return a+int(np.diff(env).argmax())*hop+win//2
ataques=[ataque(t) for t in grade]
# metronomo: o clique do Richard (1o clique do arquivo dele) em cada ataque, circular
met=None
if NOME=="partida":
    m=load(MET); e=np.sqrt((m.mean(1)**2)); i0=int(np.argmax(e>e.max()*0.05))
    clk=m[max(i0-int(0.004*SR),0):i0+int(0.12*SR)].copy(); fo=int(0.03*SR); clk[-fo:]*=np.linspace(1,0,fo)[:,None]
    pre=int(0.004*SR); met=np.zeros((N,2),np.float32)
    for a in ataques:
        idx=(np.arange(len(clk))+a-pre)%N; met[idx]+=clk
# passa-baixa sem defasagem e circular (FFT do loop inteiro)
def passa_baixa(x,fc,ordem,ganho_db):
    X=np.fft.rfft(x,axis=0); f=np.fft.rfftfreq(len(x),1/SR)
    g=1/np.sqrt(1+(f/fc)**(2*ordem)); y=np.fft.irfft(X*g[:,None],n=len(x),axis=0)
    return (y*10**(ganho_db/20)).astype(np.float32)
if NOME=="partida":
    camadas={"baixo":L["baixo"],"metronomo":met,"bateria_leve":passa_baixa(L["bateria"],1500,3,-4),"bateria":L["bateria"],
             "guitarras_leve":passa_baixa(L["guitarras"],900,3,-6),"guitarras":L["guitarras"],"outros":L["outros"]}
    mono={"baixo","metronomo"}
else:  # chefe: "outros" e a sobra da guitarra (vai junto); "teclado" e o efeito alienigena
    gt=L["guitarras"]+L["outros"]
    camadas={"baixo":L["baixo"],"bateria":L["bateria"],"guitarras_leve":passa_baixa(gt,900,3,-6),"guitarras":gt,"alien":L["teclado"]}
    mono={"baixo","bateria"}
rel={}
for k,x in camadas.items():
    lr=float(np.corrcoef(x[:,0],x[:,1])[0,1])
    save_wav(x,f"{OUT}/{k}.wav")
    y=x.mean(1,keepdims=True) if k in mono else x
    p=f"{OUT}/{k}.ogg"; save_ogg(y,p)
    dec=load(p,y.shape[1]); rel[k]={"canais":y.shape[1],"corr_esq_dir":round(lr,3),"kb":round(os.path.getsize(p)/1024),"amostras_ogg":len(dec),"rms_db":round(float(20*np.log10(np.sqrt((x**2).mean())+1e-9)),1)}
    print(k,rel[k])
print("N esperado",N,"| total OGG %.2f MB"%(sum(r["kb"] for r in rel.values())/1024))
bpm=60*len(grade)/(N/SR)
json.dump({"amostras":N,"sr":SR,"duracao_s":N/SR,"bpm":round(bpm,4),"beat_count":len(grade),"bar_beats":4,
           "batidas_s":[round(a/SR,4) for a in ataques],"camadas":rel},open(OUT+f"/musica_{NOME}.json","w"),indent=1)
np.save(OUT+"/_ataques.npy",np.array(ataques))
