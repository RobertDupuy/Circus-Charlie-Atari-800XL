from emulator import Atari
import time,re,json
a=Atari('ntsc','manual-input')
try:
 a.tap('Control_R');time.sleep(1.8);a.key('Right',True);time.sleep(.4);a.key('Right',False)
 a.monitor(['m 0600 06b0']);a.tap('F2');time.sleep(.4);a.monitor(['m 0600 06b0']);time.sleep(.4);a.monitor(['m 0600 06b0'])
 a.tap('F2');a.key('Right',True);a.tap('Control_R');time.sleep(.6);a.key('Right',False);a.shot('jump.png');a.monitor(['m 0600 06b0'],False)
finally:a.close()
s=(a.out/'ntsc.log').read_text();rows={}
for l in s.splitlines():
 m=re.match(r'^([0-9A-F]{4}): ((?:[0-9A-F]{2} ){15}[0-9A-F]{2})',l)
 if m:rows.setdefault(int(m[1],16),[]).append(bytes.fromhex(m[2]))
# Monitor may duplicate the final dump during termination; use the first four.
r=rows[0x600][:4];pos=rows[0x620][:4];pause=rows[0x610][:4]
assert r[0][0]==2 and pos[0][0]>60
assert pause[1][9]==pause[2][9]==1 and pos[1][:2]==pos[2][:2]
assert pause[3][9]==0 and pos[3][0]>pos[2][0]
report={'physical_fire_start':True,'physical_joystick_movement':True,'physical_option_pause_resume':True,'physical_fire_jump':pos[3][8]>0}
assert report['physical_fire_jump']
(a.out/'input.json').write_text(json.dumps(report,indent=2));print(report)
