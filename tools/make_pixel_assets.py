"""Original DALA pixel sprites and stretchable UI. Requires Pillow to regenerate."""
from PIL import Image, ImageDraw
from pathlib import Path
P=Path(__file__).resolve().parents[1]/'assets'
for n in ['ui','sprites']: (P/n).mkdir(parents=True,exist_ok=True)
D='#171b34'; EDGE='#946b39'; GOLD='#e8ab4c'; LIGHT='#ffdb84'; CREAM='#fff0c3'; TEAL='#45c6b5'; WHITE='#fff9e5'
def panel(name, fill, edge, hi):
 im=Image.new('RGBA',(32,32)); d=ImageDraw.Draw(im)
 d.polygon([(4,0),(27,0),(27,2),(30,2),(30,4),(31,4),(31,27),(30,27),(30,30),(27,30),(27,31),(4,31),(4,30),(1,30),(1,27),(0,27),(0,4),(1,4),(1,2),(4,2)],fill=D)
 d.rectangle((2,4,29,27),fill=edge); d.rectangle((4,2,27,29),fill=edge)
 d.rectangle((4,4,27,27),fill=fill); d.line((5,5,26,5), fill=hi); d.line((5,26,26,26),fill=D)
 for x,y in [(3,3),(28,3),(3,28),(28,28)]: d.point((x,y),fill=hi)
 im.save(P/'ui'/name)
panel('panel.png','#202641','#ae824b','#efd39a')
panel('button.png','#e3a544','#ad7131','#ffdc8b')
panel('button_hover.png','#ffe09a','#c69448','#fff3c5')
panel('button_pressed.png','#bb7e37','#8d552b','#eeb65c')
panel('button_disabled.png','#525369','#747389','#88889b')
# Sprite sheet, 16 frames, each 48x48; four rows represent idle/run/jump/dash.
sheet=Image.new('RGBA',(48*4,48*4))
for state in range(4):
 for frame in range(4):
  im=Image.new('RGBA',(48,48)); d=ImageDraw.Draw(im)
  bob=([0,0,1,0][frame] if state==0 else [0,1,0,1][frame] if state==1 else 0)
  def poly(points,c): d.polygon([(x,y+bob) for x,y in points], fill=c)
  def rect(box,c): x,y,x2,y2=box; d.rectangle((x,y+bob,x2,y2+bob),fill=c)
  # Fluffy tail, body and feet, dark pixel silhouette.
  poly([(14,29),(9,26),(8,20),(4,19),(3,25),(5,32),(12,35),(16,34)],D)
  poly([(13,30),(8,28),(6,24),(5,22),(5,26),(7,30),(13,33)],GOLD)
  poly([(13,28),(9,26),(8,22),(5,21),(5,24),(8,28)],CREAM)
  poly([(14,24),(18,19),(31,19),(36,24),(38,31),(35,38),(17,38),(13,34)],D)
  poly([(16,24),(19,21),(31,21),(35,25),(36,31),(33,35),(17,35),(15,33)],GOLD)
  poly([(18,25),(21,22),(31,22),(34,26),(34,32),(31,35),(18,35),(16,31)],LIGHT)
  # Four readable animation poses.
  if state==1:
   feet=[(17,35,21,40),(30,34,34,38)] if frame%2==0 else [(19,34,23,38),(29,35,33,40)]
  elif state==2: feet=[(18,34,22,37),(30,34,34,37)]
  elif state==3: feet=[(15,34,20,37),(32,33,37,36)]
  else: feet=[(18,35,22,39),(30,35,34,39)]
  for x,y,x2,y2 in feet:
   rect((x-1,y,x2+1,y2+1),D); rect((x,y,x2,y2),GOLD); rect((x,y2-1,x2,y2),CREAM)
  # Tall ears behind the head.
  poly([(19,17),(16,5),(20,5),(25,13),(29,12),(34,5),(38,5),(36,19)],D)
  poly([(19,15),(18,7),(20,7),(24,14)],GOLD); poly([(32,14),(35,7),(37,7),(35,17)],GOLD)
  poly([(20,13),(19,9),(21,10),(23,14)],'#e58a82'); poly([(33,13),(35,9),(36,9),(35,14)],'#e58a82')
  poly([(18,15),(21,12),(32,12),(37,16),(39,22),(37,27),(33,29),(22,28),(18,25),(16,21)],D)
  poly([(20,16),(22,14),(32,14),(36,17),(37,22),(35,26),(32,27),(22,26),(19,24),(18,21)],LIGHT)
  poly([(24,22),(30,21),(36,22),(36,25),(33,27),(24,26)],CREAM)
  rect((31,18,34,22),D); rect((32,18,32,19),WHITE); rect((33,21,34,22),TEAL)
  rect((37,22,38,23),D); rect((28,24,30,24),'#df8e70')
  # turquoise chest ornament
  rect((21,29,26,30),TEAL); rect((23,27,24,32),TEAL); rect((22,31,25,32),TEAL)
  sheet.alpha_composite(im,(frame*48,state*48))
sheet.save(P/'sprites'/'spirit.png')
# UI and world icons with genuine transparency.
for name in ['heart','coin','flag']:
 im=Image.new('RGBA',(24,24)); d=ImageDraw.Draw(im)
 if name=='heart':
  d.polygon([(2,6),(4,3),(9,3),(12,6),(15,3),(20,3),(22,6),(22,12),(12,22),(2,12)],fill=D)
  d.polygon([(4,6),(6,5),(9,5),(12,8),(15,5),(19,5),(20,7),(20,11),(12,19),(4,11)],fill='#ed5c72'); d.rectangle((6,6,8,7),fill='#ffbec0')
 elif name=='coin':
  d.polygon([(7,2),(16,2),(20,5),(22,9),(22,15),(19,20),(15,22),(8,22),(4,19),(2,15),(2,9),(4,5)],fill=D)
  d.polygon([(7,4),(16,4),(19,7),(20,10),(20,15),(17,19),(7,20),(4,16),(4,9)],fill=GOLD); d.rectangle((7,7,16,16),fill=LIGHT); d.line((12,7,12,16),fill='#bc7a32',width=2); d.point((7,6),fill=WHITE)
 else:
  d.rectangle((4,2,7,22),fill=D); d.rectangle((5,3,5,21),fill=CREAM)
  d.polygon([(7,3),(20,4),(20,13),(7,12)],fill=D); d.polygon([(8,4),(19,5),(19,11),(8,11)],fill='#df5b54'); d.rectangle((12,6,15,9),fill=LIGHT)
 im.save(P/'sprites'/(name+'.png'))
