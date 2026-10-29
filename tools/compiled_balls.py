"""Constant-pixel ball merging; unchanged approved four-phase font bytes."""
from pathlib import Path
import hashlib,json
ROOT=Path(__file__).resolve().parents[1]
def build():
 source=(ROOT/'assets/asset-banks.bin').read_bytes();drawer=(ROOT/'build/ball-draw.bin').read_bytes();assert len(drawer)==0x800
 banks=[];sizes=[];programs=0
 for phase in range(4):
  bank=bytearray([255])*16384;bank[:0x800]=drawer;pos=0x1000;seen={}
  for glyph in range(66):
   pixels=source[31*16384+phase*1024+glyph*8:31*16384+phase*1024+glyph*8+8]
   for inverse in(0,1):
    code=bytearray()
    for row,pixel in enumerate(pixels):
     mask=sum(3<<shift for shift in(0,2,4,6)if not pixel&(3<<shift))
     code.extend((0xa0,row))
     if mask:
      code.extend((0xb1,0xb0))
      if inverse:code.extend((0xaa,0xbd,0x00,0x7c))
      if mask!=255:code.extend((0x29,mask))
      if pixel:code.extend((0x09,pixel))
     else:code.extend((0xa9,pixel))
     code.extend((0x91,0xb2))
    code.append(0x60);key=bytes(code)
    if key not in seen:
     assert pos+len(code)<=0x3f00,(phase,'Ball writers exceed bank')
     seen[key]=0x8000+pos;bank[pos:pos+len(code)]=code;pos+=len(code);programs+=1
    address=seen[key];base=0x800+inverse*0x200
    bank[base+glyph]=address&255;bank[base+0x100+glyph]=address>>8
  banks.append(bank);sizes.append(pos)
 report=dict(first_bank=238,last_bank=241,phase_banks=4,glyphs_per_phase=66,palette_paths=2,unique_programs=programs,
  used_bytes=sizes,source_sha256=hashlib.sha256(source).hexdigest(),artwork_changed=False)
 (ROOT/'build/compiled-balls.json').write_text(json.dumps(report,indent=2)+'\n');return banks
