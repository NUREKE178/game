"""Create AFFINIX's original pixel-art terrain, vegetation, character and UI icons."""
from PIL import Image,ImageDraw
from random import Random
from pathlib import Path
P=Path(__file__).resolve().parents[1]/'assets/affinix';P.mkdir(parents=True,exist_ok=True)
def img(w,h):
 a=Image.new('RGBA',(w,h));return a,ImageDraw.Draw(a)
def save(a,n):a.save(P/(n+'.png'))
# Four subtle variations; pixel scale stays 1:1 with the world.
for zone,base,palette in [
 ('forest','#79956c',['#67855f','#8ca67a','#9db386','#587a58']),
 ('autumn2','#a8946f',['#9b825f','#bba27b','#c9a46c','#8a7658']),
 ('mountain2','#929d8d',['#829186','#a4ae9d','#b0b7a3','#75877b']),
 ('village2','#a99f82',['#998f77','#b8ae91','#c6ba9a','#8b806c']),
 ('cave2','#596a79',['#4b5e70','#6c7d89','#7e8d96','#435666']),
 ('path','#b9a987',['#ab9b7b','#c6b795','#d1c3a0','#9d9275']),
 ('lake','#72a6a2',['#649996','#84b5aa','#a5cabc','#5b8c8c'])]:
 for v in range(4):
  r=Random(290+v*91+sum(map(ord,zone)));a=Image.new('RGBA',(16,16),base);d=ImageDraw.Draw(a)
  for i in range(13):
   x=r.randrange(1,15);y=r.randrange(1,15);c=r.choice(palette)
   if zone=='lake':d.line((x,y,min(15,x+r.randrange(2,6)),y),fill=c)
   elif zone=='path':d.point((x,y),fill=c)
   else:
    d.point((x,y),fill=c)
    if i%3==0:d.line((x,y,x+1,min(15,y+1)),fill=c)
  save(a,f'{zone}_{v}')
# New conifer and golden canopy silhouette; green oak stays available.
for name,base,mid,light in [('pine','#344f43','#4b7056','#75916b'),('golden_tree','#665640','#9e7d48','#d1a768')]:
 r=Random(908);a,d=img(48,64)
 d.rectangle((22,31,26,61),fill='#493f36');d.rectangle((24,34,26,59),fill='#85664c');d.line((18,61,29,61),fill='#4c4538')
 if name=='pine':
  d.polygon([(24,3),(14,21),(17,21),(8,34),(13,33),(4,46),(20,43),(24,46),(30,43),(44,46),(35,32),(40,34),(31,21),(34,22)],fill=base)
  d.polygon([(24,7),(17,22),(21,20),(12,34),(17,32),(9,43),(22,40),(25,42),(35,41),(30,31),(34,33),(26,19),(29,21)],fill=mid)
  for y in (19,27,35,41):d.line((17,y,25,y-2),fill=light)
 else:
  for x,y,rx,ry,c in [(24,27,21,14,base),(13,25,11,10,mid),(34,24,11,10,mid),(19,15,12,10,mid),(29,14,12,10,light),(21,15,8,6,light)]:d.ellipse((x-rx,y-ry,x+rx,y+ry),fill=c)
  for _ in range(32):
   x=r.randrange(7,41);y=r.randrange(10,34)
   if a.getpixel((x,y))[3]:d.point((x,y),fill=light)
 save(a,name)
# Individual wildflowers and grasses, transparent and usable across biomes.
for name,petal in [('wildflower_cream','#eee6c4'),('wildflower_pink','#e4b2ac'),('wildflower_blue','#acc5c3'),('grass_tuft','#b8c996')]:
 a,d=img(16,18);d.line((8,16,8,7),fill='#567c54');d.line((8,14,4,11),fill='#6a8d5e');d.line((8,12,11,9),fill='#769765')
 if name!='grass_tuft':
  for x,y in [(8,5),(6,7),(10,7),(8,9)]:d.rectangle((x,y,x+1,y+1),fill=petal)
  d.point((8,7),fill='#caa765')
 else:
  d.line((5,16,3,9),fill='#91ae79');d.line((11,16,13,8),fill='#91ae79')
 save(a,name)
