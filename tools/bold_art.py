"""Arcade-derived actors and authored five-colour Atari scenery.
0 transparent/background, 1 dark red, 2 warm light, 3 gold, 4 blue.
All geometry, colour choice and shifting is performed before assembly.
"""
from pathlib import Path
import numpy as np, math
from PIL import Image,ImageDraw
R=Path(__file__).resolve().parents[1]
A=np.load(R/'assets/arcade-sprites.npz');H=np.load(R/'assets/hero.npz')['frames']
J=np.load(R/'assets/hero-arcade-jump.npy')
OVERLAYS={}

def outlined(a):
 solid=a!=0;d=np.zeros_like(solid);d[1:]|=solid[:-1];d[:-1]|=solid[1:];d[:,1:]|=solid[:,:-1];d[:,:-1]|=solid[:,1:]
 b=a.copy();b[d&~solid]=1;return b

def arcade_actor(src,w,h,pid):
 src=np.array(Image.fromarray(src).resize((w,h),Image.Resampling.NEAREST))
 a=np.zeros_like(src);a[np.isin(src,[1,3,11,12,15])]=2;a[np.isin(src,[2,8])]=1;a[np.isin(src,[7,13])]=3;a[np.isin(src,[9,10])]=4
 masks=[];offsets=[]
 for ids in ([9],[10],[3,15]):
  mask=np.isin(src,ids);xs=np.where(mask)[1];x=int(xs.min()) if len(xs) else 0
  if np.any(mask[:,x+8:]):mask[:,x+7]|=np.any(mask[:,x+8:],axis=1);mask[:,x+8:]=False
  q=np.zeros((h,8),np.uint8);chunk=mask[:,x:x+8];q[:,:chunk.shape[1]]=chunk
  masks.append(bytes(sum(int(v)<<(7-i) for i,v in enumerate(row)) for row in q).ljust(48,b'\0'));offsets.append(x)
 OVERLAYS[pid]=(offsets,h,masks)
 return outlined(a)

def charlie(base,pid):
 p=A['pixels'];a=np.concatenate([np.concatenate([p[base],p[base+1]],1),np.concatenate([p[base+2],p[base+3]],1)],0)
 src=A['lookup'][0,a];ys,xs=np.where(src!=0);src=src[ys.min():ys.max()+1,xs.min():xs.max()+1]
 # Consistent canvas and foot anchor across the animated poses.
 return arcade_actor(src,16,38,pid)

def horse(phase):
 im=Image.new('L',(30,32));d=ImageDraw.Draw(im)
 d.polygon([(3,14),(9,9),(20,9),(23,3),(28,4),(29,10),(26,14),(23,14),(21,23),(9,23),(5,20)],fill=2)
 d.line((2,14,0,22,4,19,6,15),fill=1,width=2)
 d.polygon([(21,7),(21,2),(24,0),(24,4),(27,1),(27,5),(23,12)],fill=1)
 d.line((23,6,28,7),fill=2,width=2);d.point((27,7),fill=1)
 d.line((25,12,29,11),fill=1)
 for x,step in ((9,phase-1),(19,1-phase)):
  d.line((x,20,x+step*2,27,x+step*3,30),fill=2,width=2);d.line((x+step*3-1,30,x+step*3+2,30),fill=1)
 d.rectangle((10,9,18,13),fill=4);d.line((11,9,17,9),fill=3)
 return outlined(np.array(im))

def hoop(phase,small=False):
 if small:
  full=hoop(phase,False)
  return np.concatenate((full[:32],full[48:]),axis=0)
 w,h=16,72
 im=Image.new('L',(w,h));d=ImageDraw.Draw(im);cx=(w-1)/2
 # The 55-pixel jump puts the rider's highest pixel at playfield Y=79.
 # The opening must start above that, while its lower edge remains aligned
 # with the established normal/money-hoop clearance rules. Keep the actor
 # and jump unchanged; extend the opening upward inside this same canvas.
 top,bottom=4,67;cy=(top+bottom)/2;ry=(bottom-top)/2
 for n in range(32):
  t=n*math.tau/32;wave=1.14 if (n+phase*2)%7<3 else 1
  x=round(cx+(w/2-2)*math.cos(t)*wave)
  y=max(top-2,min(bottom+3,round(cy+ry*math.sin(t)*wave)))
  d.line((x,y,round(cx+(w/2-3)*math.cos(t)),round(cy+(ry-2)*math.sin(t))),fill=1,width=2)
 # Fire belongs around the rim. Clear its interior explicitly so animated
 # tongues cannot consume the headroom that the opening is meant to provide.
 aperture=Image.new('L',(w,h));ad=ImageDraw.Draw(aperture)
 ad.ellipse((2,top,w-3,bottom),fill=1,outline=0,width=1)
 pixels=np.array(im);pixels[np.array(aperture)!=0]=0
 im=Image.fromarray(pixels);d=ImageDraw.Draw(im)
 d.ellipse((2,top,w-3,bottom),outline=3,width=1)
 rim_y,rim_x=np.where(np.array(im)==3)
 for n in range(12):
  t=(n+phase*.3)*math.tau/12;x=cx+(w/2-2.5)*math.cos(t);y=cy+ry*math.sin(t)
  i=int(np.argmin((rim_x-x)**2+(rim_y-y)**2));d.point((int(rim_x[i]),int(rim_y[i])),fill=2)
 # Keep the hanger visible through the top flame.
 d.line((int(cx)-1,0,int(cx)+1,1,int(cx),2,int(cx),top),fill=2)
 return np.array(im)

