"""Chooser controls, rendered state and repeated ordinary-input performances.

Availability/render edge cases use explicitly isolated counter fixtures. The
five consecutive Act 1 completions use only controller input and stage loading.
"""
from cpu import Machine, ROOT
import json,re

arcade=json.loads((ROOT/'build/build-profile.json').read_text())['selection']=='arcade'
def tick(m,joy=0,fire=0):
 m.set('input',joy);m.set('fire_latch',fire);m.call('game_tick')
 if m.get('need_stage'):m.call('load_stage')
def start():
 m=Machine();m.call('load_stage');tick(m,fire=1);return m

if not arcade:
 m=start();assert m.get('mode')==1 and m.get('act')==0
 assert 'chooser_load' not in m.labels and 'chooser_tick' not in m.labels
 # Stick/SELECT cannot pick an act during the introduction.
 for joy in (4,8,1,2,0):
  m.set('select_latch',1);tick(m,joy);assert m.get('act')==0 and m.get('mode')!=7
 report=dict(selection='automatic',chooser_not_compiled=True,starts_act_one=True)
else:
 # Verify all six choices from a fresh title through real stage initialization.
 for act in range(6):
  m=start();assert m.get('mode')==7
  for _ in range(act):tick(m,8);tick(m)
  assert m.get('selected')==act
  tick(m,fire=1);assert m.get('act')==act and m.get('mode')==1 and m.get('rank')==0
 m=start();tick(m,4);assert m.get('selected')==5
 for _ in range(10):tick(m,4)
 assert m.get('selected')==5,'Held direction repeats unexpectedly'
 tick(m);assert m.get('selected')==5,'Release must not move'
 tick(m,8);assert m.get('selected')==0
 # Same-column vertical navigation, with no wrap at the top or bottom.
 for column in range(3):
  m=start()
  for _ in range(column):tick(m,8);tick(m)
  tick(m,1);assert m.get('selected')==column
  tick(m);tick(m,2);assert m.get('selected')==column+3
  for _ in range(10):tick(m,2)
  assert m.get('selected')==column+3
  tick(m);tick(m,2);assert m.get('selected')==column+3
  tick(m);tick(m,1);assert m.get('selected')==column
  tick(m);m.m[0x6d3+column+3]=5;tick(m,2)
  assert m.get('selected')==column,'Down entered an exhausted panel'
  tick(m);m.m[0x6d3+column]=5;m.set('selected',column+3);tick(m,1)
  assert m.get('selected')==column+3,'Up entered an exhausted panel'
 m=start()
 # Waiting on the screen freezes all live gameplay values.
 before=(m.word('world'),m.word('scene_clock'),m.word('bonus'),bytes(m.m[0x632:0x635]))
 for _ in range(300):tick(m)
 assert before==(m.word('world'),m.word('scene_clock'),m.word('bonus'),bytes(m.m[0x632:0x635]))
 # Prepared fonts and maps must survive decoding and double-buffer publication.
 data=(ROOT/'assets/chooser.bin').read_bytes();decoded=bytearray();p=0
 while data[p]:
  n=data[p];p+=1
  if n&128:decoded.extend([data[p]]*(n&127));p+=1
  else:decoded.extend(data[p:p+n]);p+=n
 assert bytes(m.m[0x4000:0x4c00])==decoded[:3072]
 assert bytes(m.m[0x4c00:0x5800])==decoded[:3072]
 assert bytes(m.m[0x3400:0x3800])==decoded[3072:]
 # Exhausted panels show five filled pips, NO MORE, and are skipped both ways.
 for i,v in enumerate([5,0,5,0,5,0]):m.m[0x6d3+i]=v
 m.set('selected',1);tick(m,8);assert m.get('selected')==3
 tick(m);tick(m,4);assert m.get('selected')==1
 m.set('selected',0);tick(m,fire=1);assert m.get('mode')==7
 m.set('selected',1);m.set('back',0);m.call('render_frame')
 lock=bytes(map(int,re.search(r'chooser_lock_top: .byte ([0-9,]+)',(ROOT/'src/chooser-data.inc').read_text())[1].split(',')))
 assert bytes(m.m[0x3800+41:0x3800+52])==lock
 assert bytes(m.m[0x3800+364:0x3800+369])==bytes([120]*5)
 # Five real Act 1 performances, choosing Act 1 again after every clear.
 m=start();ranks=[];clears=0;frames=0;route=[];last_mode=7
 for t in range(20000):
  mode=m.get('mode')
  if mode==7 and clears==5:break
  if mode==7:
   if m.get('selected')!=0:tick(m,4);tick(m)
   tick(m,fire=1)
  elif mode==2:
   if last_mode!=2:
    rank=m.get('rank');ranks.append(rank)
    route=json.loads((ROOT/f'assets/routes/mechanics-route-0-{rank}.json').read_text())
   clock=m.word('scene_clock');assert clock<len(route)
   tick(m,*route[clock])
   if m.get('mode')==4:clears+=1
  else:tick(m)
  if t%2==0:
   m.set('back',frames&1);m.call('render_frame');frames+=1
   assert not m.get('fault')
  assert m.get('mode')!=3,'Unexpected death during repeated-act route'
  last_mode=mode
 else:raise AssertionError('Repeated-act timeout')
 assert clears==5 and ranks==[0,1,2,3,4]
 assert m.m[0x6d3]==5 and m.get('selected')==1
 tick(m,4);assert m.get('selected')==5,'Exhausted Act 1 not skipped'
 report=dict(selection='arcade',six_fresh_choices=True,hold_release_wrap=True,
  vertical_columns=3,vertical_lockout=True,vertical_no_wrap=True,
  gameplay_frozen=True,decoded_fonts_exact=True,locked_caption_and_pips=True,
  locked_choices_skipped=True,repeated_act_clears=clears,ranks=ranks,
  controller_only_repeat_route=True,rendered_frames=frames)
(ROOT/'build/chooser-rules.json').write_text(json.dumps(report,indent=2));print(report)
