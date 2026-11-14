"""Generate simple original ambient loops (no samples or external libraries)."""
import math, random, wave, struct
from pathlib import Path
out=Path(__file__).resolve().parents[1]/'assets/affinix';rate=11025

def write(name, values):
 with wave.open(str(out/name),'wb') as f:
  f.setnchannels(1);f.setsampwidth(2);f.setframerate(rate)
  f.writeframes(b''.join(struct.pack('<h',int(max(-1,min(1,v))*32767)) for v in values))
for name,notes in [('forest_music.wav',[220,277.18,329.63,392,261.63,329.63,392,329.63]),('cave_music.wav',[164.81,196,246.94,293.66,196,220,246.94,196])]:
 data=[]
 for i in range(rate*16):
  t=i/rate; note=int(t/2)%8; phase=t%2; env=math.exp(-phase*2.2)*min(1,phase*18);f=notes[note]
  tone=math.sin(math.tau*f*phase)+.27*math.sin(math.tau*f*2*phase)+.10*math.sin(math.tau*f*3*phase)
  data.append(tone*env*.095)
 write(name,data)
r=random.Random(933);v=0;data=[]
for i in range(rate*8):
 v=v*.89+r.uniform(-1,1)*.11;data.append(v*.18)
for i in range(1100):
 a=i/1099;data[-1100+i]=data[-1100+i]*(1-a)+data[0]*a
write('rain.wav',data)
