"""Make original 16x16 fantasy terrain sprites (requires Pillow)."""
from PIL import Image, ImageDraw
from pathlib import Path
import random
out = Path(__file__).resolve().parents[1] / 'assets/fantasy'
out.mkdir(parents=True, exist_ok=True)
def image(name, fill):
    im=Image.new('RGBA',(16,16),fill); return im,ImageDraw.Draw(im)
def save(im,name): im.save(out/(name+'.png'))
r=random.Random(488)
for name,base,spots in [('dirt','#735645',['#896849','#62483f','#a47b55']),('stone','#686c7d',['#858997','#535867','#a2a5a9']),('grass','#735645',['#896849','#62483f','#a47b55'])]:
 im,d=image(name,base)
 for i in range(35):
  x,y=r.randrange(16),r.randrange(16); d.rectangle((x,y,min(15,x+r.randrange(1,3)),min(15,y+r.randrange(0,2))),fill=r.choice(spots))
 if name=='grass':
  d.rectangle((0,0,15,3),fill='#47775f'); d.line((0,0,15,0),fill='#8bb980');
  for x in range(0,16,3): d.rectangle((x,3,x+1,5+r.randrange(2)),fill='#598964')
 save(im,name)
im,d=image('wood','#755040'); d.rectangle((1,0,3,15),fill='#9b6b4b');d.rectangle((7,0,9,15),fill='#543d38');d.rectangle((12,0,13,15),fill='#a67751'); d.rectangle((5,4,6,7),fill='#b58a60');save(im,'wood')
im,d=image('plank','#b18660');
for y in (0,5,10,15): d.line((0,y,15,y),fill='#725145')
for y,x in ((1,8),(6,3),(11,11)): d.line((x,y,x,y+3),fill='#725145'); d.point((x+2,y+1),fill='#d6ae7d')
save(im,'plank')
im,d=image('leaves',(0,0,0,0));d.polygon([(1,5),(3,2),(6,2),(7,0),(12,1),(13,3),(15,4),(15,12),(12,15),(3,15),(0,12),(0,7)],fill='#365f57');
for i in range(24):
 x,y=r.randrange(1,15),r.randrange(2,14); d.rectangle((x,y,min(x+2,15),min(y+1,15)),fill=r.choice(['#4b7d68','#638f75','#759e7b']))
save(im,'leaves')
im,d=image('berry',(0,0,0,0));d.polygon([(2,9),(4,5),(8,6),(10,3),(13,6),(14,11),(12,14),(4,14)],fill='#61364f');d.rectangle((3,8,8,13),fill='#da7186');d.rectangle((9,7,13,12),fill='#ce5f79');d.rectangle((4,8,5,9),fill='#ffd0c2');d.line((8,6,9,3),fill='#5b9870',width=2);d.rectangle((9,2,12,3),fill='#80ad78');save(im,'berry')
im,d=image('flower',(0,0,0,0));d.line((8,15,8,7),fill='#75a77d');d.polygon([(8,5),(5,3),(6,1),(8,2),(10,0),(12,2),(11,5),(13,7),(10,8),(8,6),(6,8),(4,7)],fill='#f7b4c1');d.rectangle((7,3,9,5),fill='#fce4ad');save(im,'flower')
im,d=image('brick','#7b7f89')
for y in (0,7,15): d.line((0,y,15,y),fill='#555d6a')
for x,y in ((7,1),(3,8),(12,8)): d.line((x,y,x,y+5),fill='#555d6a')
d.line((1,1,6,1),fill='#a2aaa9');d.line((5,8,11,8),fill='#a2aaa9')
save(im,'brick')
