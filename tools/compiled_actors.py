"""Compile immutable prepared hero cells, preserving runtime backgrounds.

Unlike the fixed-coordinate Trapeze writer, these programs calculate map/font
addresses at runtime and share each phase across both buffers and all Y rows.
"""
from pathlib import Path
import hashlib,json,re
ROOT=Path(__file__).resolve().parents[1]
POSES=(1,2,3,4,96,97,98,99,42,43,117,118)

def build():
 rom=(ROOT/'assets/asset-banks.bin').read_bytes()
 labels={m[2]:int(m[1],16)for l in (ROOT/'build/main.lbl').read_text().splitlines()if(m:=re.match(r'al ([0-9A-F]+) \.(.+)',l))}
 labels.update((name,int(value,16))for name,value in re.findall(r'^(\w+)=\$([0-9A-Fa-f]+)',(ROOT/'src/memory.inc').read_text(),re.M))
 helper=(ROOT/'build/actor-helper.bin').read_bytes();assert len(helper)==0x700
 banks=[bytearray([255])*16384];banks[0][:0x400]=(ROOT/'build/actor-dispatch.bin').read_bytes()
 banks[0][0xf00:0x1000]=bytes([255])*256
 for i,p in enumerate(POSES):banks[0][0xf00+p]=i
 bank=0;position=0;unique={};variants=[]
 for slot,pose in enumerate(POSES):
  dense=slot<4
  for sx in range(4):
   for sy in range(8):
    off=7*16384+pose*128+(sx*8+sy)*4
    source,lo,hi,count=rom[off:off+4];off=source*16384+lo+(hi-128)*256
    cells=[]
    if dense:
     pixels=off+rom[off];w,h=rom[off+1:off+3];index=0
     for y in range(h):
      for x in range(w):
       desc=rom[off+3+y*w+x]
       if desc:
        cells.append((x,y,desc&192,rom[pixels+index*8:pixels+(index+1)*8]));index+=1
    else:
     for i in range(count):
      x,y=rom[off+i*10:off+i*10+2];assert not x&32
      cells.append((x&31,y,x&192,rom[off+i*10+2:off+i*10+10]))
    key=(dense,tuple(cells))
    if key not in unique:
     code=bytearray();jumps=[];local={}
     def byte(*values):code.extend(values)
     def absop(op,address):byte(op,address&255,address>>8)
     def call(name):absop(0x20,labels[name])
     def jump(name):jumps.append((len(code)+1,name));byte(0x4c,0,0)
     def mark(name):local[name]=len(code)
     def rows(pixels,kind):
      for line,pixel in enumerate(pixels):
       mask=sum(3<<shift for shift in(0,2,4,6)if not pixel&(3<<shift))
       byte(0xa0,line)
       if kind!='blank'and mask:
        byte(0xb1,labels['z_bg'])
        if kind=='inverse':byte(0xaa,0xbd,0x00,0x7c)
        if mask!=255:byte(0x29,mask)
        if pixel:byte(0x09,pixel)
       else:byte(0xa9,pixel)
       byte(0x91,labels['z_glyph'])
     oldrow=-1
     for i,(x,y,flags,pixels)in enumerate(cells):
      if y!=oldrow:
       byte(0xa9,y);call('compiled_actor_row');byte(0x90,3);jump('end');oldrow=y
      byte(0xa9,x,0xa2,flags);call('compiled_dense_cell'if dense else'compiled_regular_cell')
      if not dense:byte(0x90,3);jump(f'next-{i}')
      if flags&64:rows(pixels,'blank')
      else:
       byte(0xd0,3);jump(f'blank-{i}')
       byte(0xc9,2,0xd0,3);jump(f'inverse-{i}')
       rows(pixels,'normal');jump(f'next-{i}')
       mark(f'inverse-{i}');rows(pixels,'inverse');jump(f'next-{i}')
       mark(f'blank-{i}');rows(pixels,'blank')
      mark(f'next-{i}')
     mark('end')
     if not dense:byte(0x68,0xa8,0x68,0xaa)
     byte(0x60)
     assert len(code)<=0x3800
     if bank==0 or position+len(code)>0x3800:
      bank+=1;position=0;banks.append(bytearray([255])*16384)
      banks[bank][0x3800:0x3f00]=helper
     assert 176+bank<253,('Compiled actors exceed free banks',bank)
     address=0x8000+position
     for at,label in jumps:code[at:at+2]=(address+local[label]).to_bytes(2,'little')
     banks[bank][position:position+len(code)]=code;position+=len(code)
     unique[key]=(176+bank,address,len(code))
    b,address,size=unique[key]
    entry=0x1000+slot*128+(sx*8+sy)*4
    banks[0][entry:entry+4]=bytes((address&255,address>>8,b,0))
    variants.append(dict(pose=pose,sx=sx,sy=sy,bank=b,address=address,bytes=size,dense=dense))
 report=dict(first_bank=176,last_bank=176+bank,allocated_banks=len(banks),directory_entries=len(variants),unique_programs=len(unique),
  source_sha256=hashlib.sha256(rom).hexdigest(),artwork_changed=False,variants=variants)
 (ROOT/'build/compiled-actors.json').write_text(json.dumps(report,indent=2)+'\n')
 return banks
