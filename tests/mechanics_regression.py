"""Arcade motion, contacts and retry acceptance on the actual 6502 cartridge.
Reference values come from the KONAMI-1 study and MAME frame observations.
"""
from cpu import Machine,ROOT
import json,csv
out={}
def tick(m,joy=0,fire=0):
 m.set('input',joy);m.set('fire_latch',fire);m.call('game_tick')
def route(a,rank=0):return json.loads((ROOT/f'assets/routes/mechanics-route-{a}-{rank}.json').read_text())
def bankcall(m,name,bank=29):
 address=m.labels[name];code=[0xa9,bank|32,0x8d,0,0xd5,0x20,address&255,address>>8,0xa9,63,0x8d,0,0xd5,0x60]
 for i,v in enumerate(code):m.m[0x300+i]=v
 m.labels['_fixture_call']=0x300;m.call('_fixture_call')
def score(m):return int(bytes(m.m[0x632:0x635])[::-1].hex())
# Exact 57-frame jump measured in MAME, including the zero-height landing.
golden=[4,7,10,13,16,19,22,25,28,30,32,34,36,38,40,42,44,45,46,47,48,49,50,51,52,52,52,52,52,52,52,52,51,50,49,48,47,46,45,44,42,40,38,36,34,32,30,28,25,22,19,16,13,10,7,4,0]
for a in (1,3):
 m=Machine();m.stage(a);seq=route(a)
 for joy,fire in seq:
  if fire:break
  tick(m,joy,fire)
 m.c.at_save_slot(0);paths=[]
 for later in (0,4,8):
  m.c.at_restore_slot(0);path=[]
  for i in range(57):
   tick(m,joy if i==0 else later,int(i==0));path.append((m.word('world'),m.get('f_fraction'),m.get('jump_pixels')))
  paths.append(path)
 assert paths[0]==paths[1]==paths[2],('air steering',a)
 assert [x[2] for x in paths[0]]==golden,('jump samples',a)
out['57_mame_jump_samples_and_no_air_steering']=True
# A pink monkey actually overtakes a close brown group and leaps, on each rank.
leaps=[];min_gaps=[]
for rank in range(4):
 m=Machine();m.stage(1,rank);smallest=999
 for joy,fire in route(1,rank):
  tick(m,joy,fire)
  xs=sorted(m.m[0x940+i]+256*m.m[0x950+i] for i in range(7) if m.m[0xd960+i])
  for x,y in zip(xs,xs[1:]):smallest=min(smallest,y-x)
 assert m.get('mode')==4 and m.get('leap_events')>0 and smallest<24
 leaps.append(m.get('leap_events'));min_gaps.append(smallest)
out['pink_leaps_by_rank']=leaps;out['closest_monkey_gaps']=min_gaps
# Horse: three selected speeds; neutral/reverse cannot brake an airborne jump.
for selected,speed in [(4,1),(0,2),(8,3)]:
 m=Machine();m.stage(4);tick(m,selected,1);assert m.get('h_speed')==speed
 m.c.at_save_slot(0);paths=[]
 for later in (0,4,8):
  m.c.at_restore_slot(0);path=[]
  for _ in range(20):
   tick(m,later);path.append((m.word('world'),m.get('f_fraction'),m.word('f_horse_h'),m.get('h_speed')))
  paths.append(path)
 assert paths[0]==paths[1]==paths[2]
out['horse_takeoff_locks_all_three_speeds']=True
# ROM-derived platform sequences retain multiple widths and all three heights.
widths=set();heights=set()
for rank in range(4):
 m=Machine();m.stage(4,rank)
 for joy,fire in route(4,rank):
  tick(m,joy,fire)
  for i in range(16):
   if m.m[0xd960+i]:widths.add(m.m[0xd960+i]);heights.add(m.m[0xd950+i])
 assert m.get('mode')==4
assert widths==set(range(2,8)) and heights=={128,136,144},(widths,heights)
out['horse_width_units']=sorted(widths);out['horse_heights']=sorted(heights)
# The final horse gap and the two walk courses cannot be cleared on foot.
for a in (1,3,4):
 m=Machine();m.stage(a);m.wordset('world',3620 if a==4 else m.word('stage_end')+1);tick(m,8)
 assert m.get('mode')==3,('ground endpoint must fall',a)
