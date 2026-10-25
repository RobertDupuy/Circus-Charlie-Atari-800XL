"""Atari800 title raster against the prepared art, including palette cycling."""
from emulator import Atari,R
from PIL import Image
import numpy as np,time,json
art=np.array(Image.open(R/'assets/title-art.png'));a=Atari('ntsc','title-raster',sound=True)
reports=[];colours=[];shapes=[]
try:
 for i in range(6):
  shot=a.shot(f'title-{i}.png');raw=np.array(shot)
  # Atari800's native TV crop has a 16-pixel left border. Locate the vertical
  # field from static artwork, independently of the game's DLI bookkeeping.
  choices=[]
  for top in range(20,65,2):
   if top+352>raw.shape[0]:continue
   pixels=raw[top:top+352:2,16:656:4]
   missing=int((pixels.max(axis=2)<20)[art!=0].sum());choices.append((missing,top,pixels))
  missing,top,pixels=min(choices,key=lambda v:v[0])
  assert missing==0,(i,'missing title pixels',missing,top)
  extra=int((pixels.max(axis=2)>=20)[art==0].sum())
  assert extra<=1024,(i,'nonblack scene background leaked into title',extra)
  palette=[]
  for code in (1,2,3):
   mask=art==code
   if not mask.any():mask=(art==0)&(pixels.max(axis=2)>=20)
   colours_at=np.unique(pixels[mask],axis=0)
   assert len(colours_at)==1,(i,code,'palette or character-band glitch',colours_at.tolist())
   palette.append(colours_at[0].tolist())
  colours.append(palette[1]);shapes.append((pixels.max(axis=2)>=20).tobytes())
  reports.append({'sample':i,'field_top':top,'missing_static_pixels':missing,'star_pixels':extra,'palette':palette})
  time.sleep(.22)
finally:a.close()
assert len(set(map(tuple,colours)))>=2,'Stars did not change colour'
assert len(set(shapes))>=2,'Stars did not move'
(a.out/'result.json').write_text(json.dumps({'colour_cycle':True,'moving_stars':True,'samples':reports},indent=2));print('Title art, black background, uniform palette, moving stars and colour cycle: PASS')
