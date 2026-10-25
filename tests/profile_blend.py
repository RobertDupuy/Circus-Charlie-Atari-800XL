"""Record compositor coverage across the four normal, input-only trapeze routes."""
from cpu import Machine,ROOT
from collections import Counter
import json
patterns=json.loads((ROOT/'assets/hero-blend-patterns.json').read_text());count=Counter()
for rank in range(4):
 m=Machine();m.stage(5,rank);seq=json.loads((ROOT/f'assets/routes/mechanics-route-5-{rank}.json').read_text())
 for f in range((len(seq)+1)//2):
  for j in range(2):
   t=f*2+j
   if t>=len(seq):break
   joy,fire=seq[t];m.set('input',joy);m.set('fire_latch',fire);m.call('game_tick')
  m.set('back',f%2);m.call('render_frame')
  assert m.get('fault')==0,(rank,f)
  if m.get('gfx_hero_pose') not in (3,4) or m.get('gfx_hero_x')&3:continue
  variant=(m.get('gfx_hero_pose')-3)*8+(m.get('gfx_hero_y')&7)
  for i in range(m.get('gfx_mask_count')):count[patterns[str(variant)][m.m[0xdd00+i]]]+=1
 assert m.get('mode')==4
 print('profile',rank,len(seq),flush=True)
(ROOT/'assets/hero-blend-weights.json').write_text(json.dumps(count,sort_keys=True))
print('patterns',len(count),'mask calls',sum(count.values()))
