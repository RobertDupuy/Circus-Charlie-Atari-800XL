"""Physical Atari800 title, player selection, start/fire and inter-act controls."""
from emulator import Atari,R
import time,re,json
x=Atari('ntsc','xl-ui',sound=True)
def state():
 x.monitor(['m 0600 06ef']);rows={}
 for line in (x.out/'ntsc.log').read_text().splitlines():
  m=re.match(r'^([0-9A-F]{4}): ((?:[0-9A-F]{2} ){15}[0-9A-F]{2})',line)
  if m:
   for i,v in enumerate(bytes.fromhex(m[2])):rows[int(m[1],16)+i]=v
 return rows
try:
 d=state();assert d[0x600]==0 and d[0x6b4]==1 and d[0x6e2]==1
 x.shot('title-one-player.png');x.tap('F3');time.sleep(.2);assert state()[0x6b4]==2
 x.shot('title-two-players.png');x.tap('Left');time.sleep(.2);assert state()[0x6b4]==1
 x.tap('Right');time.sleep(.2);assert state()[0x6b4]==2
 x.tap('F4');time.sleep(1.8);d=state();assert d[0x600]==2 and d[0x6b4]==2 and d[0x601]==0
 x.tap('F5');time.sleep(2);d=state();assert d[0x600]==0 and d[0x6b4]==1
 x.tap('Control_R');time.sleep(1.8);assert state()[0x600]==2
 x.monitor(['c 0600 07','c 0601 01','c 06d3 06 00 06 00 06 00','c 06d9 00','c 0639 01'])
 time.sleep(.3);x.tap('Right');time.sleep(.2);d=state();assert d[0x600]==7 and d[0x601]==3
 time.sleep(.2);assert state()[0x601]==3,'Release must not advance the cursor'
 x.tap('Left');time.sleep(.2);assert state()[0x601]==1
 x.shot('act-selection.png');x.tap('Control_R');time.sleep(2);d=state();assert d[0x600]==2 and d[0x601]==1
finally:x.close()
r={'select_toggles_players':True,'stick_selects_players':True,'start_starts_game':True,'fire_starts_game':True,'stick_skips_locked_acts':True,'stick_release_no_extra_move':True,'fire_enters_selected_act':True,'xl_reset_returns_title':True}
(x.out/'ui.json').write_text(json.dumps(r,indent=2));print(r)
