"""Interrupt banked rendering/scoring with native XL VBI or DLI audio."""
from cpu import Machine,ROOT
import json

def setup(a):
 m=Machine();m.stage(a);m.call('audio_init');m.call('audio_start',a=0,x=0);m.call('audio_start',a=14,x=1)
 n=m.labels['nmi'];m.m[0xfffa]=n&255;m.m[0xfffb]=n>>8
 m.set('loading',0);m.set('ready',0);m.set('phase',0)
 return m
cases=0
for a in range(7):
 m=setup(a);m.call('render_frame');expected=bytes(m.m[0x3400:0x6800])
 # Normal bands preserve Y without a stack save; audio and lion shade
 # bands save it only when used. Interrupt real render work on each path.
 interrupts=[(0x40,1)]+[(0x80,i) for i in (0,1,2,8)]
 if a==0:interrupts += [(0x80,i) for i in (9,10,11)]
 for kind,index in interrupts:
  for delay in (20,150,500,1100,3000,7000,15000,21000):
   m=setup(a);m.m[0xd40f]=kind;m.set('dli_index',index);m.c.at_force_nmi(delay);m.call('render_frame')
   assert bytes(m.m[0x3400:0x6800])==expected,(a,kind,index,delay)
   assert m.get('fault')==0;cases+=1
# Decimal addition can be interrupted inside the bank-zero score routine.
for kind in (0x40,0x80):
 for delay in range(10,130,10):
  m=setup(0);m.m[0x632]=0x90;m.m[0x633]=0x99;m.m[0x634]=0x01
  m.m[0xd40f]=kind;m.set('dli_index',1);m.c.at_force_nmi(delay);m.call('add_points',a=0x10,y=0)
  assert bytes(m.m[0x632:0x635])==bytes([0,0,2]),(kind,delay)
  assert m.get('lives')==4;cases+=1
report={'interrupt_cases':cases,'graphics_unchanged':True,'decimal_score_restored':True,'banked_calls_return_correctly':True}
(ROOT/'build/interrupt-audio.json').write_text(json.dumps(report,indent=2));print(report)
