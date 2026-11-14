"""Original pixel art sprites. Requires Pillow; PNGs are committed for play."""
from PIL import Image, ImageDraw
from pathlib import Path
from random import Random
out=Path(__file__).resolve().parents[1]/'assets/affinix';out.mkdir(parents=True,exist_ok=True)
r=Random(193)
def blank(w,h):
 im=Image.new('RGBA',(w,h));return im,ImageDraw.Draw(im)
def save(im,name):im.save(out/(name+'.png'))
D='#303d3b'; skin='#e9b89c'; hair='#453934'; hoodie='#879e84'; light='#a6b79a'
sheet,_=blank(32*4,32*4)
for direction in range(4):
 for f in range(4):
  im,d=blank(32,32); swing=[0,1,0,-1][f]; bob=[0,0,1,0][f]
  # grounded silhouette and tiny backpack
  d.rounded_rectangle((9,9+bob,22,25+bob),2,fill=D)
  d.rectangle((7,14+bob,10,21+bob),fill='#806950');d.rectangle((8,15+bob,10,19+bob),fill='#ad9674')
  d.rectangle((11,20+bob,15,27+bob+swing),fill=D);d.rectangle((17,20+bob,21,27+bob-swing),fill=D)
  d.rectangle((12,21+bob,14,26+bob+swing),fill='#68737a');d.rectangle((18,21+bob,20,26+bob-swing),fill='#68737a')
  d.rectangle((11,27+bob+swing,15,28+bob+swing),fill='#e0d4bd');d.rectangle((17,27+bob-swing,21,28+bob-swing),fill='#e0d4bd')
  d.rectangle((10,14+bob,22,21+bob),fill=hoodie);d.rectangle((11,14+bob,20,15+bob),fill=light)
  d.rectangle((9,16+bob,10,20+bob),fill=hoodie);d.rectangle((22,16+bob,23,20+bob),fill=hoodie)
  d.rounded_rectangle((10,5+bob,21,15+bob),2,fill=D);d.rectangle((11,7+bob,20,13+bob),fill=skin)
  d.polygon([(10,7+bob),(10,4+bob),(13,3+bob),(15,4+bob),(18,3+bob),(22,6+bob),(21,9+bob),(18,8+bob),(16,6+bob),(13,8+bob)],fill=hair)
  if direction==0:
   d.point((13,10+bob),fill=D);d.point((18,10+bob),fill=D);d.line((15,12+bob,16,12+bob),fill='#a56f66')
  elif direction==1: d.rectangle((12,8+bob,20,13+bob),fill=hair)
  elif direction==2: d.point((12,10+bob),fill=D)
  else: d.point((19,10+bob),fill=D)
  sheet.alpha_composite(im,(f*32,direction*32))
