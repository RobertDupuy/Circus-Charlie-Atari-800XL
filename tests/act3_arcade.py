"""Act 3 reference checks against recorded MAME trajectories and actor waves."""
from cpu import Machine, ROOT
import json,sys
import numpy as np
sys.path.insert(0,str(ROOT/"tools"))
import act3_assets
reference=json.loads((ROOT/'evidence/act3-mame.json').read_text())
source=json.loads((ROOT/'assets/act3-arcade.json').read_text())

def bankcall(m,name):
 address=m.labels[name]
 code=[0xa9,0x3a,0x8d,0,0xd5,0x20,address&255,address>>8,0x60]
 for i,v in enumerate(code):m.m[0x300+i]=v
 m.labels['act3_probe']=0x300
 return m.call('act3_probe')
def put(m,name,i,value):m.m[m.labels[name]+i]=value

def projectile(kind,phase=0,x=60):
 m=Machine();m.stage(2);m.set('grace',1)
 put(m,'t_active',0,kind);put(m,'t_proj_kind',0,kind)
 put(m,'t_proj_xlo',0,x&255);put(m,'t_proj_xhi',0,x>>8)
 put(m,'t_proj_phase',0,phase)
 return m

for kind,name in [(1,'fire'),(2,'sword')]:
 m=projectile(kind);observed=[]
 for expected in reference[name]['y']:
  bankcall(m,'tramp_projectile_step');observed.append(m.get('t_proj_y'))
 assert observed==reference[name]['y'],(name,observed)
 if kind==1:
  bankcall(m,'tramp_projectile_step');assert m.get('t_proj_kind')==0
 else:
  bankcall(m,'tramp_projectile_step');assert m.get('t_proj_y')==204
  for _ in range(16):bankcall(m,'tramp_projectile_step')
  assert m.get('t_proj_phase')==130
  bankcall(m,'tramp_projectile_step')
  assert m.get('t_proj_phase')==1 and m.get('t_proj_y')==204