def goal_platform():
 im=Image.new('L',(32,11));d=ImageDraw.Draw(im)
 d.rectangle((0,1,31,10),fill=4)
 for x in range(3,32,8):d.rectangle((x,3,x+3,10),fill=2)
 d.line((1,0,30,0),fill=3);d.line((0,2,31,2),fill=2)
 return np.array(im)

def distance_sign(label):
 tiny={'0':['111','101','101','101','111'],'1':['010','110','010','010','111'],
 '2':['111','001','111','100','111'],'3':['111','001','111','001','111'],
 '4':['101','101','111','001','001'],'5':['111','100','111','001','111'],
 '6':['111','100','111','101','111'],'M':['101','111','111','101','101'],
 'G':['111','100','101','101','111'],'O':['111','101','101','101','111'],
 'A':['010','101','111','101','101'],'L':['100','100','100','100','111']}
 a=np.zeros((8,16),np.uint8);a[:]=4
 start=(16-len(label)*4+1)//2
 for j,c in enumerate(label):
  for y,row in enumerate(tiny[c]):
   for x,v in enumerate(row):
    if v=='1':a[y+1,start+j*4+x]=2
 a[7,:]=3
 return a

def pot(phase):
 if phase:
  a=pot(0).copy()
  a[0:2,4]=3;a[1:3,8]=1;a[2:4,12]=3
  return a
 im=Image.new('L',(16,24));d=ImageDraw.Draw(im)
 d.ellipse((1,16,14,23),fill=1);d.line((1,17,14,17),fill=2,width=2);d.line((4,23,11,23),fill=3)
 for j in range(3):
  x=3+j*4;h=2+(j*3+phase*2)%7
  d.polygon([(x-2,17),(x-2,11),(x+1,h),(x,10),(x+2,17)],fill=1)
  d.polygon([(x-1,17),(x,h+4),(x+1,17)],fill=3);d.point((x,16),fill=2)
 return np.array(im)

def monkey(phase,pink=False):
 im=Image.new('L',(12,17));d=ImageDraw.Draw(im);body=2 if pink else 3
 d.arc((4,0,11,10),200,500,fill=1,width=2);d.ellipse((3,5,10,13),fill=body)
 d.ellipse((0,4,6,10),fill=1);d.ellipse((0,6,4,10),fill=2);d.point((2,6),fill=1)
 d.line((1,11,3,13,0 if phase&1 else 5,16),fill=body,width=2)
 d.line((8,12,8+(phase&1)*2,15,10,16),fill=body,width=2)
 d.line((3,10,0,12),fill=body);d.point((0,9),fill=1)
 return np.array(im)

def spring(phase):
 im=Image.new('L',(16,12));d=ImageDraw.Draw(im)
 d.rectangle((0,0,15,2),fill=2);d.line((1,0,14,0),fill=4)
 d.line((2,4,12,5,3,7,12,9,3,11),fill=3 if phase==0 else 2)
 return np.array(im)

def trampoline():
 im=Image.new('L',(16,10));d=ImageDraw.Draw(im)
 d.ellipse((0,0,15,4),fill=4);d.line((2,1,13,1),fill=2);d.line((1,4,3,9),fill=2);d.line((14,4,12,9),fill=2);d.line((4,9,11,9),fill=1)
 return np.array(im)

def bag():
 im=Image.new('L',(8,14));d=ImageDraw.Draw(im)
 d.polygon([(1,0),(6,0),(5,3),(7,6),(7,11),(5,13),(1,13),(0,10),(0,6),(2,3)],fill=3)
 d.line((2,5,2,10),fill=4);d.line((4,5,4,10),fill=4);d.line((1,7,5,7),fill=4);d.line((1,9,5,9),fill=4)
 return np.array(im)

