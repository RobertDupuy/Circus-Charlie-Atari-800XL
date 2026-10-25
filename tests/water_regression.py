"""Water integrator against MAME observations, native contacts, and legal routes."""
from cpu import Machine,ROOT
import json

def bankcall(m,name):
 a=m.labels.get(name,m.labels.get('water_land::'+name))
 for i,v in enumerate([0xa9,0x3c,0x8d,0,0xd5,0x20,a&255,a>>8,0x60]):m.m[0x300+i]=v
 m.labels['_water_call']=0x300;m.call('_water_call')

def score(m):return int(bytes(m.m[0x632:0x635])[::-1].hex())
fields=['w_y','w_vel_hi','w_vel_lo','w_phase','w_limit','w_bounces']
observed=json.loads((ROOT/'evidence/water-mame.json').read_text())['transitions']
m=Machine();m.stage(6);m.set('grace',255);m.set('f_direction',0)
for row in observed:
 for name,v in zip(fields,row['before']):m.set(name,v)
 m.set('w_active',1);m.set('w_xlo',150);m.set('w_xhi',0)
 bankcall(m,'water_actors')
 actual=[m.get(n) for n in fields]
 assert actual==row['after'],(row,actual)
# Visible collision, clearance, pool miss, fourth stationary bounce.
for hit in (True,False):
 m=Machine();m.stage(6);m.set('w_active',1);m.set('w_y',160)
 m.set('w_xlo',m.word('world'));m.set('w_xhi',0)
 m.set('jump_pixels',20 if hit else 60);m.call('water_collision_entry')
 assert m.get('mode')==(3 if hit else 2)
m=Machine();m.stage(6);m.wordset('world',85);m.call('water_land_entry');assert m.get('mode')==3
m=Machine();m.stage(6);m.set('bounce_count',3);m.set('z_joy',0);m.call('water_land_entry');assert m.get('mode')==3
# Retry keeps water and returns to the last safe pedestal.
m=Machine();m.stage(6);m.set('tramp_index',10);m.call('water_resume_entry')
assert m.word('world')==52+3*192+66 and m.get('water')==1
# Third-bounce prizes follow 300..900, with one prize per pedestal.
m=Machine();m.stage(6)
for i,amount in enumerate([300,400,500,600,700,800,900,900]):
 before=score(m);m.set('tramp_index',i);m.set('bounce_count',3);m.set('jump_pixels',90)
 bankcall(m,'water_hazards');assert score(m)-before==amount
 before=score(m);bankcall(m,'water_hazards');assert score(m)==before
# Every six-rank course replays with ordinary input, real collisions and rendering.
reports=[]
for rank in range(6):
 m=Machine();m.stage(6,rank);peak=0;worst=0
 route=json.loads((ROOT/f'assets/routes/mechanics-route-6-{rank}.json').read_text())
 for tick,(joy,fire) in enumerate(route):
  if tick==60:
   m.set('pause_latch',1);m.call('game_tick');before=bytes(m.m[0xd900:0xd9a4]);t=m.word('scene_clock')
   for _ in range(40):m.call('game_tick')
   assert before==bytes(m.m[0xd900:0xd9a4]) and t==m.word('scene_clock')
   m.set('pause_latch',1)
  m.set('input',joy);m.set('fire_latch',fire);m.call('game_tick')
  assert m.get('mode') in (2,4),(rank,tick,m.get('mode'))
  if tick%2==0:
   m.set('back',(tick//2)&1);worst=max(worst,m.call('render_frame'))
   assert not m.get('fault') and not m.get('water_pm_overflow')
   peak=max(peak,m.get('water_pm_peak'))
 assert m.get('mode')==4 and m.get('lives')>=3
 reports.append(dict(rank=rank,ticks=len(route),peak_dolphins=peak,max_render_cycles=worst))
report=dict(mame_transitions=len(observed),collision_and_clearance=True,retry_checkpoint=True,prize_ladder=True,pause=True,routes=reports)
(ROOT/'build/water-regression.json').write_text(json.dumps(report,indent=2));print(report)