# Independently observed spawns, after the arcade's scroll-to-Atari conversion.
m=Machine();m.stage(2)
positions=[(page*256+offset+239)*3//4 for page in range(8) for offset in (62,142,234)]
for actor in reference['actor_spawns']:
 position=actor['left']*3//4;i=positions.index(position)
 m.wordset('world',position-119);m.set('grace',1);bankcall(m,'tramp_attacks')
 assert m.m[m.labels['t_active']+i]==actor['kind'],actor
 assert m.get('t_period')==actor['period']

# Both boundaries of the active window, including reversing through old waves.
window_cases=0;pm_max=0;bitmap_cases=0
art={};act3_assets.sprites(art,{})
for rank in range(4):
 m=Machine();m.stage(2,rank);schedule=sum(source['schedules'][rank+1][1:9],[])
 for world in list(range(60,1770,3))+list(range(1767,59,-7)):
  m.wordset('world',world);m.set('grace',1);bankcall(m,'tramp_attacks')
  expected=[k if p-119<=world<p+84 else 0 for p,k in zip(positions,schedule)]
  actual=list(m.m[m.labels['t_active']:m.labels['t_active']+24])
  assert actual==expected,(rank,world,actual,expected)
  window_cases+=1
 # Holding position must keep attacks running and every live visible shot drawn.
 for world in range(180,1660,27):
  m=Machine();m.stage(2,rank);m.wordset('world',world);m.call('update_camera')
  for tick in range(220):
   m.set('grace',1);bankcall(m,'tramp_attacks')
   m.set('back',tick&1);m.call('render_frame')
   assert not m.get('fault'),(rank,world,tick,'glyph overflow')
   assert not m.get('mech_pm_overflow'),(rank,world,tick,'hidden projectile')
   expected=np.zeros((4,256),np.uint8);visible=0
   for slot in range(7):
    kind=m.m[0xf00+slot];phase=m.m[0xf20+slot]
    x=m.m[0xf30+slot]+256*m.m[0xf40+slot]-m.word('camera')
    if not kind or not -7<=x<160 or kind==2 and phase>114:continue
    visible+=1;p=m.m[0xf90+slot]
    assert p<4,(rank,world,tick,slot,'unassigned visible shot')
    if tick%11:continue
    owner=m.m[0xf10+slot];drift=m.m[0xf30+slot]+256*m.m[0xf40+slot]-positions[owner]-3
    pixels=art[(82 if kind==1 else 110)+((phase>>2)&1)]!=0
    if kind==2:
     shifted=np.zeros((16,16),bool)
     for y,x in zip(*np.nonzero(pixels)):shifted[y,x+drift]=True
     pixels=shifted.reshape(16,8,2).any(axis=2)
    rows=np.array([sum(int(v)<<(7-i) for i,v in enumerate(row)) for row in pixels],np.uint8)
    top=m.m[0xf50+slot]-(40 if kind==1 else 24)
    expected[p,top:top+len(rows)]|=rows
   pm_max=max(pm_max,visible)
   if tick%11==0:
    actual=np.array(m.m[0x5c00+(tick&1)*0x800:0x6000+(tick&1)*0x800],np.uint8).reshape(4,256)
    assert np.array_equal(actual,expected),(rank,world,tick,'projectile pixels or old trails')
    assert max(m.m[0x668+(tick&1)*4+p] for p in range(4))<=132
    bitmap_cases+=1

# A plume/blade at Charlie's centre hurts; an adjacent clear lane is safe.
for kind,phase,height in [(1,24,19),(2,24,32)]:
 for dx,expected in [(0,3),(8,2)]:
  m=projectile(kind,phase,56+dx);m.set('grace',0);m.set('jump_pixels',height)
  bankcall(m,'tramp_projectile_step');assert m.get('mode')==expected,(kind,dx,m.get('mode'))
  if expected==3:
   assert m.get('tramp_death_reason')==kind+1
   assert m.get('jump_pixels')==height, 'Show the actual projectile contact before falling'
   m.call('render_frame')
   hud=bytes(m.m[0x6a00+m.get('back')*160+80:0x6a00+m.get('back')*160+120])
   assert (b'HIT THE FIRE!' if kind==1 else b'HIT THE BLADE!') in hud

# Retry discards attacks and restores the last actual trampoline, with grace.
m=projectile(1);m.set('tramp_index',12);m.call('tramp_resume_entry')
assert m.get('tramp_index')==12 and m.get('grace')==90
assert all(m.m[m.labels['t_proj_kind']+i]==0 for i in range(7))
assert m.word('stage_end')==1656

# Interrupts inside the busiest shared-player compositor preserve its pixels.
m=Machine();m.stage(2,2);m.wordset('world',1350);m.call('update_camera')
for _ in range(104):m.set('grace',1);bankcall(m,'tramp_attacks')
m.set('back',0);m.call('render_frame')
m.call('audio_init');m.call('audio_start',a=2,x=0);m.call('audio_start',a=14,x=1)
nmi=m.labels['nmi'];m.m[0xfffa]=nmi&255;m.m[0xfffb]=nmi>>8
m.set('loading',0);m.set('ready',0);m.set('phase',0);m.c.at_save_slot(0)
cycles=m.call('tramp_prepare_entry');expected=bytes(m.m[0x5800:0x6800]);interrupts=0
for kind in (0x40,0x80):
 for delay in range(20,cycles,149):
  m.c.at_restore_slot(0);m.m[0xd40f]=kind;m.set('dli_index',1)
  m.c.at_force_nmi(delay);m.call('tramp_prepare_entry')
  assert bytes(m.m[0x5800:0x6800])==expected,('projectile compositor interrupt',kind,delay)
  interrupts+=1

report=dict(mame_fire_samples=len(reference['fire']['y']),mame_sword_samples=len(reference['sword']['y']),observed_actor_spawns=len(reference['actor_spawns']),bidirectional_window_cases=window_cases,stationary_attack_frames=4*len(range(180,1660,27))*220,max_visible_projectiles=pm_max,projectile_bitmap_cases=bitmap_cases,projectile_interrupt_cases=interrupts)
(ROOT/'build/act3-arcade.json').write_text(json.dumps(report,indent=2));print(report)
