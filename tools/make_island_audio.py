"""Original synthesized prototype ambience and interaction sounds; no samples used."""
import math,random,wave,struct
from pathlib import Path
out=Path(__file__).resolve().parents[1]/'assets/island/audio';out.mkdir(parents=True,exist_ok=True)
RATE=22050

def save(name, samples):
 with wave.open(str(out / (name+'.wav')), 'wb') as w:
  w.setnchannels(1); w.setsampwidth(2); w.setframerate(RATE)
  w.writeframes(b''.join(struct.pack('<h',int(max(-1,min(1,s))*32767)) for s in samples))
# Periodic, smoothly filtered random noise gives a seam-free 12-second breeze.
r=random.Random(1907); n=RATE*12; raw=[r.uniform(-1,1) for _ in range(n)]; noise=[]; v=0
for x in raw:
 v=v*.984+x*.016
 noise.append(v)
# crossfade the tail to the head, so the repeating loop has no hard discontinuity
for i in range(2200):
 t=i/2199; noise[-2200+i]=noise[-2200+i]*(1-t)+noise[0]*t
samples=[]
for i,x in enumerate(noise):
 t=i/RATE; swell=.48+.22*math.sin(2*math.pi*t/6)+.08*math.sin(2*math.pi*t/3)
 samples.append(x*swell*.8)
save('wind',samples)
def effect(name,duration,fn): save(name,[fn(i/RATE,duration) for i in range(int(RATE*duration))])
r=random.Random(99)
effect('step',.22,lambda t,d: (r.uniform(-1,1)*.3+math.sin(2*math.pi*76*t)*.6)*math.exp(-t*23)*.45)
effect('collect',.28,lambda t,d: (.14*math.sin(2*math.pi*(440*t+300*t*t))+.05*math.sin(2*math.pi*660*t))*math.exp(-t*9))
r=random.Random(19)
effect('crash',3.4,lambda t,d: (r.uniform(-1,1)*.38+math.sin(2*math.pi*(80*t-7*t*t))*.4)*math.exp(-t*1.4)*min(1,t*8)*.65)
effect('craft',.4,lambda t,d: .18*(math.sin(2*math.pi*392*t)+math.sin(2*math.pi*588*t))*math.exp(-t*6))
