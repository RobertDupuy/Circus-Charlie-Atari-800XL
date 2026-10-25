"""Weight immutable spring glyphs using both presentation parities, all ranks."""
from cpu import Machine,ROOT
from collections import Counter
import json
rom=(ROOT/'build/Circus-Charlie-SIC512.rom').read_bytes();weights=Counter()
for rank in range(4):
 for parity in range(2):
  m=Machine();m.stage(4,rank);seq=json.loads((ROOT/f'assets/routes/mechanics-route-4-{rank}.json').read_text())
  if parity:
   joy,fire=seq.pop(0);m.set('input',joy);m.set('fire_latch',fire);m.call('game_tick')
  for f in range((len(seq)+1)//2):
   cyc=0
   for joy,fire in seq[f*2:f*2+2]:m.set('input',joy);m.set('fire_latch',fire);cyc+=m.call('game_tick')
   visible=[]
   for i in range(16):
    w=m.m[m.labels['h_width']+i]
    if not w:continue
    x=m.m[m.labels['hazard_xlo']+i]+256*m.m[m.labels['hazard_xhi']+i]-3*w-m.word('camera')
    if x>=160 or x+6*w<=0:continue
    pose=w*2+26+((m.get('anim_clock')>>2)&1)
    d=7*16384+pose*128+(x&3)*32
    bank=rom[d];address=int.from_bytes(rom[d+1:d+3],'little');count=rom[d+3]
    start=bank*16384+address-0x8000
    for j in range(count):
     cell=rom[start+j*10:start+(j+1)*10]
     if 0<=x//4+(cell[0]&31)<40:visible.append(bytes(cell[2:]))
   m.set('back',f&1);cyc+=m.call('render_frame')
   factor=max(1,(cyc-26000)//100)
   for p in visible:weights[p]+=factor
  assert m.get('mode')==4
(ROOT/'assets/spring-cache-weights.json').write_text(json.dumps({p.hex():v for p,v in weights.items()},sort_keys=True));print(len(weights),'patterns weighted across both parities')