def dolphin(phase):
 im=Image.new('L',(16,24));d=ImageDraw.Draw(im)
 # Upright and inverted poses follow the four arcade flight phases.
 pts=[(0,19),(3,14),(4,9),(8,5),(10,3),(11,7),(15,9),(14,12),(10,11),(8,15),(6,20),(8,23),(3,21),(0,23)]
 d.polygon(pts,fill=4);d.line((6,17,7,13,9,10),fill=2,width=1);d.point((9,8),fill=1)
 a=np.array(im)
 if phase==1:a=np.array(Image.fromarray(a).rotate(-45,Image.Resampling.NEAREST,expand=False))
 if phase==2:a=np.flipud(a).copy()
 if phase==3:a=np.flipud(dolphin(1)).copy()
 return a

def actors(legacy,names):
 ims=list(legacy)
 for i,b in enumerate((0,4,8,25,57,61,41,37)):ims[i]=charlie(b,i)
 for i in range(3):ims[11+i]=horse(i)
 for i in range(4):
  a=np.zeros((30,20),np.uint8)
  for y in range(30):
   for x in range(20):
    dx=(x-9.5)/7.5;dy=(y-14.5)/14.5
    if dx*dx+dy*dy<=1:
     sector=int(((math.atan2(dy,dx)+i*math.pi/7)%(2*math.pi))/(math.pi/3))
     a[y,x]=[2,1,4,3,2,4][sector]
     if dx<-.3 and dy<-.4:a[y,x]=2
  ims[14+i]=a
 for i in range(9):ims[84+i]=arcade_actor(J if i%3==2 else H[i//3],24,32,84+i)
 for phase in range(2):
  im=Image.new('L',(8,28));d=ImageDraw.Draw(im)
  for j in range(3):
   x=1+j*3;top=2+(j*5+phase*4)%11
   d.polygon([(x-1,27),(x-2,16),(x+1,top),(x,15),(x+2,27)],fill=1)
   d.polygon([(x,26),(x+1,top+6),(x+1,26)],fill=3)
  d.line((2,25,5,25),fill=2);ims[82+phase]=np.array(im)
 ims[93]=trampoline();ims[94]=bag()
 a=Image.new('L',(32,4));d=ImageDraw.Draw(a);d.rectangle((0,0,31,1),fill=4);d.line((0,2,31,2),fill=2);d.line((0,3,31,3),fill=1);ims[95]=np.array(a)
 for label,frames in [('hoop',[hoop(i) for i in range(4)]),('pot',[pot(i) for i in range(2)]),('brown-monkey',[monkey(i) for i in range(4)]),('pink-monkey',[monkey(i,True) for i in range(4)]),('spring',[spring(i) for i in range(2)]),('dolphin',[dolphin(i) for i in range(4)])]:
  for i,a in enumerate(frames):
   if label=='dolphin':
    a=a.copy();a[a==4]=0
   if label=='pink-monkey':
    face=np.zeros_like(a);face[4:11,:7]=a[4:11,:7];face[face==3]=0;a=face
   if label=='spring':a=a.copy();a[3:]=0
   names.append(label+'-'+str(i));ims.append(a)
 return ims,names

def scene(act):
 im=Image.new('L',(160,176));d=ImageDraw.Draw(im)
 high=act in (1,5);crowd_y=104 if high else 24
 if not high:
  # Cell-aligned stripes keep cyan/gold detail inside legal ANTIC-4 cells.
  for x in range(40,112,4):d.polygon([(76,1),(x,18),(x+3,18)],fill=3 if x%8==0 else 4)
  for x in range(36,116,4):d.rectangle((x,18,x+3,23),fill=3 if x%8==0 else 4)
  d.line((76,0,76,5),fill=2);d.rectangle((77,0,82,2),fill=3)
  d.ellipse((128,1,150,22),outline=2)
  for n in range(8):
   t=n*math.pi/4;x=round(139+10*math.cos(t));y=round(12+10*math.sin(t));d.line((139,12,x,y),fill=2);d.rectangle((x-1,y-1,x+1,y+1),fill=3 if n&1 else 4)
  d.line((132,23,139,12,146,23),fill=2)
  d.line((8,5,20,5),fill=2,width=2);d.line((23,12,29,12),fill=2)
 else:
  # Rigging stays clear behind a jumping acrobat or moving trapeze.
  d.line((0,0,159,0),fill=3);d.line((0,2,159,2),fill=2)
  # Uniform rigging lines are baked into the prepared rope cells.
 for row in range(4):
  y=crowd_y+row*8
  for x in range(0,160,4):
   d.rectangle((x+1,y+1,x+2,y+2),fill=2)
   d.rectangle((x,y+3,x+3,y+4),fill=3 if (x//4+row)%2 else 4)
   d.point((x+1,y+6),fill=1)
 for x in (16,100,144):
  d.rectangle((x,crowd_y,x+3,crowd_y+31),fill=2)
  for y in range(crowd_y+6,crowd_y+32,8):d.line((x,y,x+3,y),fill=1)
 y=crowd_y+32
 for x in range(0,160,16):d.polygon([(x,y+12),(x+6,y+2),(x+8,y+8),(x+14,y+12)],fill=3)
 # A small red-curtained entrance; its palette stays stable while scrolling.
 if not high:
  d.rectangle((48,44,67,71),fill=1);d.rectangle((52,50,63,71),fill=0)
  for x in range(48,68,4):d.rectangle((x,44,x+3,49),fill=3 if x%8==0 else 4)
  d.ellipse((55,55,60,61),fill=2);d.rectangle((56,61,59,70),fill=2)
  d.line((0,72,159,72),fill=3)
  if act==0:
   d.rectangle((0,72,159,75),fill=4);d.line((0,73,159,73),fill=2)
 if act==1:d.line((0,96,159,96),fill=3);d.line((0,97,159,97),fill=1)
 if act==6:
  for y in (164,170,174):
   for x in range(0,160,8):d.line((x,y,x+4,y),fill=2 if y==164 else 4)
 elif act not in (1,5):
  d.line((0,166,159,166),fill=1)
 return np.array(im),crowd_y//8

def tile_bytes(tile):
 t=tile.copy();alt=np.count_nonzero(t==4)>np.count_nonzero(t==3)
 t[t==(3 if alt else 4)]=2;t[t==4]=3
 return bytes(sum(int(v)<<(6-2*j) for j,v in enumerate(line)) for line in t),int(alt)*128

def backgrounds():
 result=[]
 for act in range(7):
  a,cy=scene(act);fonts=[];maps=[];counts=[]
  for y0,y1 in (((0,8),(8,20),(20,22)) if act==2 else ((0,8),(8,17),(17,22))):
   unique={bytes(8):0}
   for row in range(y0,y1):
    for col in range(40):
     b,alt=tile_bytes(a[row*8:row*8+8,col*4:col*4+4])
     if b not in unique:unique[b]=len(unique)
     maps.append(unique[b]|alt)
   counts.append(len(unique));fonts.extend(b''.join(unique).ljust(1024,b'\0'))
  assert max(counts)<100,(act,counts)
  data=bytearray([255])*16384;data[:3072]=bytes(fonts);data[3072:3952]=bytes(maps)
  for shift in range(40):
   part=bytearray()
   for y in range(cy,cy+4):
    row=maps[y*40:y*40+40];part.extend(row[shift:]+row[:shift])
   data[4096+shift*160:4096+(shift+1)*160]=part
  result.append((data,counts,cy))
 return result

def install_resident(bg,act,im,top,write_records=True,shifts=(0,1,2,3)):
 data,counts,_=bg[act]
 unique=[]
 for band in range(3):
  unique.append({bytes(data[band*1024+i*8:band*1024+i*8+8]):i for i in range(counts[band])})
 records=[]
 for sx in range(4):
  if sx not in shifts:
   records.append(b'');continue
  a=np.zeros((((im.shape[0]+top%8+7)//8)*8,((im.shape[1]+sx+3)//4)*4),np.uint8)
  a[top%8:top%8+im.shape[0],sx:sx+im.shape[1]]=im
  record=bytearray()
  for y in range(a.shape[0]//8):
   row=top//8+y;band=0 if row<8 else 1 if row<(20 if act==2 else 17) else 2
   for x in range(a.shape[1]//4):
    t=a[y*8:y*8+8,x*4:x*4+4].copy()
    if not np.any(t):continue
    old=data[3072+row*40+x];base=np.array([[(v>>shift)&3 for shift in (6,4,2,0)] for v in data[band*1024+(old&127)*8:band*1024+(old&127)*8+8]],np.uint8)
    if old&128:base[base==3]=4
    t[t==0]=base[t==0]
    b,alt=tile_bytes(t);u=unique[band]
    if b not in u:
     code=len(u);u[b]=code;assert code<128,(act,band,code)
     data[band*1024+code*8:band*1024+code*8+8]=b
    record.extend((x,row,u[b]|alt))
  assert len(record)<(128 if write_records else 768),(act,len(record))
  records.append(bytes(record))
  if write_records:data[0x2a00+sx*128:0x2a00+sx*128+1+len(record)]=bytes([len(record)//3])+record
 for i in range(3):counts[i]=len(unique[i])
 return records
