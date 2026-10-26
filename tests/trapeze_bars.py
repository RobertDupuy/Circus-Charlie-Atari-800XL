"""Scanline handlebar writer equals the independent prepared/masked sprite.

Also prove the tightened actor reservation over every pose/alignment and all
ordinary route phases, including odd simulation ticks and falling positions.
"""
from cpu import Machine, ROOT
import json, sys, hashlib
import numpy as np
sys.path.insert(0,str(ROOT/'tools'))
import assets, bold_art

ims,names,*_ = assets.poses();ims,names = bold_art.actors(ims,names)
for pose in (3,4,6):
    for sx in range(4):
        for sy in range(8):
            a=np.zeros((48,20),np.uint8);a[sy:sy+38,sx:sx+16]=ims[pose]
            count=sum(a[y:y+8,x:x+4].any() for y in range(0,48,8) for x in range(0,20,4))
            assert count<=25,(pose,sx,sy,count)

def pixels(m,back):
    out=bytearray()
    for row in range(8):
        for scan in range(8):
            for col in range(40):
                code=m.m[0x3800+back*1024+row*40+col]
                bits=m.m[0x4000+back*0xc00+(code&127)*8+scan]
                for shift in (6,4,2,0):
                    v=(bits>>shift)&3;out.append(4 if v==3 and code&128 else v)
    return bytes(out)

cases=0
for back in range(2):
    m=Machine();m.stage(5);m.set('back',back);m.call('render_frame');m.c.at_save_slot(0)
    address=m.labels['complete_rope_bar_draw']
    code=bytes((0xa9,0x3c,0x8d,0,0xd5,0x4c,address&255,address>>8))
    m.labels['bar_fixture']=0x300
    for x in list(range(-6,8))+list(range(48,56))+list(range(153,161)):
        for y in list(range(8))+list(range(25,33))+list(range(56,64)):
            result=[]
            for native in (False,True):
                m.c.at_restore_slot(0)
                for i,b in enumerate(code):m.m[0x300+i]=b
                m.wordset('sprite_x',x&65535);m.set('sprite_y',y);m.set('sprite_pose',110)
                m.call('bar_fixture' if native else 'draw_stamp')
                assert not m.get('fault'),(back,x,y,native)
                result.append(pixels(m,back))
            assert result[0]==result[1],('bar pixels',back,x,y)
            cases+=1

frames=[]
for reference in (False,True):
    hashes=[]
    for rank in range(6):
        m=Machine();m.stage(5,rank)
        if reference:
            # Fall through to the original per-scanline endpoint clipper.
            helper=m.labels['rope_partial_fast'];start=m.labels['apparatus_draw_cells']
            needle=bytes((0x20,helper&255,helper>>8,0x4c))
            offset=bytes(m.m[start:start+768]).index(needle)
            for i in range(6):m.m[start+offset+i]=0xea
        seq=json.loads((ROOT/f'assets/routes/mechanics-route-5-{rank}.json').read_text())
        for tick,(joy,fire) in enumerate(seq):
            m.set('input',joy);m.set('fire_latch',fire);m.call('game_tick')
            back=tick&1;m.set('back',back);m.call('render_frame')
            assert not m.get('fault'),('rope glyph capacity',rank,tick)
            if m.get('mode')!=4:
                for band in range(3):
                    start=m.m[m.labels['gfx_range_start']+band];end=m.m[m.labels['gfx_range_end']+band]
                    assert start==255 or end-start<=m.m[m.labels['gfx_reserve']+band],(rank,tick,band,start,end)
            data=bytes(m.m[0x3800+back*1024:0x3c00+back*1024])+bytes(m.m[0x4000+back*3072:0x4c00+back*3072])
            hashes.append(hashlib.sha256(data).digest())
        assert m.get('mode')==4
    frames.append(hashes)
assert frames[0]==frames[1],'Optimized endpoint pixels changed'
report=dict(pixel_reference_cases=cases,route_frames=len(frames[0]),endpoint_pixels_identical=True,
            all_six_ranks=True,max_actor_glyphs=25)
(ROOT/'build/trapeze-bars.json').write_text(json.dumps(report,indent=2)+'\n');print(report)
