"""Additional original reward pixels; never rewrite approved prepared assets."""
from pathlib import Path
import hashlib,json,re
import numpy as np
from act3_assets import tile,convert
from bold_art import tile_bytes
ROOT=Path(__file__).resolve().parents[1]
def compile_pixels(data,labels):
 code=bytearray();jumps=[];local={}
 def byte(*values):code.extend(values)
 def call(name):a=labels[name];byte(0x20,a&255,a>>8)
 def jump(name):jumps.append((len(code)+1,name));byte(0x4c,0,0)
 def mark(name):local[name]=len(code)
 def rows(pixels,kind):
  accumulator=None
  for y,pixel in enumerate(pixels):
   mask=sum(3<<shift for shift in(0,2,4,6)if not pixel&(3<<shift));byte(0xa0,y)
   if kind!='blank'and mask:
    byte(0xb1,labels['z_bg'])
    if kind=='inverse':byte(0xaa,0xbd,0x00,0x7c)
    if mask!=255:byte(0x29,mask)
    if pixel:byte(0x09,pixel)
    accumulator=None
   else:
    if accumulator!=pixel:byte(0xa9,pixel)
    accumulator=pixel
   byte(0x91,labels['z_glyph'])
 oldrow=-1
 for i in range(len(data)//10):
  flags,y=data[i*10:i*10+2];x=flags&31;flags&=192;pixels=data[i*10+2:i*10+10]
  if y!=oldrow:byte(0xa9,y);call('compiled_actor_row');byte(0x90,3);jump('end');oldrow=y
  byte(0xa9,x,0xa2,flags);call('compiled_regular_cell');byte(0x90,3);jump(f'next-{i}')
  if flags&64:rows(pixels,'blank')
  else:
   byte(0xd0,3);jump(f'blank-{i}');byte(0xc9,2,0xd0,3);jump(f'inverse-{i}')
   rows(pixels,'normal');jump(f'next-{i}');mark(f'inverse-{i}');rows(pixels,'inverse');jump(f'next-{i}');mark(f'blank-{i}');rows(pixels,'blank')
  mark(f'next-{i}')
 mark('end');byte(0x68,0xa8,0x68,0xaa,0x60)
 return code,jumps,local

def build():
 # $EF1C / $7827: hardware flip-Y ($80) becomes horizontal after ROT90.
 # tile() already returns oriented pixels. Keep the recorded quadrants.
 extra=convert(np.block([[np.fliplr(tile(0x42)),np.fliplr(tile(0x41))],
                         [np.fliplr(tile(0x44)),np.fliplr(tile(0x43))]]),24,32)
 codes=(0x143,0x142,0x141,0x140,0x150,0x151,0x152,0x151,0x150,0x140,0x141,0x142)
 images=[extra]+[convert(np.fliplr(tile(code))if i>=7 else tile(code),12,16)for i,code in enumerate(codes)]
 directory=bytearray(13*128);banks=[bytearray([255])*16384];used=0;unique={};variants=[];payloads=[]
 for pose,im in enumerate(images):
  for sx in range(4):
   for sy in range(8):
    yy=6 if pose==0 else sy
    a=np.zeros((((im.shape[0]+yy+7)//8)*8,((im.shape[1]+sx+3)//4)*4),np.uint8)
    a[yy:yy+im.shape[0],sx:sx+im.shape[1]]=im
    data=bytearray()
    for y in range(a.shape[0]//8):
     for x in range(a.shape[1]//4):
      cell=a[y*8:y*8+8,x*4:x*4+4]
      if not np.any(cell):continue
      pixels,alt=tile_bytes(cell)
      data+=bytes((x|alt|(64 if np.all(cell)else 0),y))+pixels
    data=bytes(data);payloads.append(data)
    if data not in unique:
     if used+len(data)>0x3f00:banks.append(bytearray([255])*16384);used=0
     b=242+len(banks);address=0x8000+used
     banks[-1][used:used+len(data)]=data;used+=len(data);unique[data]=(b,address)
    b,address=unique[data];count=len(data)//10;off=pose*128+(sx*8+sy)*4
    directory[off:off+4]=bytes((b,address&255,address>>8,count))
    variants.append(dict(pose=pose,x_phase=sx,y_phase=sy,cells=count,bank=b,address=address))
 np.savez_compressed(ROOT/'build/hidden-reward-pixels.npz',**{f'pose{i}':a for i,a in enumerate(images)})
 labels={m[2]:int(m[1],16)for l in (ROOT/'build/main.lbl').read_text().splitlines()if(m:=re.match(r'al ([0-9A-F]+) \.(.+)',l))}
 labels.update((n,int(v,16))for n,v in re.findall(r'^(\w+)=\$([0-9A-Fa-f]+)',(ROOT/'src/memory.inc').read_text(),re.M))
 helper=(ROOT/'build/actor-helper.bin').read_bytes();compiled=bytearray(len(directory));programs={};used=0x3800;first_compiled=0;compiled_banks=[]
 for i,data in enumerate(payloads):
  if data not in programs:
   code,jumps,local=compile_pixels(data,labels)
   if used+len(code)>0x3800:compiled_banks.append(bytearray([255])*16384);compiled_banks[-1][0x3800:0x3f00]=helper;used=0
   b=len(compiled_banks)-1;address=0x8000+used
   assert b<32,('Reward compiler exhausted free banks',b)
   for at,label in jumps:code[at:at+2]=(address+local[label]).to_bytes(2,'little')
   compiled_banks[-1][used:used+len(code)]=code;used+=len(code);programs[data]=(b,address)
  b,address=programs[data];compiled[i*4:i*4+4]=bytes((b,address&255,address>>8,len(data)//10))
 report=dict(first_compiled_bank=first_compiled,last_compiled_bank=len(compiled_banks)-1,compiled_programs=len(programs),code_bank=242,first_art_bank=243,last_art_bank=242+len(banks),
  original_pixels_sha256=hashlib.sha256((ROOT/'assets/arcade-sprites.npz').read_bytes()).hexdigest(),
  variants=variants,approved_assets_changed=False)
 (ROOT/'build/hidden-reward-art.json').write_text(json.dumps(report,indent=2)+'\n')
 return directory,compiled,banks,compiled_banks
