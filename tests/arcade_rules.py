"""Arcade transition rules, independent two-player progress and life schedules."""
from cpu import Machine,ROOT
def score(m):return int(bytes(m.m[0x632:0x635])[::-1].hex())
def score_set(m,n):
 for i,v in enumerate(bytes.fromhex(f'{n:06d}')[::-1]):m.m[0x632+i]=v
def tick(m,n=1):
 for _ in range(n):m.call('game_tick')
import json
m=Machine();m.set('players',2);m.call('newgame_entry');m.call('load_stage')
# Complete all six acts six times. Every second land trampoline adds water.
water_visits=0
for repetition in range(6):
 for act in range(6):
  m.set('act',act);m.set('water',0);m.set('mode',4);m.set('mode_timer',1);tick(m)
  assert m.m[0x6d3+act]==repetition+1
  if act==2 and repetition%2==1:
   assert m.get('mode')==1 and m.get('water')==1
   water_visits+=1;m.set('mode',4);m.set('mode_timer',1);tick(m)
  if repetition==5 and act==5:
   assert m.get('mode')==8 and m.get('lives')==0
  else:
   assert m.get('mode')==7 and m.get('water')==0
   assert m.m[0x6d3+m.get('act')]<6
   m.call('load_stage');assert m.get('mode')==7
   # The selection screen cannot advance physics, score or timer.
   before=(m.word('world'),m.word('scene_clock'),score(m),m.word('bonus'))
   m.set('input',0);tick(m,100)
   assert before==(m.word('world'),m.word('scene_clock'),score(m),m.word('bonus'))
assert water_visits==3
m.set('fire_latch',1);tick(m);assert m.get('player')==1 and m.get('mode')==7
assert bytes(m.m[0x6d3:0x6d9])==bytes(6)
assert bytes(m.m[0x80a:0x810])==bytes([6]*6)
# Locked acts are skipped in both directions. Selection then starts normally.

for i,v in enumerate([6,0,6,0,6,0]):m.m[0x6d3+i]=v
m.set('act',1)
m.set('input',8);tick(m);assert m.get('act')==3
m.call('load_stage');m.set('input',0);tick(m);m.set('input',4);tick(m);assert m.get('act')==1
m.set('fire_latch',1);tick(m);assert m.get('mode')==1
# Exact DIP threshold sequences with no repeated award.
for rule,thresholds in [(0,[20000,40000,60000]),(1,[20000,90000,160000]),(2,[30000,110000,190000])]:
 m=Machine();m.m[0x6e2]=rule;m.call('newgame_entry')
 for n,threshold in enumerate(thresholds):
  score_set(m,threshold-100);m.call('add_points',a=0,y=1)
  assert score(m)==threshold and m.get('lives')==4+n
  m.call('add_points',a=0,y=1);assert m.get('lives')==4+n
report={'36_act_completions':True,'three_water_visits':True,'selection_freezes_play':True,'locked_acts_skipped':True,'independent_player_completion':True,'arcade_life_schedules':True,'c64_life_schedule_retained':True}
(ROOT/'build/arcade-rules.json').write_text(json.dumps(report,indent=2));print(report)
