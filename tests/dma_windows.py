"""Every disabled DMA scanline must contain no visible player pixels.

Check both buffers, every route/rank, and intro/death/clear displays. This
independently reads the actual PM bitmaps and staged horizontal positions.
"""
from cpu import Machine,ROOT
import json
starts=[40,64,96,104,112,144,176,200,216]
reports=[]
for scene in (1,2,4,5,6):
 for rank in range(6):
  m=Machine();m.stage(scene,rank);checked=0;disabled=0
  seq=json.loads((ROOT/f'assets/routes/mechanics-route-{scene}-{rank}.json').read_text())
  for f in range((len(seq)+1)//2):
   for joy,fire in seq[f*2:f*2+2]:m.set('input',joy);m.set('fire_latch',fire);m.call('game_tick')
   back=f&1;m.set('back',back);m.call('render_frame')
   modes=(m.get('mode'),1,3,4) if f%67==0 else (m.get('mode'),)
   original=m.get('mode')
   for mode in modes:
    m.set('mode',mode)
    if mode!=original:m.call('render_frame')
    assert not m.get('fault'),(scene,rank,f,mode,'font overflow')
    events={40:0};i=0
    while i<8:
     i=m.m[m.labels['gfx_dli_next']+i];events[starts[i]]=i
    dma=0x32
    for y in range(256):
     if y in events:dma=m.m[0xe10+back*32+events[y]]
     if dma&8:continue
     disabled+=1
     for p in range(4):
      if not m.m[0xe00+back*32+p]:continue
      address=0x5c00+back*2048+p*256+y
      assert not m.m[address],(scene,rank,f,mode,y,p,'hidden PM pixels')
      if y in events:assert not m.m[address-1],(scene,rank,f,mode,y,p,'nonzero latch at DMA stop')
    checked+=1
   m.set('mode',original)
  assert m.get('mode')==4
  reports.append({'scene':scene,'rank':rank,'pictures_checked':checked,'disabled_blank_scanlines':disabled})
(ROOT/'build/dma-windows-check.json').write_text(json.dumps(reports,indent=2));print(reports)
