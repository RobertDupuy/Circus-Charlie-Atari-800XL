"""Render every simulation tick, including phases skipped by a 2-tick replay.

PAL alternates two and three simulation ticks per picture. Testing only every
second tick can miss an odd-phase glyph overflow. This sweep also renders the
introduction and the natural post-landing clear sequence.
"""
from cpu import Machine,ROOT
import json

reports=[]
for rank in range(6):
 for scene in range(7):
  m=Machine();m.stage(scene,rank);maximum=[0,0,0];pictures=0
  m.set('mode',1)
  for back in range(2):
   m.set('back',back);m.call('render_frame')
   assert not m.get('fault'),('introduction',scene,rank,back)
  m.set('mode',2)
  seq=json.loads((ROOT/f'assets/routes/mechanics-route-{scene}-{rank}.json').read_text())
  for tick,(joy,fire) in enumerate(seq+[[0,0]]*200):
   m.set('input',joy);m.set('fire_latch',fire);m.call('game_tick')
   if m.get('need_stage'):break
   m.set('back',tick&1);m.call('render_frame');pictures+=1
   assert not m.get('fault'),('glyph capacity',scene,rank,tick,m.get('mode'))
   if scene in (2,5):assert m.m[m.labels['free_glyph']+2]<=124,('Distance board pool',scene,rank,tick)
   for band in range(3):
    start=m.m[m.labels['gfx_range_start']+band]
    end=m.m[m.labels['gfx_range_end']+band]
    if start==255:continue
    maximum[band]=max(maximum[band],end-start)
    assert m.m[m.labels['bg_count']+band]+end-start<=128,(scene,rank,tick,band)
  reports.append(dict(scene=scene,rank=rank,pictures=pictures,hero_glyph_max=maximum))
  print(reports[-1],flush=True)
(ROOT/'build/every-tick-render.json').write_text(json.dumps(reports,indent=2))
