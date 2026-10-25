"""Search ordinary joystick input, then replay it on the unchanged cartridge.
Saved test states select branches only during search, never during final replay.
"""
from cpu import Machine,ROOT
import json,sys,time

def pathfile(a,rank):return ROOT/f'assets/routes/mechanics-route-{a}-{rank}.json'
def route(a,rank=0,width=28,block=6):
 f=pathfile(a,rank)
 if f.exists():
  saved=json.loads(f.read_text());check=Machine();check.stage(a,rank)
  for joy,fire in saved:
   check.set('input',joy);check.set('fire_latch',fire);check.call('game_tick')
   if check.get('mode')!=2:break
  if check.get('mode')==4:return saved
  f.unlink()
 m=Machine();m.stage(a,rank);c=m.c;c.at_save_slot(0)
 beam=[([],0)];start=time.monotonic()
 actions=[(8,0),(8,1),(0,0),(0,1)] if a not in (0,4) else [(8,0),(8,1),(0,0),(0,1),(4,0),(4,1)]
 for step in range(1100):
  candidates=[];seen=set()
  for b,(history,_) in enumerate(beam):
   c.at_restore_slot(b)
   jumping=m.get('jumping')
   for joy,fire in actions:
    if fire and jumping:continue
    c.at_restore_slot(b)
    n=c.at_game_steps(m.labels['game_tick'],joy,fire,block)
    assert n>0
    mode=m.get('mode')
    if mode not in (2,4):continue
    h=history+[[joy,fire]]+[[joy,0]]*(n-1)
    if mode==4:
     f.write_text(json.dumps(h));print('route',a,rank,'clear',len(h),'seconds',round(time.monotonic()-start),flush=True);return h
    w=m.word('world');height=m.get('jump_pixels');v=m.get('velocity');v=v if v<128 else v-256
    key=(w//2,height//3,v//4,m.get('jumping'),m.get('held_rope'),m.get('flying'))
    if a==0:key+=(m.get('lion_direction'),m.get('lion_phase'),m.get('lion_wave'))
    if key in seen:continue
    seen.add(key)
    slot=256+len(candidates);assert slot<1024
    c.at_save_slot(slot)
    # Small height tie-break preserves leading and trailing jump alternatives.
    score=w+height*.03
    candidates.append((score,slot,h))
  if not candidates:
   diagnostics=[]
   for b,(history,_) in enumerate(beam):
    c.at_restore_slot(b)
    diagnostics.append(dict(world=m.word('world'),height=m.get('jump_pixels'),phase=m.get('lion_phase'),direction=m.get('lion_direction'),goal=m.word('stage_end'),rings=[(m.m[0xd90c+i],m.m[0x940+i]+256*m.m[0x950+i],m.m[0xd910+i])for i in range(4)],history=history))
   (ROOT/f'build/failed-route-{a}-{rank}.json').write_text(json.dumps(diagnostics))
   raise RuntimeError(('no surviving input route',a,rank,step*block))
  candidates.sort(reverse=True,key=lambda v:v[0]);beam=[]
  selected=candidates[:width]
  if a==0:
   selected=[];buckets={}
   for item in candidates:
    c.at_restore_slot(item[1])
    bucket=(m.word('world')//8,m.get('jumping'),m.get('lion_phase')//16,m.get('lion_direction'))
    if buckets.get(bucket,0)>=2:continue
    buckets[bucket]=buckets.get(bucket,0)+1;selected.append(item)
    if len(selected)>=width:break
  for i,(score,slot,h) in enumerate(selected):
   c.at_clone_slot(i,slot);beam.append((h,score))
  if step%100==0:print('search',a,rank,'ticks',step*block,'world',round(beam[0][1]),'sec',round(time.monotonic()-start),flush=True)
 raise RuntimeError(('route search limit',a,rank))

def trapeze(rank=0):
 f=pathfile(5,rank)
 if f.exists():
  saved=json.loads(f.read_text());check=Machine();check.stage(5,rank)
  for joy,fire in saved:
   check.set('input',joy);check.set('fire_latch',fire);check.call('game_tick')
   if check.get('mode')!=2:break
  if check.get('mode')==4:return saved
  f.unlink()
 m=Machine();m.stage(5,rank);c=m.c;c.at_save_slot(0);history=[];start=time.monotonic()
 for part in range(30):
  c.at_restore_slot(0);before=m.get('held_rope');winner=None
  for steering in [0,8,4]:
   c.at_restore_slot(0);c.at_save_slot(1)
   for delay in range(0,600,3):
    c.at_restore_slot(1)
    if delay:c.at_game_steps(m.labels['game_tick'],steering,0,3);c.at_save_slot(1)
    if m.get('mode')!=2:break
    c.at_game_steps(m.labels['game_tick'],8,1,1)
    if not m.get('flying'):continue
    for flight in range(320):
     c.at_game_steps(m.labels['game_tick'],8,0,1)
     if m.get('mode')==4 or (not m.get('flying') and m.get('held_rope')>before):
      winner=(delay,steering,flight+2);break
     if m.get('mode')!=2:break
    if winner:break
   if winner:break
  if not winner:raise RuntimeError(('trapeze stuck',rank,before,len(history)))
  delay,steering,flight=winner
  history += [[steering,0]]*delay+[[8,1]]+[[8,0]]*(flight-1)
  c.at_save_slot(0)
  print('trapeze',rank,'rope',m.get('held_rope'),'ticks',len(history),'rescues',m.get('rescue_events'),'seconds',round(time.monotonic()-start),flush=True)
  if m.get('mode')==4:
   f.write_text(json.dumps(history));return history
 raise RuntimeError('trapeze route limit')

if __name__=='__main__':
 a=int(sys.argv[1]);rank=int(sys.argv[2]) if len(sys.argv)>2 else 0
 trapeze(rank) if a==5 else route(a,rank)
