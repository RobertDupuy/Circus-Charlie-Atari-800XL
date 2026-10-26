"""Replay real losses that exposed descending, exact-top spring edge contacts.

Fixtures contain joystick/fire samples, not saved game state. Rank/player are
stage-entry fixtures; checkpoints, misses, retries and continues run normally.
"""
from cpu import Machine,ROOT
import json,hashlib

cases=json.loads((ROOT/'tests/fixtures/horse-edge-losses.json').read_text())['cases']
reports=[]
for player in range(2):
 for case in cases:
  m=Machine();m.stage(4,case['rank']);m.set('player',player)
  losses=continues=0
  for i,(joy,fire) in enumerate(case['inputs']):
   mode=m.get('mode');before_lives=m.get('lives')
   if i==len(case['inputs'])-1:
    b=case['before']
    assert (m.word('world'),m.get('jump_pixels'),m.get('lives'))==(b['world'],b['height'],b['lives'])
    assert m.get('stage_hurt') and losses==case['prior_losses']
    assert m.get('velocity')>=128
   m.wordset('host_frames',(m.word('host_frames')+1)&65535)
   m.set('input',joy);m.set('fire_latch',fire);m.call('game_tick')
   losses+=mode==2 and m.get('mode')==3
   continues+=mode==6 and m.get('mode')==1
   if m.get('need_stage'):m.call('load_stage')
   if i%2==0:
    m.set('back',(i//2)&1);m.call('render_frame');assert not m.get('fault')
  assert m.get('mode')==2 and m.get('lives')==before_lives,('Exact-top landing killed Charlie',case['rank'])
  assert m.get('jumping') and m.get('velocity')<128 and m.get('jump_pixels')==case['before']['height']
  for _ in range(8):
   m.set('input',joy);m.call('game_tick');assert m.get('mode')==2
  reports.append(dict(player=player+1,rank=case['rank'],natural_losses=losses,continues=continues,
                      ticks=len(case['inputs']),contact_world=case['old_death_world'],bounced_alive=True))

# Isolate the boundary at every apparatus width, deck height and travel speed.
# Adjacent cases must still distinguish a top landing from a side/underside hit.
boundaries=0
for width in range(2,8):
 for y in (128,136,144):
  for joy in (4,0,8):
   for offset in (-1,0,1):
    for rising in (False,True):
     m=Machine();m.stage(4);m.wordset('world',500);m.set('h_speed',{4:1,0:2,8:3}[joy])
     m.set('f_idle',100);m.m[0xd960]=width;m.m[0xd950]=y
     m.m[0x940]=500&255;m.m[0x950]=500>>8
     h=152-y+offset
     m.set('jumping',1);m.set('jump_pixels',h);m.wordset('f_horse_h',h*256)
     m.wordset('f_horse_v',0x100 if rising else 0xff00)
     m.set('input',joy);m.call('game_tick')
     # Rising above the top is clear; rising into its body is fatal.
     should_live=(not rising and offset>=0)or(rising and offset>0)
     assert (m.get('mode')==2)==should_live,(width,y,joy,offset,rising)
     if not rising and should_live:assert m.get('velocity')<128 and m.get('jump_pixels')==152-y
     boundaries+=1
report=dict(car_sha256=hashlib.sha256((ROOT/'build/Circus-Charlie-SIC512.car').read_bytes()).hexdigest(),
            replay_cases=reports,boundary_cases=boundaries)
(ROOT/'build/horse-contacts.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))
