"""Natural misses, visible floor landings, late horse recovery and game over.

Rank/player setup is isolated. Deaths, continues, restarts, and the recovered
finish use ordinary input. Every simulation tick renders, alternating buffers.
"""
from cpu import Machine,ROOT
import json


def tick(m,joy=0,fire=0):
 m.wordset('host_frames',(m.word('host_frames')+1)&65535)
 m.set('input',joy);m.set('fire_latch',fire);m.call('game_tick')
 # Main-loop stage transitions install their fonts before another picture.
 if m.get('need_stage'):return 0
 m.set('back',m.get('back')^1);cycles=m.call('render_frame')
 assert not m.get('fault'),(m.get('act'),m.get('rank'),m.get('mode'),m.word('world'))
 if m.get('act')==4:
  for band in range(3):
   start=m.m[m.labels['gfx_range_start']+band];end=m.m[m.labels['gfx_range_end']+band]
   assert start==255 or end-start<=m.m[m.labels['gfx_reserve']+band],('Horse actor overwrites platform glyphs',band,start,end)
 return cycles

def begin(m):
 while m.get('mode')==1:tick(m)
 assert m.get('mode')==2

def settle(m):
 samples=[]
 while m.get('mode')==3:
  tick(m);samples.append(m.get('death_drop'))
 assert samples==sorted(samples)
 assert samples[-1]==(30 if m.get('act')==3 else 14)
 return samples

def collide(m):
 for t in range(4000):
  tick(m,8)
  if m.get('mode')!=2:break
 assert m.get('mode')==3
 return t+1

def final_miss(m,rank):
 seq=json.loads((ROOT/f'assets/routes/mechanics-route-4-{rank}.json').read_text())
 last=max(i for i,(_,f) in enumerate(seq) if f)
 for i,(joy,fire) in enumerate(seq):
  tick(m,joy,fire if i<last else 0)
  if m.get('mode')!=2:break
 assert m.get('mode')==3 and 3620<=m.word('world')<=3623

reports=[]
for player in range(2):
 for rank in range(6):
  # Repeated ball misses must fall to the floor, including continue/over.
  m=Machine();m.stage(3,rank);m.set('player',player)
  other=0xda00+256*(player^1);untouched=bytes(m.m[other:other+256])
  for death in range(3):
   collide(m);settle(m)
   assert bytes(m.m[other:other+256])==untouched
   if death<2:m.call('load_stage');begin(m)
  assert m.get('mode')==6
  while m.get('mode')==6:
   tick(m)
   if m.get('mode')==6:assert m.get('feet')==166 and m.get('sprite_pose')==6
  assert m.get('mode')==0
  m.call('load_stage')
  tick(m,fire=1);m.call('load_stage')
  assert m.get('mode') in (1,7) and m.get('lives')==3 and not m.get('stage_hurt')
  reports.append(dict(act='balls',player=player+1,rank=rank+1,misses=3,floor=166,gameover_restart=True))
  # Failure at the final horse gap, then four attempts, one continue, and a
  # real recovered clear. No position or invulnerability edits during replay.
  m=Machine();m.stage(4,rank);m.set('player',player)
  other=0xda00+256*(player^1);untouched=bytes(m.m[other:other+256])
  final_miss(m,rank);positions=[];continues=0
  for attempt in range(4):
   settle(m)
   if m.get('mode')==6:tick(m,fire=1);continues+=1
   assert m.get('need_stage');m.call('load_stage');begin(m)
   positions.append(m.word('world'))
   assert m.word('world')==3311 and m.word('f_scroll')==4351
   assert m.word('f_horse_h')==m.word('f_horse_v')==m.get('jumping')==m.get('grace')==0
   assert bytes(m.m[other:other+256])==untouched
   if attempt<3:
    runway=collide(m);assert runway>=120,runway
   else:
    for joy,fire in json.loads((ROOT/f'assets/routes/horse-retry-{rank}.json').read_text()):tick(m,joy,fire)
    assert m.get('mode')==4
  assert continues==1
  reports.append(dict(act='horse',player=player+1,rank=rank+1,retries=4,continues=continues,retry_worlds=positions,recovered_finish=True))

# Let the horse's last life and continue timer expire at the late checkpoint,
# then start another game and choose Horse again (automatic starts Act 1).
for rank in range(6):
 m=Machine();m.stage(4,rank);final_miss(m,rank)
 for death in range(3):
  settle(m)
  if death<2:m.call('load_stage');begin(m);collide(m)
 assert m.get('mode')==6
 while m.get('mode')==6:tick(m)
 assert m.get('mode')==0
 m.call('load_stage')
 tick(m,fire=1);m.call('load_stage')
 if m.get('mode')==7:
  tick(m,2);tick(m);tick(m,8);tick(m,fire=1);m.call('load_stage')
  assert m.get('act')==4
 begin(m)
 for _ in range(30):tick(m)
 assert m.get('mode')==2 and m.get('lives')==3 and m.get('rank')==0
reports.append(dict(horse_late_gameovers=6,restarts_playable=True))
(ROOT/'build/ball-horse-retry.json').write_text(json.dumps(reports,indent=2));print(json.dumps(reports,indent=2))
