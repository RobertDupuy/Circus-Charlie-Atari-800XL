"""Isolated transition fixtures; full ordinary-input careers run separately."""
from cpu import Machine, ROOT
import json
ARCADE=json.loads((ROOT/'build/build-profile.json').read_text())['selection']=='arcade'
def score(m):return int(bytes(m.m[0x632:0x635])[::-1].hex())
def score_set(m,n):
 for i,v in enumerate(bytes.fromhex(f'{n:06d}')[::-1]):m.m[0x632+i]=v
def clear(m):
 m.set('mode',4);m.set('mode_timer',1);m.set('input',0);m.call('game_tick')
m=Machine();m.set('players',2);m.call('newgame_entry')
water_visits=0
for show in range(2):
 for repetition in range(5):
  for act in range(6):
   m.set('act',act);m.set('water',0);clear(m)
   if act==2 and (show*5+repetition)%2==1:
    assert m.get('mode')==1 and m.get('water')==1
    water_visits+=1;clear(m)
   assert m.get('water')==0
   assert m.get('mode')==(7 if ARCADE else 1)
   if repetition==4 and act==5:
    assert m.get('show_cycle')==show+1
    assert bytes(m.m[0x6d3:0x6d9])==bytes(6)
   else:
    assert m.m[0x6d3+act]==repetition+1
    assert m.get('show_cycle')==show
   assert m.m[0x6d3+m.get('selected')]<5
assert water_visits==5 and m.get('lives')>0
# Score/lives and show counters survive a real player handoff.
score_set(m,123400);m.set('lives',2)
for i,v in enumerate([1,2,3,4,0,0]):m.m[0x6d3+i]=v
m.set('mode',3);m.set('mode_timer',1);m.call('game_tick')
assert m.get('player')==1 and m.get('show_cycle')==0
assert bytes(m.m[0x6d3:0x6d9])==bytes(6)
if ARCADE:
 assert m.get('mode')==7
 m.set('fire_latch',1);m.call('game_tick')
m.set('mode',3);m.set('mode_timer',1);m.call('game_tick')
assert m.get('player')==0 and m.get('show_cycle')==2
assert bytes(m.m[0x6d3:0x6d9])==bytes([1,2,3,4,0,0])
assert score(m)==123400 and m.get('lives')==2
# If trampolines is the final act, finish its pending water variation before
# reopening all thirty selections. Never enter an all-locked chooser.
m=Machine();m.call('newgame_entry');m.set('show_cycle',1);m.set('tramp_clears',9)
for i in range(6):m.m[0x6d3+i]=4 if i==2 else 5
m.set('act',2);clear(m)
assert m.get('water')==1 and m.get('mode')==1 and m.get('show_cycle')==1
clear(m)
assert not m.get('water') and m.get('show_cycle')==2
assert bytes(m.m[0x6d3:0x6d9])==bytes(6) and m.get('mode')==(7 if ARCADE else 1)
# Exact DIP threshold sequences with no repeated award.
for rule,thresholds in [(0,[20000,40000,60000]),(1,[20000,90000,160000]),(2,[30000,110000,190000])]:
 m=Machine();m.m[0x6e2]=rule;m.call('newgame_entry')
 for n,threshold in enumerate(thresholds):
  score_set(m,threshold-100);m.call('add_points',a=0,y=1)
  assert score(m)==threshold and m.get('lives')==4+n
  m.call('add_points',a=0,y=1);assert m.get('lives')==4+n
report=dict(selection='arcade' if ARCADE else 'automatic',two_thirty_act_shows=True,
 five_water_visits=True,independent_player_progress=True,water_before_rollover=True,arcade_life_schedules=True)
(ROOT/'build/arcade-rules.json').write_text(json.dumps(report,indent=2));print(report)
