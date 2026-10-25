"""Pack the title into unused tightrope font capacity; no gameplay glyph changes."""
from pathlib import Path
from PIL import Image
import numpy as np,json
ROOT=Path(__file__).resolve().parents[1]

def packbits(data):
 out=bytearray();i=0
 while i<len(data):
  run=1
  while i+run<len(data) and data[i+run]==data[i] and run<127:run+=1
  if run>=3:out.extend((128|run,data[i]));i+=run;continue
  start=i;i+=run
  while i<len(data) and i-start<127:
   run=1
   while i+run<len(data) and data[i+run]==data[i] and run<3:run+=1
   if run>=3:break
   i+=min(run,127-(i-start))
  out.append(i-start);out.extend(data[start:i])
 out.append(0);return out

def install(rom,bg):
 a=np.array(Image.open(ROOT/'assets/title-art.png'));fonts=bytearray();screen=bytearray();counts=[]
 for first,last in ((0,8),(8,17),(17,22)):
  patterns=[bytes(8)];codes={bytes(8):0}
  for row in range(first,last):
   for col in range(40):
    tile=a[row*8:row*8+8,col*4:col*4+4]
    p=bytes(sum(int(v)<<(6-2*x) for x,v in enumerate(scan)) for scan in tile)
    if p not in codes:codes[p]=len(patterns);patterns.append(p)
    screen.append(codes[p])
  counts.append(len(patterns));assert len(patterns)<=117,counts
  data=bytearray(b''.join(patterns)).ljust(1024,b'\0')
  # Small stars move in two-pixel steps; the three large sparkle poses alternate.
  for i in range(11):
   tile=np.zeros((8,4),np.uint8)
   if i<3:
    y=i*2;tile[y+1,:]=2;tile[y:y+4,1:3]=2
   else:
    phase=i-3;x=(phase&1)*2;y=(phase>>1)*2;tile[y:y+2,x:x+2]=2
   p=bytes(sum(int(v)<<(6-2*x) for x,v in enumerate(scan)) for scan in tile)
   data[(117+i)*8:(118+i)*8]=p
  fonts.extend(data)
 raw=fonts+screen.ljust(1024,b'\0');encoded=packbits(raw)
 ranges=[(0x10,0x400),(0x5c0,0x800),(0x878,0xc00),(0xf70,0x1000)]
 assert all(lo>=i*1024+bg[1][1][i]*8 for i,(lo,hi) in enumerate(ranges[:3]))
 assert ranges[3][0]>=3072+880
 assert len(encoded)<=sum(b-a for a,b in ranges),(len(encoded),counts)
 n=0
 for lo,hi in ranges:
  block=encoded[n:n+hi-lo];rom[2][lo:lo+len(block)]=block;n+=len(block)
 (ROOT/'assets/title-info.json').write_text(json.dumps(dict(font_counts=counts,compressed_bytes=len(encoded),star_count=32,storage_bank=2,storage_ranges=ranges),indent=2))
 print('Title:',len(encoded),'bytes; glyph counts',counts)
