"""All acts: five TV seconds, live HUD, accept/decline/expiry and fresh title.

Final-life/rank/player setup is explicit. The assembled death/continue/title
handlers run normally; the test advances the VBI-owned TV clock independently
of game_tick, including multiple simulation calls per refresh and wraparound.
"""
from cpu import Machine,ROOT
import json

arcade=json.loads((ROOT/'build/build-profile.json').read_text())['selection']=='arcade'
results=[]

def countdown(m,scene,pal,rank,start):
 m.stage(scene,rank);m.set('pal',pal);m.wordset('host_frames',start)
 m.set('lives',1);m.wordset('score',0x1230);m.wordset('highscore',0x4560)
 m.call('hurt')
 while m.get('mode')==3:m.call('game_tick')
 assert m.get('mode')==6 and m.get('lives')==0
 assert m.word('continue_ticks')==(250 if pal else 300)
 assert m.word('continue_deadline')==(start+(250 if pal else 300))&65535

def hud(m,seconds):
 for back in (0,1):
  m.set('back',back);m.call('render_frame')
  text=bytes(m.m[0x6a00+160*back+80:0x6a00+160*back+120]).decode('ascii')
  assert text.startswith('CONTINUE '+str(seconds)),text
  assert not m.get('fault')

for scene in range(7):
 for pal in (0,1):
  for rank,start in ((0,0x00fa),(5,0xff80)):
   m=Machine();countdown(m,scene,pal,rank,start);m.c.at_save_slot(0)
   period=50 if pal else 60;frames=5*period;shown=[]
   for frame in range(frames):
    m.wordset('host_frames',(start+frame)&65535)
    # Lion and PAL can run more simulation steps in the same TV interval.
    for _ in range(3):m.call('game_tick')
    remaining=frames-frame;seconds=(remaining+period-1)//period
    assert m.get('mode')==6 and m.word('continue_ticks')==remaining
    assert m.get('continue_secs')==seconds
    if not shown or shown[-1]!=seconds:shown.append(seconds);hud(m,seconds)
   m.wordset('host_frames',(start+frames)&65535);m.call('game_tick')
   assert m.get('mode')==0 and m.get('need_stage') and not m.word('continue_ticks')
   assert m.word('highscore')==0x4560
   m.call('load_stage');m.call('render_frame')
   for _ in range(20):m.call('game_tick')
   assert m.get('mode')==0 and not m.get('fault')
   m.set('fire_latch',1);m.call('game_tick');m.call('load_stage')
   assert m.get('mode')==(7 if arcade else 1) and m.get('lives')==3 and not m.word('score')

   # A new press just before the deadline continues the same act and score.
   m.c.at_restore_slot(0);m.wordset('host_frames',(start+frames-1)&65535)
   m.set('fire_latch',1);m.call('game_tick')
   assert m.get('mode')==1 and m.get('need_stage') and m.get('lives')==3
   assert m.get('act')==(2 if scene==6 else scene) and m.get('water')==int(scene==6)
   assert m.word('score')==0x1230
   m.call('load_stage')
   while m.get('mode')==1:m.call('game_tick')
   assert m.get('mode')==2 and not m.get('fault')

   # A press on/after the deadline cannot accept an expired continue or
   # leak through to start a new game immediately after returning to title.
   for late in (0,1,7):
    m.c.at_restore_slot(0);m.wordset('host_frames',(start+frames+late)&65535)
    m.set('fire_latch',1);m.call('game_tick');assert m.get('mode')==0
    m.call('load_stage');m.call('game_tick');assert m.get('mode')==0
   m.c.at_restore_slot(0);m.set('select_latch',1);m.call('game_tick')
   assert m.get('mode')==0 and m.get('need_stage')
   results.append(dict(scene=scene,standard='pal' if pal else 'ntsc',rank=rank+1,
                       frames=frames,seconds_shown=shown,wraparound=start>65000,
                       accepted_before_deadline=True,expired_to_title=True,
                       late_fire_ignored=True,select_declines=True,fresh_game=True))

# In two-player games, an exhausted player's timeout passes to a surviving
# player. The title appears after both are out, preserving the high score.
handoffs=[]
for scene in range(7):
 for player in (0,1):
  m=Machine();m.set('players',2);m.call('newgame_entry')
  countdown(m,scene,0,0,1000);m.set('players',2);m.set('player',player)
  other=player^1;m.m[m.labels['player_records']+other*16+3]=2
  m.wordset('host_frames',1300);m.call('game_tick')
  assert m.get('player')==other and m.get('lives')==2 and m.get('mode') in (1,7)
  m.call('load_stage')
  if m.get('mode')==7:m.set('fire_latch',1);m.call('game_tick');m.call('load_stage')
  while m.get('mode')==1:m.call('game_tick')
  m.set('lives',1);m.call('hurt')
  while m.get('mode')==3:m.call('game_tick')
  m.wordset('host_frames',1600);m.call('game_tick')
  assert m.get('mode')==0 and m.get('player')==0 and m.word('highscore')==0x4560
  handoffs.append(dict(scene=scene,first_player=player+1,survivor_preserved=True,both_out_to_title=True))

# Any legacy game-over state also exits, rather than reinstating a dead end.
m=Machine();m.stage(4);m.set('mode',5);m.call('game_tick')
assert m.get('mode')==0 and m.get('need_stage')
report=dict(selection='arcade' if arcade else 'automatic',cases=results,two_player_handoffs=handoffs,
            clock_source='TV frames; 300 NTSC / 250 PAL',unbounded_gameover_removed=True)
(ROOT/'build/continue-rules.json').write_text(json.dumps(report,indent=2));print(report)
