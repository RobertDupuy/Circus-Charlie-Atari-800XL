"""Act 1 acceptance against measured KONAMI-1 frames, using the assembled 6502.
Fixtures isolate physics/collisions; full unmodified input routes are separate.
"""
from cpu import Machine,ROOT
import csv,json,math

def score(m):return int(bytes(m.m[0x632:0x635])[::-1].hex())
def tick(m,joy=0,fire=0):
 m.set('input',joy);m.set('fire_latch',fire);return m.call('game_tick')
def isolated(rank=0):
 m=Machine();m.stage(0,rank);m.set('grace',255);return m
out={}
# Golden observations were read from arcade $20B7 at takeoff through landing.
rows=list(csv.DictReader((ROOT/'evidence/arcade-act1-jump.csv').open()))
expected=[int(r['height_pixels']) for r in rows]
m=isolated();actual=[]
for t in range(64):tick(m,8,t==0);actual.append(m.get('jump_pixels'))
assert actual==expected,(actual,expected)
assert not m.get('jumping') and m.word('world')==120 and m.get('lion_frac')==0
out['arcade_jump_trace_exact_frames']=len(actual)
out['jump_airborne_frames']=63;out['jump_apex_pixels']=max(actual)
# Releasing or reversing the stick after takeoff cannot alter the chosen speed.
for takeoff,in_air,delta in [(8,0,72),(8,4,72),(0,8,0)]:
 m=isolated();start=m.word('world');tick(m,takeoff,1)
 for t in range(63):tick(m,in_air)
 # The landing frame takes the new ground direction; compare through frame 62.
 m=isolated();start=m.word('world');tick(m,takeoff,1)
 for t in range(62):tick(m,in_air)
 movement=(m.word('world')-start)+m.get('lion_frac')/256
 assert movement==(63*1.125 if takeoff==8 else 0),(takeoff,in_air,movement)
out['airborne_momentum_locked']=True
m=isolated();m.wordset('world',500)
for _ in range(64):tick(m,4)
assert (m.word('world')+m.get('lion_frac')/256)==443
out['left_speed_colour_pixels_per_tick']=.890625
# Continuous ring motion, including when Charlie stands still.
m=isolated();m.m[0xd90c]=1;m.wordset('z_pos',0);m.m[0x940]=244;m.m[0x950]=1
for _ in range(64):tick(m)
assert m.word('world')==48 and m.m[0x940]+256*m.m[0x950]==476
out['stationary_player_ring_motion_64_ticks']=24
# The four ROM difficulty slices contain real short gaps, not evenly spaced hoops.
for rank,wave,gap in [(0,7,27),(1,7,30),(2,9,33),(3,1,33)]:
 m=isolated(rank);m.set('lion_wave',wave);m.set('lion_lastgap',1);m.wordset('lion_gap',0)
 tick(m,8);assert m.get('lion_wave')==wave+1
 assert m.word('lion_gap')==gap*192
 elapsed=0
 while m.get('lion_wave')==wave+1:tick(m,8);elapsed+=1
 assert elapsed==math.floor(gap/2)+1,(rank,gap,elapsed)
 out[f'rank_{rank}_close_pair_frames']=elapsed
# Raised money hoops: safe to run under, hazardous midway up, collectible high up.
for height,mode,want in [(0,2,0),(25,3,0),(43,2,1000)]:
 m=Machine();m.stage(0);m.m[0xd90f]=1;m.m[0xd913]=2;m.m[0x943]=48;m.m[0x953]=0;m.set('jump_pixels',height);m.set('jumping',int(height>0))
 m.call('lion_arcade_collision');assert (m.get('mode'),score(m))==(mode,want),(height,m.get('mode'),score(m))
 if want:m.call('lion_arcade_collision');assert score(m)==want and m.get('bag_awards')==1
out['money_hoop_underpass_and_high_clearance']=True
# Finish is a descending landing on the raised surface, never a ground crossing.
for jumping,phase,want in [(0,0,2),(1,4,2),(1,60,4)]:
 m=isolated();m.wordset('world',1362);m.set('jumping',jumping);m.set('lion_phase',phase);m.set('jump_pixels',10)
 tick(m,8);assert m.get('mode')==want
 if want==4:assert m.get('lion_goal')==1 and m.get('jump_pixels')==11
out['platform_requires_descending_landing']=True
# A press in the original late-landing window queues one new jump.
m=isolated();tick(m,8,1)
for _ in range(61):tick(m,8)
tick(m,0,1);tick(m,0)
assert m.get('jumping') and m.get('lion_phase')==0 and m.get('lion_direction')==0
out['late_landing_input_buffer']=True
# Exact prepared PM transfer, with all non-target DMA bytes unchanged.
rom=(ROOT/'build/Circus-Charlie-SIC512.car').read_bytes()[16:]
m=isolated();cases=0
for back in range(2):
 for slot in range(4):
  for phase in range(8):
   base=0x5800+back*0x800+0x400+slot*256
   for i in range(256):m.m[base+i]=165
   m.set('back',back);m.set('z_iter',slot);m.m[0x678+slot]=phase;m.call('gfx_copy_hoop_pm')
   expected=bytes(rom[23*16384+0x100+y*8+phase] for y in range(72))
   assert bytes(m.m[base+112:base+184])==expected
   assert all(m.m[base+i]==165 for i in list(range(112))+list(range(184,256)))
   cases+=1
out['four_player_eight_pose_transfer_cases']=cases
# Both clocks target the original physical arcade cadence, independently of rendering.
for pal,expected_ticks in [(0,89),(1,107)]:
 m=isolated();m.set('pal',pal);m.set('pal_acc',0);m.set('paused',1)
 # Paused game_tick is deliberately used so these are clock scheduling checks.
 counts=[]
 # Infer completed game_tick invocations via anim_clock after unpausing in title.
 m.set('paused',0);m.set('mode',0);start=m.word('anim_clock')
 for _ in range(44):m.call('gfx_game_steps')
 assert ((m.word('anim_clock')-start)&65535)==expected_ticks
 out['pal' if pal else 'ntsc']={'logic_ticks_per_44_presentations':expected_ticks}
(ROOT/'build/arcade-lion.json').write_text(json.dumps(out,indent=2));print(json.dumps(out,indent=2))
