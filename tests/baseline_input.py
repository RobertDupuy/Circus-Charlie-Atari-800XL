"""Real keyboard events exercise both joystick ports and the continue prompt.
The monitor only speeds up the first handoff and sets one life for the next
ordinary collision. It never supplies the input being checked.
"""
from emulator import Atari
import time,re,json

a=Atari('ntsc','baseline-input')
snapshots=[]
def snapshot():
 a.monitor(['m 0600 06df'])
 data={}
 for line in (a.out/'ntsc.log').read_text().splitlines():
  m=re.match(r'^([0-9A-F]{4}): ((?:[0-9A-F]{2} ){15}[0-9A-F]{2})',line)
  if m:
   for i,v in enumerate(bytes.fromhex(m[2])):data[int(m[1],16)+i]=v
 snapshots.append(data)
 return data
def world(d):return d[0x620]+256*d[0x621]
def await_play():
 # Font loading precedes the 90-tick introduction. Do not assume host wall
 # time is enough when other emulator captures are running concurrently.
 for _ in range(12):
  d=snapshot()
  if d[0x600]==2:return d
  time.sleep(.25)
 raise AssertionError(('Introduction did not finish',d[0x600],d[0x62e]))
try:
 a.tap('Right');a.tap('Down');time.sleep(.15);a.shot('menu-2p-hard.png');menu=snapshot()
 assert menu[0x6b4]==2 and menu[0x6b6]==1
 a.tap('Control_R');time.sleep(1.8);await_play()
 a.key('Right',True);time.sleep(.25);a.key('Right',False);p1=snapshot()
 assert p1[0x600]==2 and p1[0x6b5]==0 and world(p1)>60
 a.monitor(['c 0600 03','c 0603 02','c 062e 01','c 063a 01'])
 time.sleep(1.8);p2=await_play();assert p2[0x6b5]==1
 a.key('Right',True);time.sleep(.25);a.key('Right',False);wrong=snapshot()
 assert world(wrong)==world(p2),'Player 1 stick moved Player 2'
 a.key('d',True);time.sleep(.25);a.key('d',False);right=snapshot()
 assert world(right)>world(p2),'Player 2 stick did not move Player 2'
 a.tap('Control_L');time.sleep(.2);jump=snapshot();assert jump[0x628]>0
 # Let the jump finish, then lose the final life through a real collision.
 time.sleep(.8);a.monitor(['c 0603 01'])
 a.key('d',True);time.sleep(1.5);a.key('d',False);time.sleep(2.5)
 prompt=snapshot();a.shot('continue-player-2.png')
 assert prompt[0x600]==6 and prompt[0x603]==0
 a.tap('Control_R');wrongfire=snapshot();assert wrongfire[0x600]==6
 a.tap('Control_L');time.sleep(1.8);continued=await_play()
 assert continued[0x600]==2 and continued[0x603]==3 and continued[0x6b5]==1
 a.shot('continued-player-2.png')
finally:a.close()
report={'menu_2p_hard':True,'port_1_start_and_movement':True,
 'port_2_turn':True,'inactive_port_ignored':True,'port_2_move_and_jump':True,
 'natural_final_life_collision':True,'continue_only_active_fire':True,
 'continued_same_player_with_three_lives':True}
(a.out/'input.json').write_text(json.dumps(report,indent=2));print(json.dumps(report,indent=2))
