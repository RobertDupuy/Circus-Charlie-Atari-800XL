"""Execute every PAL/NTSC stream through real 6502 code and compare registers.
Includes every bank link and loop, FX restoration, pause and bank preservation.
"""
from cpu import Machine,ROOT
import json
m=Machine();m.call('audio_init');rows=json.loads((ROOT/'assets/audio/manifest.json').read_text());report=[]
for k,row in enumerate(rows):
 m.set('pal',int(row['standard']=='pal'));m.set('paused',0)
 m.call('audio_init');effect=row['kind']=='effect';stream=int(effect)
 m.call('audio_start',a=k%29,x=stream)
 data=json.loads((ROOT/'assets/audio'/row['file']).read_text());state=bytearray(5 if effect else 9);expected=[]
 for packet in data['packets']:
  duration,lo,hi,*values=packet;mask=lo+256*hi;j=0
  for i in range(len(state)):
   if mask>>i&1:state[i]=values[j];j+=1
  expected += [bytes(state)]*duration
 peak=0
 for n,frame in enumerate(expected):
  cost=m.call('audio_tick');peak=max(cost,peak)
  actual=bytes(m.m[(0xd204 if effect else 0xd200)+i] for i in range(len(frame)))
  assert actual==frame,(row['file'],n,actual,frame)
  assert m.c.at_cart_control()==0x3e,hex(m.c.at_cart_control())
 if data['loop_packet'] is not None:
  m.call('audio_tick');frame=expected[row['loop_frame']]
  actual=bytes(m.m[0xd200+i] for i in range(9));assert actual==frame,(row['file'],'loop',actual,frame)
 else:
  m.call('audio_tick');assert m.m[0xd804+stream]==0
 report.append({'file':row['file'],'frames':len(expected),'max_cpu_cycles':peak})
# Simultaneous music and effects: leading parts survive, music cursor continues.
m.call('audio_init');m.set('pal',0);m.call('audio_start',a=0,x=0);m.call('audio_start',a=14,x=1)
peak=0
for i in range(2000):
 peak=max(peak,m.call('audio_tick'))
 assert bytes(m.m[0xd200+j] for j in range(4))==bytes(m.m[0xd810+j] for j in range(4))
 if not m.m[0xd805]:assert bytes(m.m[0xd204+j] for j in range(5))==bytes(m.m[0xd814+j] for j in range(5))
before=bytes(m.m[0xd800+i] for i in range(8));m.set('paused',1);m.call('audio_tick')
assert bytes(m.m[0xd800+i] for i in range(8))==before
assert all(m.m[a]==0 for a in [0xd201,0xd203,0xd205,0xd207])
m.set('paused',0);m.call('audio_tick')
(ROOT/'build/arcade-audio-validation.json').write_text(json.dumps({'streams':report,'simultaneous_peak_cycles':peak},indent=2))
print('58 complete streams, loops, bank links, effects, pause: PASS; simultaneous peak',peak)
