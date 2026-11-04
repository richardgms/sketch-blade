# Etapa 1 da musica adaptativa (docs/plano-musica-adaptativa.md). Uso: python tools/musica/grade_batidas.py <pasta de trabalho fora do repo>
import sys, os, json; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import *
sr=22050
dr=stem("bateria",sr)
f,dt=flux(dr,sr,hop=64,n=1024)
f=f-np.convolve(f,np.ones(64)/64,mode="same"); f=np.maximum(f,0); f/=f.std()
# tempo via autocorrelation around 0.45-0.56 s
ac=np.correlate(f,f,mode="full")[len(f)-1:]
lags=np.arange(len(ac))*dt; m=(lags>0.45)&(lags<0.56)
P=lags[m][ac[m].argmax()]; print("periodo autocorr %.4f"%P)
# refine: autocorr at 16 beats
m2=(lags>P*16-0.2)&(lags<P*16+0.2); P16=lags[m2][ac[m2].argmax()]/16; print("periodo 16 batidas %.4f"%P16)
P=P16; per=P/dt
# DP beat tracking (Ellis)
N=len(f); score=f.copy(); back=-np.ones(N,int); alpha=100
for i in range(N):
    lo=int(i-2*per); hi=int(i-per/2)
    if hi<=0: continue
    lo=max(lo,0); idx=np.arange(lo,hi)
    pen=-alpha*(np.log((i-idx)/per))**2
    c=score[idx]+pen; j=c.argmax(); score[i]=f[i]+c[j]; back[i]=idx[j]
# backtrack from best near end
end=N-1-int(per); i=end-int(per)+np.argmax(score[end-int(per):end]); bt=[]
while i>=0: bt.append(i); i=back[i]
bt=np.array(bt[::-1])*dt
d=np.diff(bt); print("batidas",len(bt),"primeira %.3f ultima %.3f"%(bt[0],bt[-1]),"int med %.4f min %.4f max %.4f"%(np.median(d),d.min(),d.max()))
print("intervalos fora de 0.47-0.535:",[(round(bt[i],2),round(d[i],3)) for i in range(len(d)) if not 0.47<d[i]<0.535])
# per-beat features
fl,_=flux(dr,sr,hop=64,n=2048,fmin=30,fmax=160)
fl=fl/fl.std()
kick=np.array([fl[max(int(t/dt)-4,0):int(t/dt)+5].max() for t in bt])
strength=np.array([f[max(int(t/dt)-4,0):int(t/dt)+5].max() for t in bt])
for ph in range(4): print("fase",ph,"kick %.2f ataque %.2f"%(kick[ph::4].mean(),strength[ph::4].mean()))
json.dump({"beats":bt.tolist(),"kick":kick.tolist(),"strength":strength.tolist()},open(sys.argv[1]+"/grid.json","w"))