# 8 walking frames × 4 directions. Body remains anchored at the feet.
a,_=img(256,128)
for direction in range(4):
 for f in range(8):
  b,d=img(32,32); bob=[0,0,1,1,0,0,1,1][f]; stride=[0,1,2,1,0,-1,-2,-1][f]; dark='#303d3b'; hoodie='#78917b'; highlight='#9eb49a'; skin='#e9b89c'; hair='#443a35'
  # backpack is behind the hoodie, visible from the side and back
  d.rounded_rectangle((8,13+bob,13,22+bob),2,fill=dark);d.rectangle((9,14+bob,12,21+bob),fill='#9a7e5b');d.point((10,15+bob),fill='#d5bc8e')
  for x,off in [(11,stride),(17,-stride)]:
   d.rectangle((x,20+bob,x+4,27+bob+off),fill=dark);d.rectangle((x+1,21+bob,x+3,26+bob+off),fill='#68777a');d.rectangle((x,27+bob+off,x+4,28+bob+off),fill='#e4d9c4')
  d.rounded_rectangle((9,11+bob,23,22+bob),2,fill=dark);d.rectangle((10,13+bob,22,21+bob),fill=hoodie);d.rectangle((11,13+bob,21,14+bob),fill=highlight)
  d.rectangle((8,15+bob,10,20+bob),fill=hoodie);d.rectangle((22,15+bob,24,20+bob),fill=hoodie)
  if direction==1:
   d.rectangle((12,14+bob,20,21+bob),fill='#987e5f');d.rectangle((13,15+bob,19,20+bob),fill='#b39570');d.line((16,15+bob,16,19+bob),fill='#705b48')
  d.rounded_rectangle((10,4+bob,22,15+bob),2,fill=dark);d.rectangle((11,7+bob,21,13+bob),fill=skin)
  d.polygon([(10,8+bob),(10,5+bob),(12,3+bob),(15,4+bob),(18,2+bob),(22,5+bob),(22,9+bob),(19,8+bob),(17,6+bob),(14,8+bob)],fill=hair)
  if direction==0:d.point((13,10+bob),fill=dark);d.point((19,10+bob),fill=dark);d.line((15,12+bob,17,12+bob),fill='#ad786b')
  elif direction==1:d.rectangle((12,8+bob,21,13+bob),fill=hair)
  elif direction==2:d.point((12,10+bob),fill=dark)
  else:d.point((20,10+bob),fill=dark)
  a.alpha_composite(b,(f*32,direction*32))
save(a,'chill_boy_v2')
# Compact actual item art for the functional hotbar and bag.
icons={'axe':('#b7c4b5','#71513b'),'pickaxe':('#9aab9e','#6e513c'),'rod':('#b69d73','#f2e3bc'),'berry':('#ce7f7b','#62885e'),'meal':('#e3c697','#946c4f'),'wood':('#aa7f58','#604935'),'stone':('#a7b1a4','#64756a'),'lantern':('#efd18a','#785d43'),'health':('#e49c94','#a75e61'),'hunger':('#dfc081','#9b7750'),'energy':('#c2d59c','#718e65'),'temperature':('#a9c7c2','#628d8d'),'sun':('#e9cb8c','#f2ddb1'),'rain_icon':('#9cbfc4','#d5e8df'),'fog_icon':('#c0cdc4','#8ea49b'),'wind_icon':('#c8d6bd','#8ba58d')}
for name,(c1,c2) in icons.items():
 a,d=img(16,16)
 if name in ('axe','pickaxe','rod'):
  d.line((3,14,11,3),fill=c2,width=2)
  if name=='axe':d.polygon([(9,3),(14,2),(14,6),(10,8),(8,6)],fill=c1)
  elif name=='pickaxe':d.line((7,4,13,2),fill=c1,width=2)
  else:d.line((11,3,14,11),fill=c1)
 elif name=='berry':d.ellipse((3,6,9,13),fill=c1);d.ellipse((8,5,13,12),fill=c1);d.line((8,7,9,3),fill=c2,width=2)
 elif name=='meal':d.ellipse((2,7,13,13),fill=c2);d.rectangle((3,6,12,9),fill=c1);d.point((6,4),fill=c1)
 elif name=='wood':d.rectangle((2,5,13,11),fill=c2);d.rectangle((3,6,12,10),fill=c1);d.line((5,6,5,10),fill=c2)
 elif name=='stone':d.polygon([(2,11),(4,6),(8,3),(13,7),(14,12)],fill=c2);d.polygon([(4,10),(6,6),(9,5),(12,8),(12,10)],fill=c1)
 elif name=='lantern':d.rectangle((4,4,11,13),fill=c2);d.rectangle((6,6,9,11),fill=c1);d.line((6,2,9,2),fill=c2)
 elif name=='health':d.polygon([(2,5),(4,3),(7,4),(8,6),(10,4),(12,3),(14,5),(13,9),(8,14),(3,9)],fill=c1)
 elif name=='hunger':d.ellipse((3,3,12,13),fill=c1);d.line((7,4,7,12),fill=c2)
 elif name=='energy':d.polygon([(9,1),(4,8),(7,8),(6,14),(12,6),(9,6)],fill=c1)
 elif name=='temperature':d.ellipse((5,10,11,15),fill=c1);d.rectangle((7,2,9,12),fill=c1)
 elif name=='sun':d.ellipse((4,4,11,11),fill=c1);d.point((8,1),fill=c2);d.point((8,14),fill=c2);d.point((1,8),fill=c2);d.point((14,8),fill=c2)
 else:d.line((3,6,12,6),fill=c1,width=2);d.line((2,9,11,9),fill=c2);d.line((5,12,13,12),fill=c1)
 save(a,'icon_'+name)
print('Created original AFFINIX polish assets')
