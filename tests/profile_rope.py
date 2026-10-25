"""Choose immutable rope glyphs from the real four-rank input replays."""
from cpu import Machine,ROOT
from collections import Counter
import json
rom=(ROOT/'build/Circus-Charlie-SIC512.car').read_bytes()[16:];freq=Counter()
p=7*16384+0xeb0;bank,lo,hi=rom[p:p+3];atlas=bank*16384+(hi*256+lo-0x8000)
for rank in range(4):
 m=Machine();m.stage(5,rank);seq=json.loads((ROOT/f'assets/routes/mechanics-route-5-{rank}.json').read_text())
 for f in range((len(seq)+1)//2):
  for j in range(2):
   t=f*2+j
   if t>=len(seq):break
   joy,fire=seq[t];m.set('input',joy);m.set('fire_latch',fire);m.call('game_tick')
  for i in range(m.get('r_first'),m.get('r_limit')):
   if m.get('r_goal_ready') and i>m.get('r_goal_rope'):continue
   pivot=m.m[0xf00+i]+256*m.m[0xf20+i]-m.word('camera');sign=m.m[0xfc0+i]&1;dx=m.m[0xd920+i]
   if pivot < -48 or pivot>=208 or (sign and (pivot<0 or pivot-dx>=160)) or (not sign and (pivot>=160 or pivot+dx<0)):continue
   align=pivot&3
   if sign:align=3-align
   pos=7*16384+0x900+(m.m[0xd980+i]*4+align)*4;b,l,h,n=rom[pos:pos+4];data=b*16384+h*256+l-0x8000
   full=rom[data+(m.m[0xf40+i]-32)//4]>>2
   left=pivot-(51-align if sign else align)
   for j in range(full):
    col,row,idx=rom[data+8+j*3:data+11+j*3];idx+=256*(col>>7);col&=15
    col=(12-col if sign else col)+left//4
    if not 0<=col<40:continue
    pat=rom[atlas+idx*8:atlas+(idx+1)*8]
    if sign:pat=bytes(sum(((v>>(i*2))&3)<<((3-i)*2) for i in range(4)) for v in pat)
    freq[pat.hex()]+=1
print('weighted rope patterns',len(freq),'visits',sum(freq.values()))
(ROOT/'assets/rope-cache-weights.json').write_text(json.dumps(freq,sort_keys=True))
