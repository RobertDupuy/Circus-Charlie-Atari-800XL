"""Profile the busiest input-only rendered frame; not part of release logic."""
from cpu import Machine,ROOT
import ctypes,json,bisect,sys
rank=int(sys.argv[1]) if len(sys.argv)>1 else 0
m=Machine();m.stage(2,rank);seq=json.loads((ROOT/f'assets/routes/mechanics-route-2-{rank}.json').read_text());best=(0,0)
for f in range((len(seq)+1)//2):
 m.c.at_save_slot(0);cyc=0
 for j in range(2):
  t=f*2+j
  if t>=len(seq):break
  joy,fire=seq[t];m.set('input',joy);m.set('fire_latch',fire);cyc+=m.call('game_tick')
 m.set('back',f%2);cyc+=m.call('render_frame')
 if cyc>best[0]:best=(cyc,f);m.c.at_clone_slot(1,0)
m.c.at_restore_slot(1);m.c.at_clear_pc_cycles()
for j in range(2):
 joy,fire=seq[best[1]*2+j];m.set('input',joy);m.set('fire_latch',fire);m.call('game_tick')
m.set('back',best[1]%2);m.call('render_frame');m.c.at_pc_cycles.restype=ctypes.POINTER(ctypes.c_uint64);p=m.c.at_pc_cycles();labels=sorted((v,k) for k,v in m.labels.items() if not k.startswith('@') and 0x1000<=v<0xfd00);addresses=[v for v,k in labels];counts={}
for pc in range(65536):
 if p[pc]:
  i=bisect.bisect_right(addresses,pc)-1;key=labels[i][1] if i>=0 else hex(pc);counts[key]=counts.get(key,0)+p[pc]
print('worst',best,'masks',m.get('gfx_mask_count'),'free',bytes(m.m[0x650:0x656]).hex())
print(sorted(counts.items(),key=lambda v:-v[1])[:30])
(ROOT/f'build/profile-act3-{rank}.json').write_text(json.dumps({'worst':best,'counts':counts},indent=2))
