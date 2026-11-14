"""Original AFFINIX pixel art. Run with Pillow to regenerate the atlas and character."""
from pathlib import Path
from PIL import Image, ImageDraw
from random import Random
import math
P=Path(__file__).resolve().parents[1]/'assets/affinix'
P.mkdir(exist_ok=True,parents=True)
# 16px corner transitions plus four quiet, full-tile alternatives per terrain.
# Bits are NW, NE, SE, SW; all tiles share the same edge endpoints.
terrains=[('grass','#728d65','#7d9870','#627f5e'),('autumn','#ad9972','#baa782','#998460'),('village','#9a9b7d','#aaa989','#888a70'),('cave','#64747a','#728187','#56676f'),('mountain','#879486','#97a396','#788a7d'),('sand','#c5b795','#d6c9a9','#afa283'),('dirt','#ab9b79','#baa984','#98896d'),('water','#668f92','#79a3a1','#567f84'),('stone','#929b8b','#a4ac9c','#7d8c80')]
atlas=Image.new('RGBA',(20*16,len(terrains)*16))
for row,(name,base,light,dark) in enumerate(terrains):
 for mask in range(1,20):
  m=15 if mask>=16 else mask
  tile=Image.new('RGBA',(16,16));pix=tile.load()
  for y in range(16):
   for x in range(16):
    u=(x+.5)/16;v=(y+.5)/16
    weight=((1-u)*(1-v)*bool(m&1)+u*(1-v)*bool(m&2)+u*v*bool(m&4)+(1-u)*v*bool(m&8))
    if weight>=.5: pix[x,y]=Image.new('RGB',(1,1),base).getpixel((0,0))+(255,)
  d=ImageDraw.Draw(tile); rng=Random(71+row*113+(mask if mask>=16 else 0))
  # Small intentional clusters, not a field of random single-pixel noise.
  for _ in range(2 if name!='water' else 3):
   x=rng.randrange(3,13);y=rng.randrange(3,13)
   if pix[x,y][3]:
    if name=='water': d.line((x,y,min(x+3,14),y),fill=light)
    elif name in ('grass','autumn','village','mountain'):
     d.line((x,y,x+1,y-1),fill=dark);d.point((x+2,y),fill=light)
    else:d.line((x,y,min(x+1,14),y),fill=dark)
  # Clean cut on the mask after decoration, so adjacent edges match exactly.
  for y in range(16):
   for x in range(16):
    u=(x+.5)/16;v=(y+.5)/16
    weight=(1-u)*(1-v)*bool(m&1)+u*(1-v)*bool(m&2)+u*v*bool(m&4)+(1-u)*v*bool(m&8)
    if weight<.5:pix[x,y]=(0,0,0,0)
  atlas.alpha_composite(tile,(mask*16,row*16))
atlas.save(P/'terrain_v2.png')
# Four directions × seven explicit animation states; six 32px frames each.
# Every state shares a fixed feet baseline and the same body palette.
S=32; frames=6; states=['idle','walk','run','gather','chop','fish','interact']
sheet=Image.new('RGBA',(frames*S,len(states)*4*S))
for si,state in enumerate(states):
 for direction in range(4):
  for f in range(frames):
   im=Image.new('RGBA',(S,S));d=ImageDraw.Draw(im)
   outline='#2b3b35';hood='#526e59';hood_hi='#78927a';shade='#3c5545';skin='#e6bb9c';hair='#443a34';pants='#536269';shoe='#eee5ce';bag='#9a7d58'
   stride=([0,2,1,0,-2,-1][f] if state in ('walk','run') else 0)
   if state=='run':stride=int(stride*1.5)
   bob=([0,0,1,0,0,1][f] if state in ('walk','run') else (1 if state=='idle' and f>=3 else 0))
   lean=([0,0,1,1,0,0][f] if state in ('gather','chop','interact') else 0)
   # Separate shoes and trouser legs keep the planted foot at the baseline.
   for x,k in [(11,stride),(17,-stride)]:
    foot_y=28-max(0,k)
    d.rectangle((x,21+bob,x+4,foot_y),fill=outline)
    d.rectangle((x+1,22+bob,x+3,foot_y-1),fill=pants)
    d.rectangle((x,foot_y,x+4,foot_y+1),fill=shoe)
   d.rounded_rectangle((8+lean,12+bob,23+lean,23+bob),radius=3,fill=outline)
   d.rectangle((9+lean,14+bob,22+lean,21+bob),fill=hood)
   d.line((11+lean,14+bob,20+lean,14+bob),fill=hood_hi)
   if direction==1:
    d.rounded_rectangle((12,15+bob,20,22+bob),2,fill=bag);d.line((13,17+bob,19,17+bob),fill='#c5a97e')
   elif direction in (2,3):
    bx=21 if direction==2 else 8
    d.rectangle((bx,14+bob,bx+3,21+bob),fill=bag)
   else:
    d.line((12,14+bob,12,21+bob),fill=shade);d.line((20,14+bob,20,21+bob),fill=shade)
    d.line((14,19+bob,18,19+bob),fill=hood_hi)
   # Arms gesture only in action frames; tools are visible without changing gameplay.
   a=2 if state in ('gather','chop','interact') and f in (1,2,3) else 0
   d.rectangle((7+lean,15+bob+a,9+lean,20+bob+a),fill=hood)
   d.rectangle((22+lean,15+bob-a,24+lean,20+bob-a),fill=hood)
   if state=='chop':
    d.line((24,17-a,28,10-a),fill='#856443',width=2);d.rectangle((26,9-a,30,12-a),fill='#bcc8b9')
   if state=='fish':
    tip_y=5+(1 if f in (2,3,4) else 0);d.line((23,17,29,tip_y),fill='#b39972');d.line((29,tip_y,31,15),fill='#e8e1c9')
   # Head and distinctive side-swept hair.
   d.rounded_rectangle((10+lean,4+bob,22+lean,15+bob),radius=3,fill=outline)
   d.rectangle((11+lean,7+bob,21+lean,13+bob),fill=skin)
   d.polygon([(10+lean,8+bob),(10+lean,5+bob),(13+lean,3+bob),(16+lean,4+bob),(19+lean,3+bob),(22+lean,5+bob),(22+lean,8+bob),(19+lean,7+bob),(17+lean,6+bob),(14+lean,8+bob)],fill=hair)
   if direction==0:
    d.point((13+lean,10+bob),fill=outline);d.point((19+lean,10+bob),fill=outline)
   elif direction==1:d.rectangle((11,8+bob,21,13+bob),fill=hair)
   else:d.point(((12 if direction==2 else 20)+lean,10+bob),fill=outline)
   sheet.alpha_composite(im,(f*S,(si*4+direction)*S))
