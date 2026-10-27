"""Arcade Act 3 actors, attack tables and prepared graphics (no runtime scaling)."""
from pathlib import Path
import json
import numpy as np
from PIL import Image,ImageDraw
R=Path(__file__).resolve().parents[1]
A=np.load(R/'assets/arcade-sprites.npz')
def convert(src,w,h):
 src=np.array(Image.fromarray(src).resize((w,h),Image.Resampling.NEAREST))
 a=np.zeros_like(src);a[np.isin(src,[1,3,11,12,15])]=2;a[np.isin(src,[2,8])]=1;a[np.isin(src,[7,13])]=3;a[np.isin(src,[9,10])]=4
 return a

def tile(code,pal=0):return A['lookup'][pal,A['pixels'][code]]

TRAMP_HERO_IDS=(96,97,98,99,42,43,117,118)

def hero_poses():
 # Original 32x32 sprite quadrants, without cropping/stretching the body.
 # Horizontal movement uses the six poses observed in MAME at phases
 # 0,1,6,11,16,21 (returning upright at 26). Neutral jumps raise both arms.
 frames=[]
 for base,flip in ((25,False),(149,False),(153,False),(161,False),(165,False),(161,True)):
  q=np.block([[tile(base),tile(base+1)],[tile(base+2),tile(base+3)]])
  if flip:q=np.flip(q,(0,1))
  frames.append(convert(q,24,32))
 for base in (315,311):
  frames.append(convert(np.block([[tile(base),np.fliplr(tile(base))],
                                  [tile(base+1),np.fliplr(tile(base+1))]]),24,32))
 return frames

