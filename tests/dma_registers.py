"""DMACTL and GRACTL must agree at every actual display interrupt.

Blank PM memory alone is insufficient: with player DMA off and GRACTL on,
ANTIC display-list reads can feed stray data into the GTIA player latches.
"""
from cpu import Machine,ROOT
import json

cases=0
for scene in range(7):
 for rank in range(4):
  m=Machine();m.stage(scene,rank);m.set('loading',0)
  m.labels['probe']=0x300
  for i in range(32):m.m[0x300+i]=0xea
  m.m[0x320]=0x60
  n=m.labels['nmi'];m.m[0xfffa]=n&255;m.m[0xfffb]=n>>8
  for back in range(2):
   m.set('back',back);m.call('render_frame');m.set('front',back);m.call('gfx_font_table')
   m.set('ready',0);m.set('phase',1);m.set('render_busy',0)
   m.m[0xd01d]=0 # A prior gated band/title can leave player output disabled.
   m.m[0xd40f]=0x40;m.c.at_force_nmi(8);m.call('probe')
   assert bool(m.m[0xd400]&8)==bool(m.m[0xd01d]&2),(scene,rank,back,'VBI')
   cases+=1
   for index in range(9):
    m.m[0xd40f]=0x80;m.set('dli_index',index)
    m.c.at_force_nmi(8);m.call('probe')
    assert bool(m.m[0xd400]&8)==bool(m.m[0xd01d]&2),(scene,rank,back,index)
    cases+=1
report=dict(interrupt_cases=cases,dma_and_player_latches_agree=True)
(ROOT/'build/dma-registers.json').write_text(json.dumps(report,indent=2));print(report)
