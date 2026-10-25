"""Exact-angle rope tiles shared across all eight arcade rope lengths.
Only the end tile is clipped at runtime. Positive slopes are mirrored when
needed; the atlas and fonts are read from RAM during the native draw pass.
"""
from collections import Counter
from PIL import Image,ImageDraw
import numpy as np,math,json
from pathlib import Path
import bold_art as bold

def prepare(bg):
 frames=[];freq=Counter();positive={};sine=json.loads((Path(__file__).resolve().parents[1]/"assets/arcade-apparatus.json").read_text())["sine"]
 for angle in range(91):
  for sx in range(4):
   im=Image.new('L',(52,64));ImageDraw.Draw(im).line((sx,0,sx+round(45*math.sin(math.radians(angle))),round(60*math.cos(math.radians(angle)))),fill=2)
   a=np.array(im);frame=[]
   for row in range(8):
    for col in range(13):
     tile=a[row*8:row*8+8,col*4:col*4+4].copy()
     if not tile.any():continue
     if row==0:
      tile[0,tile[0]==0]=3;tile[2,tile[2]==0]=2
     yy,xx=np.where(a[row*8:row*8+8,col*4:col*4+4]!=0);points=list(zip(xx+col*4,yy+row*8))
     p=bold.tile_bytes(tile)[0];q=bold.tile_bytes(np.fliplr(tile))[0]
     positive.setdefault(p,q);freq[p]+=1;freq[q]+=1;frame.append((col,row,p,points))
   frame.sort(key=lambda c:min(x+y for x,y in c[3]));frames.append(frame)
 data,counts,_=bg[5];cache={bytes(data[i*8:i*8+8]):i for i in range(counts[0])}
 weights=Path(__file__).resolve().parents[1]/"assets/rope-cache-weights.json"
 if weights.exists():freq=Counter({bytes.fromhex(k):v for k,v in json.loads(weights.read_text()).items()})
 for pattern,_ in freq.most_common(72):
  if pattern not in cache:
   i=counts[0];cache[pattern]=i;counts[0]+=1;data[i*8:i*8+8]=pattern
 patterns=list(positive);index={p:i for i,p in enumerate(patterns)}
 records=[]
 for fi,frame in enumerate(frames):
  angle,sx=divmod(fi,4);head=bytearray()
  for length in range(32,61,4):
   mx=sx+(length*sine[angle]*3//4)//256;my=length*sine[90-angle]//256
   visible=[any(x<=mx and y<=my for x,y in points) for col,row,p,points in frame]
   total=max((i+1 for i,v in enumerate(visible) if v),default=0)
   full=0
   for col,row,p,points in frame[:total]:
    if not all(x<=mx and y<=my for x,y in points):break
    full+=1
   assert full<64 and total-full<4,(angle,sx,length,full,total)
   head.append((full<<2)|(total-full))
  blob=head
  for col,row,p,points in frame:
   i=index[p];blob.extend((col|((i>>8)<<7),row,i&255))
  records.append((bytes(blob),len(frame)))
 atlas=b''.join(patterns);assert len(atlas)<=4096
 maps=[bytes(cache.get(p,255) for p in patterns),bytes(cache.get(positive[p],255) for p in patterns)]
 return records,atlas.ljust(4096,b'\0'),maps
