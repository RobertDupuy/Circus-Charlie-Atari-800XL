"""C64 gameplay acceptance checks through the assembled NMOS 6502 program."""
from cpu import Machine,ROOT
from playthrough import controls,run
import json

def score(m):return int(bytes(m.m[0x632:0x635])[::-1].hex())
def score_set(m,n):
 for i,v in enumerate(bytes.fromhex(f'{n:06d}')[::-1]):m.m[0x632+i]=v
def tick(m,n=1):
 for _ in range(n):m.call('game_tick')
def playing(m):m.call('load_stage');tick(m,90);assert m.get('mode')==2

# Extra lives at exact 20k intervals; no duplicate reward on later additions.
m=Machine();m.stage(0);score_set(m,19900);m.call('add_points',a=0,y=1)
assert score(m)==20000 and m.get('lives')==4 and m.get('next_extra')==4
m.call('add_points',a=0,y=1);assert m.get('lives')==4
score_set(m,39900);m.call('add_points',a=0,y=1)
assert score(m)==40000 and m.get('lives')==5 and m.get('next_extra')==6
score_set(m,99900);m.set('next_extra',0x10);before=m.get('lives');m.call('add_points',a=0,y=1)
assert score(m)==100000 and m.get('lives')==before+1 and m.get('next_extra')==0x12
score_set(m,999900);m.set('next_extra',255);m.call('add_points',a=0,y=2)
assert score(m)==999990,'Score must saturate, not wrap'

# Authored rank 1 includes reachable mixed-monkey landing rewards.
m=Machine();m.stage(1,1)
while m.get('mode')==2:
 joy,fire=controls(m,1);m.set('input',joy);m.set('fire_latch',fire);tick(m)
assert m.get('mode')==4 and m.get('combo_awards')>=1 and m.get('leap_events')>=1

# Two independent careers, alternating on a miss and preserving water/round.
m=Machine();m.set('players',2);m.set('fire_latch',1);tick(m);playing(m)
score_set(m,12340);m.set('act',2);m.set('water',1);m.set('round',3)
m.set('tramp_clears',2);m.call('hurt');tick(m,150)
assert m.get('player')==1 and score(m)==0 and m.get('lives')==3 and m.get('act')==0
playing(m);score_set(m,54320);m.set('next_extra',6);m.set('act',5);m.set('round',2)
m.call('hurt');tick(m,150)
assert m.get('player')==0 and score(m)==12340 and m.get('lives')==2
assert (m.get('act'),m.get('water'),m.get('round'),m.get('tramp_clears'),m.get('next_extra'))==(2,1,3,2,2)
playing(m);assert m.word('bonus')==0x5000

# Last-life continue lasts 300 logic ticks; accepting resumes the same pool
# platform and score, with three lives and bounded collision grace.
m.set('lives',1);m.wordset('world',252);m.set('tramp_index',3)
m.wordset('scene_clock',200);m.wordset('hazard_clock',200)
m.call('hurt');tick(m,150)
assert m.get('mode')==6 and m.word('continue_ticks')==300
tick(m,120);assert m.word('continue_ticks')==180 and m.get('continue_secs')==3
m.set('fire_latch',1);tick(m);m.call('load_stage')
assert (m.get('player'),m.get('act'),m.get('water'),m.get('lives'))==(0,2,1,3)
assert m.word('world')==252 and m.word('scene_clock')==200 and score(m)==12340 and m.get('grace')==90

# Declining transfers to the surviving player; declining both reaches game over.
m.set('mode',2);m.set('lives',1);m.call('hurt');tick(m,150)
m.set('select_latch',1);tick(m)
assert m.get('player')==1 and score(m)==54320 and m.get('act')==5 and m.get('next_extra')==6
playing(m);m.set('lives',1);m.call('hurt');tick(m,150);tick(m,299)
assert m.get('mode')==6;tick(m);assert m.get('mode')==5
m.set('select_latch',1);tick(m);assert m.get('mode')==0

# Menu skill and independent per-act progression alter bounded difficulty.
m=Machine();m.set('input',8);tick(m);assert m.get('players')==2
m.set('input',2);tick(m);assert m.get('difficulty')==1
m.set('input',0);m.set('fire_latch',1);tick(m);m.call('load_stage');assert m.get('rank')==2
m.set('act',5);m.set('mode',4);m.set('mode_timer',1);tick(m);m.call('load_stage')
assert m.get('mode')==7 and m.get('round')==1 and m.get('rank')==2 and m.get('act')==0
# Return to the completed trapeze: it advances independently of unplayed acts.
m.set('input',4);tick(m);m.call('load_stage');assert m.get('act')==5 and m.get('rank')==3 and m.get('round')==2

# A continue must produce a playable support/checkpoint in every act, including
# the extra trampoline/pool scenes. No forced position is used during recovery.
for a in range(7):
 m=Machine();m.stage(a)
 for _ in range(120):
  joy,fire=controls(m,a);m.set('input',joy);m.set('fire_latch',fire);tick(m)
 assert m.get('mode')==2
 saved_score=score(m);saved_clock=m.word('scene_clock')
 m.set('lives',1);m.call('hurt');tick(m,150)
 m.set('fire_latch',1);tick(m);m.call('load_stage')
 assert score(m)==saved_score and m.word('scene_clock')==saved_clock
 assert m.get('water')==int(a==6) and m.get('act')==(2 if a==6 else a)
 tick(m,90);m.set('input',0);tick(m,20)
 assert m.get('mode')==2 and m.get('lives')==3,(a,m.get('mode'))

report={'extra_lives_every_20000':True,'score_saturation':True,
 'reachable_monkey_combination_and_reactive_leaps':True,
 'two_independent_player_careers':True,
 '300_tick_continue_accept_decline_expiry':True,'continue_safe_pool_checkpoint':True,
 'continue_playable_all_seven_scenes':True,'menu_and_per_act_difficulty':True}
(ROOT/'build/baseline-regression.json').write_text(json.dumps(report,indent=2));print(json.dumps(report,indent=2))