sheet.save(P/'chill_boy_states.png')
# Shore reeds stay at native pixel scale.
for i in range(3):
 im=Image.new('RGBA',(16,20));d=ImageDraw.Draw(im)
 d.line((5,19,4,6+i),fill='#466d5b');d.line((9,19,10,4+i),fill='#5f8469');d.line((12,19,13,10),fill='#789774')
 d.rectangle((3,4+i,5,7+i),fill='#886c55');d.rectangle((9,2+i,11,5+i),fill='#80644f')
 im.save(P/f'reeds_{i}.png')
print('Created terrain_v2.png, chill_boy_states.png and reeds')
# Smaller tree silhouettes are separate integer-pixel assets rather than runtime scaling.
for original, name, size in [('tree.png','tree_small.png',(40,50)),('pine.png','pine_small.png',(40,54))]:
 Image.open(P/original).convert('RGBA').resize(size, Image.Resampling.NEAREST).save(P/name)
# Small native-resolution forage details.
for name in ('fallen_log','herb','leaf_pile'):
 im=Image.new('RGBA',(16,16));d=ImageDraw.Draw(im)
 if name=='fallen_log':
  d.polygon([(2,8),(5,6),(13,8),(14,11),(11,13),(3,11)],fill='#594b38')
  d.line((4,8,12,10),fill='#a1815c',width=2);d.point((3,10),fill='#d0b78d')
 elif name=='herb':
  d.line((8,14,8,5),fill='#486a50');d.polygon([(8,11),(3,9),(4,6),(8,8)],fill='#72986a');d.polygon([(8,9),(12,5),(14,6),(12,9)],fill='#86a976');d.rectangle((7,3,9,5),fill='#e1d6ad')
 else:
  d.polygon([(3,11),(5,8),(8,9),(10,7),(13,10),(11,12),(7,11),(5,13)],fill='#b49c67');d.line((4,10,7,11),fill='#d4b77d');d.point((10,9),fill='#d4b77d')
 im.save(P/(name+'.png'))
# Lake shoreline uses a 4px corner atlas: smaller tiles follow the curve closely.
small=Image.new('RGBA',(80,8))
for row,base in enumerate(('#c5b795','#668f92')):
 for col in range(1,20):
  mask=15 if col>=16 else col
  tile=Image.new('RGBA',(4,4));pix=tile.load();rgb=Image.new('RGB',(1,1),base).getpixel((0,0))
  for y in range(4):
   for x in range(4):
    u=(x+.5)/4;v=(y+.5)/4
    if (1-u)*(1-v)*bool(mask&1)+u*(1-v)*bool(mask&2)+u*v*bool(mask&4)+(1-u)*v*bool(mask&8) >= .5:pix[x,y]=rgb+(255,)
  small.alpha_composite(tile,(col*4,row*4))
small.save(P/'lake_edges_v2.png')
