"""Exercise normal gameplay with joystick/fire decisions through the real 6502.
No collision suppression, score patching, or forced stage clears.
"""
from cpu import Machine,ROOT
import json
from functools import lru_cache
@lru_cache(None)
def audited_route(a,rank):
 return json.loads((ROOT/f'assets/routes/mechanics-route-{a}-{rank}.json').read_text())

def controls(m,a):
 if a in (0,1,2,3,4,5,6):
  route=audited_route(a,m.get('rank'));t=m.word('scene_clock')
  return route[t] if t<len(route) else (0,0)
 w=m.word('world');jump=m.get('jumping');t=m.word('scene_clock');clock=m.word('hazard_clock');fire=0;joy=8
 hazards=[m.m[0x940+i]+256*m.m[0x950+i] for i in range(16)]
 if a==6:
  from water_route import route
  return route(m.get('rank'))[t]
 if a==0:
  obstacles=sorted(hazards[:14]+[m.m[0x960+i]+256*m.m[0x964+i] for i in range(4)])
  fire=int(not jump and any(32<=h-w<=35 for h in obstacles))
 elif a==1:
  fire=int(not jump and any(30<=h-w<=33 for h in hazards))
 elif a in (2,6):
  if m.get('rank'):
   from water_route import route
   return route(m.get('rank'),False)[t]
  current=m.m[0x63c];bounce=m.m[0x63d];target=60+current*64
  joy=8 if bounce>=2 and w<target+64 else 0
 elif a==3:
  b=m.m[0x63b];target=m.m[0x900+b+1]+256*m.m[0x910+b+1] if b<15 else 999
  fire=int(not jump)
  joy=8 if w<target else 0
  if b==15:joy=8;fire=0
 elif a==4:
  joy=0;fire=int(not jump and (any(38<=h-w<=41 for h in hazards) or 38<=m.word('stage_end')-w<=43))
 elif a==5:
  r=m.get('held_rope');p=m.m[0xD970+r];kind=m.m[0xD960+r]
  joy=8;fire=int(not m.get('flying') and (12<=p<=17 if kind<2 else 7<=p<=10))
 return joy,fire

def run(a,rank=0):
 m=Machine();m.stage(a,rank)
 inputs=[];costs=[];ticks=[];maxdirty=0;reason='limit';lives=3
 for frame in range(5000):
  cycles=0
  for j in range(2):
   joy,fire=controls(m,a);inputs.append([joy,fire]);m.set('input',joy);m.set('fire_latch',fire)
   cycles+=m.call('game_tick')
   if m.get('mode')!=2:break
  m.set('back',frame&1);r=m.call('render_frame');costs.append(r+cycles)
  maxdirty=max(maxdirty,m.m[0x656+(frame&1)])
  for band in range(3):
   start=m.m[0xdc90+band];end=m.m[0xdc93+band]
   assert start==255 or m.m[0x650+band]+end-start<=128,('hero font boundary',a,rank,band,start,end)
  assert m.m[0xdcc0]<=252 and m.m[0xdcc1]<=252,'rectangle capacity'
  if a==3:
   start=m.m[m.labels['bg_count']+2]
   assert start<=m.m[0x655]<=start+31<=128,'Ball merging exceeded its private font range'
  if m.get('fault'):reason='render fault';break
  if m.get('mode')!=2:
   reason='clear' if m.get('mode')==4 else 'death';break
 report={'act':a+1,'rank':rank,'result':reason,'ticks':len(inputs),'world':m.word('world'),'height':m.get('jump_pixels'),'velocity':m.get('velocity'),'max_cpu_cycles':max(costs),'steady_max_cpu_cycles':max(costs[2:]or costs),'dirty_cells':maxdirty,'fault':m.get('fault'),'score':bytes(m.m[0x632:0x635]).hex(),'mode':m.get('mode'),'monkey_leaps':m.get('leap_events'),'trampoline_rescues':m.get('rescue_events'),'pm_overflow':m.get('mech_pm_overflow')}
 assert not report['pm_overflow'],report
 (ROOT/f"build/inputs-act-{a+1}{'-rank-'+str(rank) if rank else ''}.json").write_text(json.dumps(inputs))
 print(report,flush=True);return report
if __name__=='__main__':
 reports=[run(a) for a in range(7)]
 (ROOT/'build/playthrough.json').write_text(json.dumps(reports,indent=2))
 assert all(r['result']=='clear' and not r['fault'] for r in reports)
