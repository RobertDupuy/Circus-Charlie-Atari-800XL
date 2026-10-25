"""Candidate reward, retry and celebration regressions on the assembled 6502."""
from cpu import Machine,ROOT
import json

def score(m):return int(bytes(m.m[0x632:0x635])[::-1].hex())
# Arcade money-hoop ladder, with its 5,000-point cap.
m=Machine();m.stage(0)
for amount in (1000,2000,3000,4000,5000,5000):
 before=score(m);m.call('complete_lion_bag');assert score(m)-before==amount
# A reverse-jump prize needs three landings and an actual contact to collect.
m=Machine();m.stage(0);m.set('lion_direction',4)
for _ in range(2):m.call('complete_lion_land');assert not m.get('secret_visible')
m.call('complete_lion_land');assert m.get('secret_visible') and score(m)==800
m.wordset('world',m.word('secret_world'));m.set('jump_pixels',0);m.call('complete_play')
assert not m.get('secret_visible') and m.get('secret_paid') and score(m)==3800
m.call('complete_play');assert score(m)==3800
# Clear awards the remaining countdown; only an unharmed lion run adds coins.
for scene in range(7):
 for hurt in (0,1):
  m=Machine();m.stage(scene);m.set('stage_hurt',hurt);bonus=int(bytes(m.m[0x630:0x632])[::-1].hex())
  # Populate both live-scene player buffers before replacing the hero with
  # the celebration. The trapeze must hide its old blue player-3 overlay.
  for back in (0,1):m.set('back',back);m.call('render_frame')
  m.call('finish_act');assert score(m)==bonus
  for t in range(223):
   m.call('game_tick');m.set('back',t&1);m.call('render_frame');assert not m.get('fault'),(scene,hurt,t)
   if scene==5:assert not m.m[0x0e03+(t&1)*32],('old trapeze player overlay',hurt,t)
  assert score(m)==bonus+(400 if scene==0 and not hurt else 0)
  if scene==4:assert m.get('finish_pony')==96
# Neutral input really selects the growing stationary bounce, in both courses.
for scene in (2,6):
 m=Machine();m.stage(scene)
 for t in range(250):
  m.set('input',0);m.set('fire_latch',0);m.call('game_tick')
  if m.get('bounce_count')>=2:break
 assert m.get('bounce_count')>=2 and m.get('f_direction')==0,(scene,t,m.get('bounce_count'))
report=dict(money_ladder=True,reverse_prize_contact=True,clear_bonus=True,conditional_lion_coins=True,pony_departure=True,celebrations_rendered=14,stationary_bounces=True)
(ROOT/'build/completion-rules.json').write_text(json.dumps(report,indent=2));print(report)