out['ground_crossing_never_clears']=True
# Original trapeze lengths/pivots, period clocks, and phase-dependent pumping.
m=Machine();m.stage(5)
assert list(m.m[0xf40:0xf4d])==[60,56,60,52,60,48,60,44,60,52,60,48,60]
assert [m.m[0xf00+i]+256*m.m[0xf20+i] for i in range(13)]==[84,183,282,378,474,567,660,750,840,936,1032,1125,1218]
for phase in (20,110):
 for cycle in (0,1):
  for joy in (0,4,8):
   m=Machine();m.stage(5);m.m[0xf80]=phase;m.m[0xfc0]=cycle;m.m[0xf60]=60;m.set('r_pump',240);m.set('z_joy',joy)
   bankcall(m,'apparatus_pump')
   direction=cycle^(phase<90);want=60 if not joy else 60+(1 if int(joy==8)==direction else -1)
   assert m.m[0xf60]==want
out['trapeze_original_pivots_and_phase_pump']=True
# Replay to a genuine release, then compare trajectories through free flight.
m=Machine();m.stage(5)
for joy,fire in route(5):
 tick(m,joy,fire)
 if m.get('flying'):break
assert m.get('f_rope_valid')>=5;m.c.at_save_slot(0);paths=[]
for later in (0,4,8):
 m.c.at_restore_slot(0);path=[]
 for _ in range(8):
  tick(m,later);assert m.get('flying');path.append((m.word('world'),m.get('f_fraction'),m.word('r_depth'),m.word('r_vertical')))
 paths.append(path)
assert paths[0]==paths[1]==paths[2]
out['trapeze_release_has_no_air_steering']=True
# Recovery trampolines remain in the original hard course; direction is sampled
# at the bounce and neutral produces a stationary recovery jump.
for rank in range(4):
 for joy,dx in [(0,0),(4,65536-84),(8,84)]:
  m=Machine();m.stage(5,rank);m.wordset('world',m.m[0xf00]+(m.m[0xf40]*3//4)+12);m.set('r_old_depth',123);m.set('z_joy',joy)
  bankcall(m,'apparatus_rescue')
  assert m.get('flying')==2 and m.get('rescue_events')==1 and m.word('f_velocity')==dx
out['recovery_contacts_on_all_four_ranks']=True
# Retry ordinary deaths from real route states, preserving apparatus identity.
retries=[]
for a in (1,3,4,5):
 m=Machine();m.stage(a)
 for joy,fire in route(a)[:600]:tick(m,joy,fire)
 assert m.get('mode')==2;rope=m.get('held_rope');before=m.word('world');m.call('hurt')
 for _ in range(160):tick(m)
 m.call('load_stage');assert m.get('checkpoint_restores')==1 and m.get('lives')==2
 if a==4:
  assert 192<=before-m.word('world')<448,(a,before,m.word('world'))
  assert not m.word('f_horse_h') and not m.word('f_horse_v')
 else:assert abs(m.word('world')-before)<220,(a,before,m.word('world'))
 if a==5:assert m.get('held_rope')==rope and not m.get('flying')
 retries.append(a+1)
out['ordinary_retry_acts']=retries
# Retained rewards: committed only on a safe monkey landing, per spring contact.
for kinds,want in [([0],200),([1],300),([0,1],1000)]:
 m=Machine();m.stage(1)
 for i,kind in enumerate(kinds):m.m[0xd920+i]=kind;m.call('monkey_reward_entry',x=i)
 assert score(m)==0;m.call('land_reward_entry');assert score(m)==want
for serial,want in [(1,100),(2,500)]:
 m=Machine();m.stage(3);m.set('f_direction',8);m.wordset('world',194)
 m.m[0x901]=200;m.m[0x911]=0;m.m[0xd961]=1;m.m[0xd981]=serial
 bankcall(m,'fidelity_ball_land',30);assert score(m)==want
m=Machine();m.stage(4);points=[]
for _ in range(5):m.call('mech_spring_reward');points.append(score(m))
assert points==[100,300,600,900,1200]
out['safe_landing_and_contact_rewards']=True
(ROOT/'build/mechanics-regression.json').write_text(json.dumps(out,indent=2));print(json.dumps(out,indent=2))
