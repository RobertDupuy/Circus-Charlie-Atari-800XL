"""Validate native hero compositors against the generic mask, all four routes."""
from cpu import Machine,ROOT
import json,hashlib

def capture(reference=False):
 frames=[];cost=0
 for rank in range(4):
  m=Machine();m.stage(5,rank)
  if reference:
   m.m[m.labels['apparatus_blend_prepare']]=0x60
   m.m[m.labels['apparatus_clip_rect']]=0x18;m.m[m.labels['apparatus_clip_rect']+1]=0x60
   p=m.labels['gfx_cached_select'];target=m.labels['gfx_native_cached'];code=bytes(m.m[p:p+130]);needle=bytes([0x4c,target&255,target>>8])
   for i in range(len(code)-2):
    if code[i:i+3]==needle:
     for j in range(3):m.m[p+i+j]=0xea
  seq=json.loads((ROOT/f'assets/routes/mechanics-route-5-{rank}.json').read_text())
  for f in range((len(seq)+1)//2):
   for j in range(2):
    t=f*2+j
    if t>=len(seq):break
    joy,fire=seq[t];m.set('input',joy);m.set('fire_latch',fire);m.call('game_tick')
   if reference:
    m.set('r_blend_enabled',0)
   back=f&1;m.set('back',back);cost+=m.call('render_frame')
   assert m.get('fault')==0,(rank,f)
   memory=bytes(m.m[0x3800+back*0x400:0x3c00+back*0x400])+bytes(m.m[0x4000+back*0xc00:0x4c00+back*0xc00])
   frames.append(hashlib.sha256(memory).digest())
  assert m.get('mode')==4
 return frames,cost
old,oldcost=capture(True);new,newcost=capture()
assert old==new,('compositor pixel mismatch',[i for i,(a,b) in enumerate(zip(old,new)) if a!=b][:10])
r={'frames_compared':len(new),'pixel_identical':True,'mean_cycles_saved':round((oldcost-newcost)/len(new),1)}
(ROOT/'build/rope-cache-check.json').write_text(json.dumps(r,indent=2));print(r)
