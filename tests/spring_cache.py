"""All six horse routes: cached spring tiles versus original masked pixels."""
from cpu import Machine,ROOT
import numpy as np,json,hashlib
band=np.array([0]*8+[1]*9+[2]*5)
def pixels(m,back):
 codes=np.frombuffer(bytes(m.m[0x3800+back*1024:0x3800+back*1024+880]),np.uint8).reshape(22,40)
 fonts=np.frombuffer(bytes(m.m[0x4000+back*3072:0x4000+back*3072+3072]),np.uint8).reshape(3,128,8)
 packed=fonts[band[:,None],codes&127].transpose(0,2,1).reshape(176,40)
 colors=(packed[:,:,None]>>np.array([6,4,2,0]))&3
 alt=np.repeat(codes&128,8,axis=0)[:,:,None]
 return np.where((colors==3)&(alt!=0),4,colors).astype(np.uint8).tobytes()
def run(reference):
 out=[];cycles=0
 for rank in range(6):
  m=Machine();m.stage(4,rank)
  if reference:
   p=m.labels['gfx_spring_board'];target=m.labels['draw_stamp'];m.m[p]=0x4c;m.m[p+1]=target&255;m.m[p+2]=target>>8
   # Independent ordinary-stamp reference for both columns. The production
   # helper draws the pair in one native call; this fixture lives in test RAM.
   def absolute(op,name):
    address=m.labels[name];return [op,address&255,address>>8]
   code=absolute(0x20,'draw_stamp')+[0xa6,m.labels['z_hazard']]+absolute(0xbd,'h_width')
   code += [0x0a,0x18]+absolute(0x7d,'h_width')+[0x0a,0x38,0xe9,3,0x18]
   code += absolute(0x6d,'sprite_x')+absolute(0x8d,'sprite_x')+[0x90,3]+absolute(0xee,'sprite_xhi')+absolute(0x4c,'draw_stamp')
   for i,v in enumerate(code):m.m[0x300+i]=v
   p=m.labels['gfx_spring_leg'];m.m[p]=0x4c;m.m[p+1]=0;m.m[p+2]=3
   p=m.labels['ds_spring_cache'];target=m.labels['ds_spring_fallback'];m.m[p]=0x4c;m.m[p+1]=target&255;m.m[p+2]=target>>8
   m.m[m.labels['bg_count']+1]=11;m.m[m.labels['bg_count']+2]=48
   m.m[m.labels['gfx_alt_base']+7]=11;m.m[m.labels['gfx_alt_base']+8]=48
  seq=json.loads((ROOT/f'assets/routes/mechanics-route-4-{rank}.json').read_text())
  for f in range((len(seq)+1)//2):
   for joy,fire in seq[f*2:f*2+2]:m.set('input',joy);m.set('fire_latch',fire);m.call('game_tick')
   back=f&1;m.set('back',back);cycles+=m.call('render_frame')
   assert m.get('fault')==0,(rank,f)
   out.append(hashlib.sha256(pixels(m,back)).digest())
  assert m.get('mode')==4
 return out,cycles
old,a=run(True);new,b=run(False)
assert old==new,('spring pixel mismatch',[i for i,(x,y) in enumerate(zip(old,new)) if x!=y][:12])
r={'frames_compared':len(new),'pixel_identical':True,'mean_cycles_saved':round((a-b)/len(new),1)}
(ROOT/'build/spring-cache-check.json').write_text(json.dumps(r,indent=2));print(r)
