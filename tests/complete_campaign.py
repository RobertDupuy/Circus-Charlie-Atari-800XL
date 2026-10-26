"""Two uninterrupted shows: title, 60 acts, 5 water visits, third-show entry.
Only controller input and the same stage-loader entry called by the main loop.
No active game state, collisions, lives, score or progression flags are changed.
"""
from cpu import Machine,ROOT
import json
m=Machine();m.set('input',0);m.set('fire_latch',1);m.call('game_tick')
finished=[];last_mode=0;route=[];frame=0;deaths=0
for tick in range(200000):
 if m.get('need_stage'):m.call('load_stage')
 mode=m.get('mode')
 if m.get('show_cycle')==2:break
 if mode==2 and last_mode!=2:
  scene=6 if m.get('water') else m.get('act');rank=m.get('rank')
  route=json.loads((ROOT/f'assets/routes/mechanics-route-{scene}-{rank}.json').read_text())
 if mode==2:
  index=m.word('scene_clock');assert index<len(route),(scene,rank,index,len(route))
  joy,fire=route[index]
 else:joy,fire=0,int(mode in (0,7))
 m.set('input',joy);m.set('fire_latch',fire);m.call('game_tick')
 if mode==2 and m.get('mode')==4:
  finished.append(dict(scene=scene,rank=rank,ticks=m.word('scene_clock')))
  print('clear',len(finished),scene,rank,flush=True)
 if m.get('mode')==3:deaths+=1;raise AssertionError(('unexpected death',scene,rank,tick))
 if m.get("need_stage"):m.call("load_stage")
 if tick%2==0:
  m.set('back',frame&1);m.call('render_frame');frame+=1
  assert not m.get('fault'),(mode,scene if route else None,tick,m.get('fault'))
 last_mode=mode
else:raise AssertionError('career timeout')
assert len(finished)==65 and bytes(m.m[0x6d3:0x6d9])==bytes(6)
assert sum(x['scene']==6 for x in finished)==5
assert m.get('lives')>0 and m.get('mode') in (1,7)
report=dict(completed=True,performances=len(finished),water_visits=5,shows=2,
 third_show_available=True,game_ticks=tick,rendered_frames=frame,deaths=deaths,final_mode=m.get('mode'),acts=finished)
(ROOT/'build/complete-campaign.json').write_text(json.dumps(report,indent=2));print(report)
