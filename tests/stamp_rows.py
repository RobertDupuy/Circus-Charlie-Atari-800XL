"""Reuse sprite row addresses without changing any rendered pixel, across all routes."""
from cpu import Machine,ROOT
from playthrough import controls
import hashlib,json
def run(reference):
 frames=[];cycles=0
 for rank in range(6):
  for scene in range(7):
   m=Machine();m.stage(scene,rank)
   if reference:
    start=m.labels['draw_stamp'];code=bytes(m.m[start:start+500])
    branch=start+code.index(bytes((0xc5,m.labels['gfx_stamp_row'],0xf0)))+2
    m.m[branch]=0xea;m.m[branch+1]=0xea
   f=0
   while m.get('mode')==2:
    for _ in range(2):
     if m.get('mode')!=2:break
     joy,fire=controls(m,scene);m.set('input',joy);m.set('fire_latch',fire);m.call('game_tick')
    back=f&1;m.set('back',back);cycles+=m.call('render_frame')
    assert not m.get('fault'),(scene,rank,f)
    graphics=bytes(m.m[0x3800+back*1024:0x3800+back*1024+880])+bytes(m.m[0x4000+back*3072:0x4000+back*3072+3072])
    frames.append(hashlib.sha256(graphics).digest());f+=1
    assert f<5000,(scene,rank,'route timeout')
   assert m.get('mode')==4,(scene,rank,m.get('mode'))
 return frames,cycles
old,a=run(True);new,b=run(False)
assert old==new,('sprite row cache mismatch',[i for i,(x,y) in enumerate(zip(old,new)) if x!=y][:12])
r={'frames_compared':len(new),'pixel_identical':True,'mean_cycles_saved':round((a-b)/len(new),1)}
(ROOT/'build/stamp-rows-check.json').write_text(json.dumps(r,indent=2));print(r)
