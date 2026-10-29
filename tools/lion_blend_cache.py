"""Compile exact Lion jump masks into audited unused crowd-bank padding.

The input is the approved prepared bitmap, never regenerated artwork. These
programs implement the generic transparent-pixel merge using immediate masks.
The crowd data ends below $8500; crowd writers start at $A000. Nothing in the
original $8500..$9FFF interval is referenced by either writer.
"""
from collections import Counter
from pathlib import Path
import json

ROOT=Path(__file__).resolve().parents[1]
BANK=18
START,END=0x500,0x2000
DIRECTORY=0x700

def install(rom):
    approved=(ROOT/'assets/asset-banks.bin').read_bytes()
    assert approved[BANK*16384+START:BANK*16384+END]==bytes([255])*(END-START)
    # Existing crowd writers contain only LDA abs,X; STA abs; LDY abs,X;
    # LDA immediate; STA abs,Y; RTS. Audit every source address explicitly.
    for start in (0x2000,0x2800):
        pc=start
        while True:
            op=approved[BANK*16384+pc]
            if op==0x60:break
            assert op in (0xbd,0x8d,0xbc,0xa9,0x99),(pc,op)
            if op in (0xbd,0xbc):
                address=int.from_bytes(approved[BANK*16384+pc+1:BANK*16384+pc+3],'little')
                assert address+39<0x8500,(pc,address)
            pc+=2 if op==0xa9 else 3

    lists={};frequency=Counter()
    for pose in (86,89,92):
        for shift in range(8):
            off=7*16384+pose*128+shift*4
            bank,lo,hi,count=approved[off:off+4]
            off=bank*16384+lo+(hi-128)*256
            payload=off+approved[off]
            glyphs=[approved[payload+i*8:payload+(i+1)*8]for i in range(count)]
            lists[(pose-84)*8+shift]=glyphs
            for pixels in glyphs:
                if any(any(not((v>>bit)&3)for bit in (0,2,4,6))for v in pixels):frequency[pixels]+=1
    data=bytearray([255])*(END-START)
    helper=(ROOT/'build/liongfx.bin').read_bytes()
    assert len(helper)==256
    data[:256]=helper
    fused=(ROOT/'build/fused.bin').read_bytes()
    assert len(fused)==256
    data[256:512]=fused
    data[DIRECTORY-START:DIRECTORY-START+144]=bytes(144)
    position=DIRECTORY+144
    offsets={}
    for variant,glyphs in lists.items():
        offsets[variant]=position
        address=0x8000+position
        data[DIRECTORY-START+variant*2:DIRECTORY-START+variant*2+2]=address.to_bytes(2,'little')
        position+=len(glyphs)*2
    programs={};suffixes={}
    for pixels in sorted(frequency,key=lambda p:(-frequency[p],p)):
        rows=[]
        for y,pixel in enumerate(pixels):
            mask=sum(3<<bit for bit in (0,2,4,6)if not(pixel&(3<<bit)))
            if not mask:continue
            row=bytearray((0xa0,y,0xb1,0xb0)) # LDY y; LDA (background),Y
            if mask!=255:row.extend((0x29,mask))
            if pixel:row.extend((0x09,pixel))
            row.extend((0x91,0xb2)) # STA (hero glyph),Y
            rows.append(bytes(row))
        rows.append(b'\x60')
        cut=len(rows);jump=None
        for i in range(len(rows)):
            suffix=b''.join(rows[i:])
            if len(suffix)>3 and suffix in suffixes:
                cut=i;jump=suffixes[suffix];break
        if cut==0:
            programs[pixels]=jump;continue
        code=bytearray(b''.join(rows[:cut]))
        if jump is not None:code.extend((0x4c,jump&255,jump>>8))
        assert position+len(code)<=END,'Lion mask cache overlaps crowd writer'
        address=0x8000+position;programs[pixels]=address
        data[position-START:position-START+len(code)]=code
        position+=len(code)
        offset=0
        for i,row in enumerate(rows[:cut]):
            suffixes[b''.join(rows[i:])]=address+offset;offset+=len(row)
    for variant,glyphs in lists.items():
        for i,pixels in enumerate(glyphs):
            off=offsets[variant]+i*2-START
            data[off:off+2]=programs.get(pixels,0).to_bytes(2,'little')
    rom[BANK*16384+START:BANK*16384+END]=data
    report=dict(bank=BANK,start=START,end=position,bytes=position-START,
                variants=len(lists),compiled_patterns=len(programs),
                source='Immutable approved Lion poses 86, 89, 92; all eight Y alignments at X alignment zero',
                artwork_changed=False,crowd_source_references_audited=True)
    (ROOT/'build/lion-blend-cache.json').write_text(json.dumps(report,indent=2)+'\n')
    return rom
