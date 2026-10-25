"""Search legal swing pumping, release timing and spring launches; replay inputs.
No memory edits after stage initialization in the final route verification.
"""
from cpu import Machine,ROOT
import json,time,sys

def trapeze(rank=0):
 m=Machine();m.stage(5,rank);c=m.c;c.at_save_slot(0);history=[];start=time.monotonic()
 def pump():
  i=m.get('held_rope');p=m.m[0xf80+i]*256+m.m[0xfa0+i]
  steps=[1440,1138,922,762,640,545,470,410]
  p+=steps[(m.m[0xf40+i]-32)//4];cycle=m.m[0xfc0+i]+int(p>=180*256);p%=180*256
  return 8 if ((cycle&1)^int(p<90*256)) else 4
 for part in range(32):
  c.at_restore_slot(0);before=m.get('held_rope');winner=None
  # Exercise the original amplitude pump, including timing reversals.
  for policy in ['pump','neutral']:
   c.at_restore_slot(0);c.at_save_slot(1);waiting=[]
   for delay in range(1800):
    c.at_restore_slot(1)
    if m.get('mode')!=2 or m.get('flying'):break
    joy=pump() if policy=='pump' else 0
    if m.get('f_rope_valid')>=4:
     n=c.at_game_steps(m.labels['game_tick'],joy,1,1)
     if m.get('flying'):
      for flight in range(500):
       c.at_game_steps(m.labels['game_tick'],8,0,1)
       if m.get('mode')==4 or (not m.get('flying') and m.get('held_rope')>before):
        winner=waiting+[[joy,1]]+[[8,0]]*(flight+1);break
       if m.get('mode')!=2 or not m.get('flying'):break
     if winner:break
    c.at_restore_slot(1);joy=pump() if policy=='pump' else 0
    c.at_game_steps(m.labels['game_tick'],joy,0,1);waiting.append([joy,0]);c.at_save_slot(1)
   if winner:break
  if not winner:
   raise RuntimeError(('trapeze route stuck',rank,before,len(history),m.word('world')))
  history+=winner;c.at_save_slot(0)
  print('trapeze',rank,'rope',m.get('held_rope'),'ticks',len(history),'world',m.word('world'),'rescues',m.get('rescue_events'),'sec',round(time.monotonic()-start),flush=True)
  if m.get('mode')==4:
   # A fresh reset checks the search history, without any branch snapshots.
   check=Machine();check.stage(5,rank)
   for joy,fire in history:
    check.set('input',joy);check.set('fire_latch',fire);check.call('game_tick')
   assert check.get('mode')==4 and check.get('lives')==3
   (ROOT/f'assets/routes/mechanics-route-5-{rank}.json').write_text(json.dumps(history));return history
 raise RuntimeError('route limit')
if __name__=='__main__':trapeze(int(sys.argv[1]) if len(sys.argv)>1 else 0)
