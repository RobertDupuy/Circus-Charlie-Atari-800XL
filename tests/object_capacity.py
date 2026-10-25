"""Ensure authored on-screen hazards fit hardware player/missile allocation."""
from cpu import Machine,ROOT
from playthrough import controls
import json
results=[]
for rank in range(4):
 for act,limit,width in ((0,4,168),(1,4,152),(4,4,144)):
  m=Machine();m.stage(act,rank);peak=0
  while m.get('mode')==2:
   joy,fire=controls(m,act);m.set('input',joy);m.set('fire_latch',fire);m.call('game_tick')
   camera=m.word('camera');count=sum((-8 if act==0 else 0)<=m.m[0x940+i]+256*m.m[0x950+i]-camera<width and (act!=0 or m.m[0xd90c+i]) for i in range(4 if act==0 else 16))
   peak=max(peak,count);assert count<=limit,(act,rank,m.word('scene_clock'),count)
  assert m.get('mode')==4
  results.append({'act':act+1,'rank':rank,'peak_visible':peak,'player_slots':limit})
(ROOT/'build/object-capacity.json').write_text(json.dumps(results,indent=2));print(results)
