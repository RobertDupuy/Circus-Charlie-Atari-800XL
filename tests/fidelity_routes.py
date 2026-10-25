"""Find legal fixed-trajectory input routes through the arcade object streams."""
from cpu import Machine,ROOT
import json,sys,time

def route(act,rank=0,width=80,block=4):
 m=Machine();m.stage(act,rank);c=m.c;c.at_save_slot(0);beam=[([],0)];start=time.monotonic()
 for step in range(1800):
  candidates=[];seen=set()
  for b,(history,_) in enumerate(beam):
   c.at_restore_slot(b);air=m.get('jumping')
   actions=[(8,0),(0,0),(4,0)] if act in (2,6) else [(8,0)]if air else [(8,0),(8,1),(0,0),(0,1),(4,0),(4,1)]
   for joy,fire in actions:
    c.at_restore_slot(b);n=c.at_game_steps(m.labels['game_tick'],joy,fire,block)
    assert n>0
    mode=m.get('mode')
    if mode not in (2,4):continue
    h=history+[[joy,fire]]+[[joy,0]]*(n-1)
    if mode==4:
     f=ROOT/f'assets/routes/mechanics-route-{act}-{rank}.json';f.write_text(json.dumps(h));print('CLEAR',act,rank,len(h),'sec',round(time.monotonic()-start),flush=True);return h
    w=m.word('world');height=m.get('jump_pixels')
    key=(w//2,m.get('f_phase')//2,m.get('f_direction'),m.get('jumping'),m.get('current_ball'),m.get('f_counter')//8,m.get('f_spawned'),m.get('f_idle')//16,m.get('f_tramp_arc'),m.get('bounce_count'))
    if key in seen:continue
    seen.add(key);slot=256+len(candidates)
    if slot>=1024:continue
    c.at_save_slot(slot)
    score=w+height*.03
    candidates.append((score,slot,h))
  if not candidates:raise RuntimeError(('all routes died',act,rank,step*block))
  candidates.sort(reverse=True,key=lambda v:v[0]);beam=[];selected=[];buckets={}
  for item in candidates:
   c.at_restore_slot(item[1]);bucket=(m.word('world')//10,m.get('f_direction'),m.get('f_phase')//12,m.get('jumping'))
   if buckets.get(bucket,0)>=4:continue
   buckets[bucket]=buckets.get(bucket,0)+1;selected.append(item)
   if len(selected)>=width:break
  for i,(score,slot,h)in enumerate(selected):c.at_clone_slot(i,slot);beam.append((h,score))
  if step%100==0:print('search',act,rank,step*block,round(beam[0][1]),round(time.monotonic()-start),flush=True)
 raise RuntimeError('route limit')
if __name__=='__main__':route(int(sys.argv[1]),int(sys.argv[2])if len(sys.argv)>2 else 0)