save(sheet,'chill_boy')
# deliberately hand-authored small foliage clusters
for name,pal in [('tree',['#354f3e','#466e4e','#60855a','#7d9b68']),('dark_tree',['#2f4340','#3a5b4c','#4c6d58','#65836c'])]:
 im,d=blank(48,60);d.rectangle((21,32,26,57),fill='#503e34');d.rectangle((23,33,26,56),fill='#85644a');d.rectangle((19,53,28,57),fill='#503e34')
 for x,y,radius,col in [(24,23,17,pal[0]),(12,24,10,pal[1]),(35,24,10,pal[1]),(16,15,10,pal[2]),(30,13,11,pal[2]),(24,10,7,pal[3])]:
  d.ellipse((x-radius,y-radius//2,x+radius,y+radius//2+5),fill=col)
 for _ in range(50):
  x=r.randrange(6,42);y=r.randrange(10,34)
  if im.getpixel((x,y))[3] and y<30:d.rectangle((x,y,x+1,y+1),fill=pal[r.randrange(1,4)])
 save(im,name)
im,d=blank(80,64);d.rectangle((11,24,68,58),fill='#533d33');d.rectangle((14,26,65,56),fill='#a27c58');
for y in range(30,57,6): d.line((14,y,65,y),fill='#79583f',width=1)
d.polygon([(4,26),(12,16),(37,3),(69,16),(76,26),(70,28),(39,13),(12,28)],fill='#3c4240');d.polygon([(12,23),(38,8),(68,23),(66,25),(38,13),(13,26)],fill='#79634d')
for x in (21,52):
 d.rectangle((x,30,x+9,40),fill='#453b35');d.rectangle((x+1,31,x+8,39),fill='#d7bc83');d.line((x+5,31,x+5,39),fill='#725441');d.line((x+1,35,x+8,35),fill='#725441')
d.rectangle((34,38,46,58),fill='#4d3a31');d.rectangle((36,40,44,57),fill='#8a6347');d.point((42,48),fill='#e9cf86');d.rectangle((9,58,71,60),fill='#6b624f');d.rectangle((53,7,59,17),fill='#60544b')
save(im,'cabin')
im,d=blank(24,18);d.polygon([(2,15),(3,8),(9,3),(17,4),(22,10),(21,16)],fill='#555f5e');d.polygon([(4,12),(8,5),(16,6),(20,11),(19,14),(5,14)],fill='#929b8e');d.line((8,7,13,6),fill='#c4c7b4');save(im,'rock')
im,d=blank(24,18);d.ellipse((1,5,22,16),fill='#405d45');d.ellipse((3,2,18,13),fill='#638a5a');
for x,y in [(6,8),(12,5),(16,10),(9,12)]: d.rectangle((x,y,x+2,y+2),fill='#d48282');d.point((x,y),fill='#f7c9b7')
save(im,'berry_bush')
im,d=blank(16,16);d.rectangle((7,10,9,14),fill='#d7cdb4');d.pieslice((2,3,13,12),180,360,fill='#b76c5e');d.rectangle((3,8,12,9),fill='#a8544f');d.point((6,5),fill='#f6d9bc');save(im,'mushroom')
im,d=blank(20,18);d.polygon([(1,13),(4,8),(7,11),(9,4),(12,9),(15,6),(18,14)],fill='#d78a48');d.polygon([(5,14),(8,10),(10,6),(12,12),(15,14)],fill='#f5d08a');d.line((1,16,18,16),fill='#574839',width=2);save(im,'campfire')
im,d=blank(24,28);d.ellipse((5,8,18,22),fill='#384f3e');d.rectangle((10,17,14,26),fill='#584638');d.ellipse((7,5,17,17),fill='#7da868');d.rectangle((9,7,15,13),fill='#a9c787');save(im,'sapling')
im,d=blank(24,30);d.rectangle((7,7,17,21),fill=D);d.rectangle((8,9,16,20),fill='#b78d73');d.rectangle((7,5,17,9),fill='#c8c3ac');d.rectangle((6,20,18,28),fill='#668798');d.point((10,13),fill=D);d.point((15,13),fill=D);save(im,'npc')
im,d=blank(24,18);d.rectangle((1,4,22,16),fill='#544232');d.rectangle((3,6,20,14),fill='#ac8557');d.rectangle((4,4,19,6),fill='#d3af7a');d.rectangle((11,8,13,11),fill='#e6d1a0');save(im,'chest')
print('Pixel art generated')
for name,base,colors in [('grass','#79986c',['#89a97a','#6d8c62','#9db88a']),('autumn','#ad9670',['#c5a77c','#9e8764','#d4ae79']),('mountain','#929e8d',['#aab1a1','#7e8a7d','#bcc2af']),('village','#afa485',['#bdb395','#a3997b','#d1c4a2']),('cave','#58677a',['#6e7a8b','#48586c','#8392a0']),('water','#76aaa5',['#8ebbb2','#6da09f','#b3d3c5'])]:
 im=Image.new('RGBA',(16,16),base);d=ImageDraw.Draw(im)
 for i in range(13):
  x=r.randrange(16);y=r.randrange(16);d.rectangle((x,y,min(x+r.randrange(1,4),15),min(y+r.randrange(1,2),15)),fill=r.choice(colors))
 save(im,name)
for name,coat in [('rabbit','#ded7c0'),('fox','#bd8a62'),('bird','#798f8b')]:
 im,d=blank(16,16);d.ellipse((3,7,13,13),fill='#394c40');d.ellipse((4,7,12,12),fill=coat)
 if name=='rabbit':d.rectangle((5,2,7,8),fill=coat);d.rectangle((9,3,11,8),fill=coat)
 if name=='fox':d.polygon([(5,7),(5,4),(8,7),(11,4),(12,9)],fill=coat);d.rectangle((1,8,4,10),fill='#ebd9b9')
 if name=='bird':d.rectangle((11,8,14,9),fill='#d1bb85')
 d.point((10,8),fill='#2a3d36');save(im,name)