def hero_contacts():
 # Exact displayed body/blade overlap, retaining the one-pixel fringe.
 # Share run-length encoded dy rows: this fits all eight poses into 3 KB.
 art={};sprites(art,{})
 rows=[];patterns={}
 for h in hero_poses():
  solid=h!=0;body=np.zeros_like(solid)
  body[1:-1,1:-1]=(solid[1:-1,1:-1]&solid[:-2,1:-1]&solid[2:,1:-1]
                    &solid[1:-1,:-2]&solid[1:-1,2:])
  for kind in range(5):
   if kind==0:
    proj=art[82]!=0;bias=31;parity=0
   else:
    flip=(kind-1)//2;parity=(kind-1)%2;bias=15
    proj=np.zeros((16,8),bool);proj[:,parity:parity+6]=art[110+flip]!=0
    proj=proj.reshape(16,4,2).any(axis=2).repeat(2,axis=1)
   py,px=np.nonzero(proj);px=px-parity
   for dx in range(-7,25):
    flags=[]
    for dy in range(-bias,32):
     valid=(py+dy>=0)&(py+dy<32)&(px+dx>=0)&(px+dx<24)
     flags.append(bool(body[(py+dy)[valid],(px+dx)[valid]].any()))
    encoded=[];start=None
    for i,hit in enumerate(flags+[False]):
     if hit and start is None:start=i
     elif not hit and start is not None:encoded.extend((start,i));start=None
    key=bytes(encoded+[255]);patterns.setdefault(key,None);rows.append(key)
 # All run records fit in $AB80..$AFFF. Store each absolute pointer as a
 # low byte plus a shared high nibble, avoiding 640 redundant high bytes.
 data=bytearray(len(rows)*3//2)
 for key in patterns:patterns[key]=0xa400+len(data);data.extend(key)
 for i,key in enumerate(rows):
  addr=patterns[key];data[i]=addr&255
  data[len(rows)+i//2]|=((addr>>8)&15)<<((i&1)*4)
 assert len(data)<=3072,('Trampoline contact cache',len(data))
 (R/'assets/trampoline-hero-contacts.bin').write_bytes(data.ljust(3072,b'\xff'))
 text='; Generated original-pose contact row directories in bank 26.\n'
 text+='tramp_contact_lo: .byte '+','.join(str((0xa400+i*32)&255)for i in range(40))+'\n'
 text+='tramp_contact_hi: .byte '+','.join(str((0xa400+i*32)>>8)for i in range(40))+'\n'
 text+='tramp_contact_bits_lo: .byte '+','.join(str((0xa900+i*16)&255)for i in range(40))+'\n'
 text+='tramp_contact_bits_hi: .byte '+','.join(str((0xa900+i*16)>>8)for i in range(40))+'\n'
 text+='tramp_hero_ids: .byte '+','.join(map(str,TRAMP_HERO_IDS))+'\n'
 (R/'src/trampoline-hero-tables.inc').write_text(text)
 print('Trampoline body contacts:',len(data),'bytes')
def performer(base,flip=False):
 parts=[tile(256+base-2+i) for i in range(4)]
 if flip:parts=[np.flipud(p) for p in parts]
 return convert(np.block([[parts[0],parts[1]],[parts[2],parts[3]]]),16,32)
def sprites(ims,names):
 for pid,base,flip in [(96,10,False),(97,14,False),(98,2,False),(99,6,False),(100,7,True),(101,2,False)]:
  # Mirror frame is assembled explicitly so adjacent quadrant order is retained.
  if pid==100:
   parts=[np.flipud(tile(256+i))for i in (7,6,5,4)]
   ims[pid]=convert(np.block([[parts[2],parts[3]],[parts[0],parts[1]]]),16,32)
  else:ims[pid]=performer(base,flip)
  names[pid]='act3-performer-'+str(pid-96)
 for pid,pal in [(82,3),(83,4)]:
  # MAME puts code 110 above code 111: the flame head leads its trailing tip.
  ims[pid]=convert(np.concatenate([tile(272,pal),tile(273,pal)]),8,32);names[pid]='act3-fire-'+str(pid-82)
 for pid,flip in [(110,False),(111,True)]:
  src=tile(203,7)
  if flip:src=np.flipud(src)
  ims[pid]=convert(src,6,16);names[pid]='act3-sword-'+str(pid-110)
 return ims,names

def pedestal(width=24):
 im=Image.new('L',(width,48));d=ImageDraw.Draw(im)
 d.rectangle((0,6,width-1,47),fill=4)
 for x in range(3,width,8):d.rectangle((x,6,min(width-1,x+3),47),fill=2)
 d.rectangle((0,0,width-1,5),fill=3)
 d.line((0,0,width-1,0),fill=2)
 for x in range(0,width,4):d.line((x,4,x+2,1,min(width-1,x+3),4),fill=1)
 return np.array(im)

def tables():
 d=json.loads((R/'assets/act3-arcade.json').read_text());s='; Extracted arcade Act 3 schedules and exact integer projectile integrators.\n'
 def put(name,a):
  nonlocal s;s+=name+': .byte '+','.join(str(x) for x in a)+'\n'
 positions=[page*192+(v+239)*3//4 for page in range(8) for v in (62,142,234)]
 triggers=[p-119 for p in positions]
 for name,seq in [('t_positions',positions),('t_triggers',triggers)]:
  put(name+'_lo',[v&255 for v in seq]);put(name+'_hi',[v>>8 for v in seq])
 for rank in range(6):
  # Begin with the original Easy first-wave map described by the arcade
  # guide. Each repeat advances one original schedule, including double throws.
  schedule=sum(d['schedules'][rank][1:9],[])
  put('t_schedule_'+str(rank),schedule)
 put('t_schedule_lo',['<t_schedule_'+str(i)for i in range(6)])
 put('t_schedule_hi',['>t_schedule_'+str(i)for i in range(6)])
 intervals=d['intervals'][:6]
 put('t_intervals',intervals)
 # Fire waits eight ticks at the mouth, then rises by the high byte of $0400,
 # subtracting $0010 each tick. It vanishes eight ticks after velocity < $0100.
 y=210;v=0x400;fire=[y]*8
 while v>=0x100:
  y-=v>>8;v-=0x10;fire.append(y)
 fire += [y]*8
 # A sword has the same initial speed/gravity, descends, and is caught again.
 y=208;v=0x400;sword=[]
 while v>=0x100:y-=v>>8;v-=0x10;sword.append(y)
 sword.append(y);v=0
 for i in range(64):y+=v>>8;v+=0x10;sword.append(y)
 put('t_fire_y',fire);put('t_sword_y',sword)
 s+='T_FIRE_LENGTH='+str(len(fire))+'\nT_SWORD_LENGTH='+str(len(sword))+'\n'
 (R/'src/act3-tables.inc').write_text(s)
 if __name__=='__main__':print('Act 3 table lengths',len(fire),len(sword))
def sword_masks():
 data=bytearray()
 for drift in range(12):
  for flip in (False,True):
   src=tile(203,7)
   if flip:src=np.flipud(src)
   sword=convert(src,6,16)!=0
   canvas=np.zeros((16,16),bool)
   for y,x in zip(*np.nonzero(sword)):canvas[y,x+drift]=True
   data.extend(sum(int(np.any(row[x*2:x*2+2]))<<(7-x) for x in range(8)) for row in canvas)
 (R/'assets/act3-sword-masks.bin').write_bytes(data)
if __name__=='__main__':tables();sword_masks();hero_contacts()

def bags(bg,im,water=False):
 # Crowd and prize share the camera, so the exact background under each
 # shifted prize is fixed in world space. Preserve generic stamp pixels.
 from bold_art import tile_bytes
 data=bytearray(200);unique={};fonts=bg[6 if water else 0][0]
 for i in range(25):
  world=(48 if water else 52)+(i//3)*192+(i%3)*66
  for sx in range(4):
   a=np.zeros((16,12),np.uint8);a[:14,sx:sx+8]=im
   record=bytearray()
   for row in range(2):
    for col in range(3):
     tile=a[row*8:row*8+8,col*4:col*4+4]
     if not tile.any():continue
     fg,alt=tile_bytes(tile)
     old=fonts[3072+(6+row)*40+(((world-sx)//4+col)%40)]
     bgbytes=fonts[(old&127)*8:(old&127)*8+8]
     if (old^alt)&128:bgbytes=bytes(v & ~(v>>1&0x55) for v in bgbytes)
     pixels=bytes(b & sum(3<<sh for sh in (0,2,4,6) if not f&(3<<sh)) | f for b,f in zip(bgbytes,fg))
     record.extend((col|alt,6+row));record.extend(pixels)
   blob=bytes([len(record)//10])+record
   if blob not in unique:unique[blob]=len(data);data.extend(blob)
   addr=(0x9000 if water else 0xa000)+unique[blob];offset=(i*4+sx)*2;data[offset:offset+2]=bytes((addr&255,addr>>8))
 assert len(data)<=(1536 if water else 4096),len(data)
 (R/('assets/water-bags.bin' if water else 'assets/act3-bags.bin')).write_bytes(data.ljust(2048 if water else 4096,b'\xff'))
 print('Act 3 exact prize cache:',len(data),'bytes')
