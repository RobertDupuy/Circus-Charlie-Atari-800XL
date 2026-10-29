"""Compile the approved hero against arbitrary current background glyphs.

Only the common X=52, Y=0..138 poses use this path. Every pixel, inverse-colour
conversion, glyph destination and map code agrees with the generic renderer.
"""
from pathlib import Path
import json,re
ROOT=Path(__file__).resolve().parents[1]

def build():
    rom=(ROOT/'assets/asset-banks.bin').read_bytes()
    common=(ROOT/'assets/common.bin').read_bytes()
    counts=common[0xdc0+15:0xdc0+18]
    assert list(counts)==[74,12,69]
    labels={m[2]:int(m[1],16)for l in (ROOT/'build/main.lbl').read_text().splitlines()if (m:=re.match(r'al ([0-9A-F]+) \.(.+)',l))}
    banks=[bytearray([255])*16384,bytearray([255])*16384];bi=1;pos=0;programs=0
    def ins(op,addr):return bytes((op,addr&255,addr>>8))
    for pose in (3,4):
      for back in range(2):
       directory=((pose-3)*2+back)*1024
       for y in range(139):
        off=7*16384+pose*128+(y%8)*4
        b,lo,hi,count=rom[off:off+4];off=b*16384+lo+(hi-128)*256
        payload=off+rom[off];w,h=rom[off+1:off+3]
        cells=rom[off+3:off+3+w*h];index=0;starts={};code=bytearray()
        for row in range(h):
         screenrow=y//8+row
         if screenrow>=22:break
         band=0 if screenrow<8 else 1 if screenrow<17 else 2
         starts.setdefault(band,index)
         font=0x4000+back*3072+band*1024
         for col in range(w):
          desc=cells[row*w+col]
          if not desc:continue
          glyph=counts[band]+index-starts[band]
          assert glyph<128
          dst=font+glyph*8;mapaddr=0x3800+back*1024+screenrow*40+13+col
          pixels=rom[payload+index*8:payload+(index+1)*8];index+=1
          flags=desc&128
          def rows(alt):
           out=bytearray()
           for line,pixel in enumerate(pixels):
            mask=sum(3<<shift for shift in (0,2,4,6)if not(pixel&(3<<shift)))
            if mask and not desc&64:
             out.extend((0xa0,line,0xb1,0xb0))
             if alt:out.extend((0xaa,0xbd,0x00,0x7c))
             if mask!=255:out.extend((0x29,mask))
             if pixel:out.extend((0x09,pixel))
            else:out.extend((0xa9,pixel))
            out.extend(ins(0x8d,dst+line))
           return out
          if desc&64:code.extend(rows(False))
          else:
           code.extend(ins(0xad,mapaddr));code.extend((0x29,127,0xaa))
           code.extend(ins(0xbd,labels['glyph_lo']));code.extend((0x85,0xb0))
           code.extend(ins(0xbd,labels['glyph_hi']));code.extend((0x09,font>>8,0x85,0xb1))
           normal=rows(False);alternate=rows(True)
           # The local branch skips a JMP, so merged row blocks need no
           # signed-branch length restriction. Absolute targets fixed below.
           code.extend(ins(0x2c,mapaddr));code.extend((0x30 if flags else 0x10,3))
           altfix=len(code)+1;code.extend((0x4c,0,0))
           code.extend(normal);endfix=len(code)+1;code.extend((0x4c,0,0))
           altat=len(code);code.extend(alternate);endat=len(code)
           # Temporarily store program-relative addresses; relocate at pack.
           code[altfix:altfix+2]=altat.to_bytes(2,'little');code[endfix:endfix+2]=endat.to_bytes(2,'little')
          code.extend((0xa9,glyph|flags));code.extend(ins(0x8d,mapaddr))
        code.append(0x60)
        if pos+len(code)>0x3f00:
         bi+=1;pos=0;banks.append(bytearray([255])*16384)
        assert bi+64<253,('Native renderer exceeds free cart banks',bi)
        address=0x8000+pos
        # Decode only the small, known opcode set and relocate local JMPs.
        pc=0
        while pc<len(code):
         op=code[pc]
         if op==0x4c:
          rel=int.from_bytes(code[pc+1:pc+3],'little')
          code[pc+1:pc+3]=(rel+address).to_bytes(2,'little')
         pc+=1 if op in (0xaa,0x60)else 2 if op in (0xa0,0xa9,0xb1,0x29,0x09,0x85,0x30,0x10)else 3
        assert pc==len(code)
        banks[bi][pos:pos+len(code)]=code;pos+=len(code);programs+=1
        banks[0][directory+y]=address&255;banks[0][directory+256+y]=address>>8;banks[0][directory+512+y]=64+bi
    report=dict(programs=programs,first_bank=64,last_bank=64+bi,allocated_banks=len(banks),last_bank_bytes=pos,
        source='Approved immutable poses 3/4, X=52, every Y 0..138, both buffers',artwork_changed=False)
    (ROOT/'build/trapeze-native-hero.json').write_text(json.dumps(report,indent=2)+'\n')
    return banks
