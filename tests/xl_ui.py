"""Native title/chooser controls, all six entries, and static PAL/NTSC raster.

Only the final lockout-caption check injects an isolated availability fixture.
All title, reset, navigation, stage-entry and raster checks use normal controls.
"""
from emulator import Atari,R
import time,re,json,argparse,subprocess,hashlib
import numpy as np
parser=argparse.ArgumentParser();parser.add_argument('standard',choices=['ntsc','pal'],nargs='?',default='ntsc')
args=parser.parse_args();arcade=json.loads((R/'build/build-profile.json').read_text())['selection']=='arcade'
x=Atari(args.standard,'chooser-ui-'+args.standard,sound=True)
def tap(key):
 x.key(key,True);time.sleep(.15);x.key(key,False);time.sleep(.12)
x.tap=tap
def monitor(commands,resume=True):
 # Synchronize entry/exit instead of queueing the next command while SDL is
 # still reopening its window. Otherwise a fast host can read an old dump.
 log=x.out/(args.standard+'.log');offset=log.stat().st_size
 x.tap('F8');deadline=time.monotonic()+3
 while b' PC=' not in log.read_bytes()[offset:]:
  assert time.monotonic()<deadline,'Emulator monitor did not open'
  time.sleep(.02)
 for command in commands:
  x.p.stdin.write((command+'\n').encode());x.p.stdin.flush();time.sleep(.05)
 if resume:
  x.p.stdin.write(b'cont\n');x.p.stdin.flush();deadline=time.monotonic()+3
  while b'Video Mode:' not in log.read_bytes()[offset:]:
   assert time.monotonic()<deadline,'Emulator monitor did not resume'
   time.sleep(.02)
  time.sleep(.15)
x.monitor=monitor
def shot(name):
 # Atari800 recreates its SDL window on returning from the monitor. Allow
 # it to present a frame before reading the window's initially black pixels.
 time.sleep(.2)
 return x.shot(name)
def state():
 log=x.out/(args.standard+'.log');offset=log.stat().st_size
 x.monitor(['m 0600 06ff']);deadline=time.monotonic()+3
 while time.monotonic()<deadline:
  rows={}
  for line in log.read_bytes()[offset:].decode(errors='replace').splitlines():
   m=re.match(r'^([0-9A-F]{4}): ((?:[0-9A-F]{2} ){15}[0-9A-F]{2})',line)
   if m:
    for i,v in enumerate(bytes.fromhex(m[2])):rows[int(m[1],16)+i]=v
  if all(addr in rows for addr in range(0x600,0x700)):return rows
  time.sleep(.02)
 raise AssertionError('Emulator monitor did not return a fresh complete dump')
r=dict(standard=args.standard,selection='arcade' if arcade else 'automatic',car_sha256=hashlib.sha256((R/'build/Circus-Charlie-SIC512.car').read_bytes()).hexdigest())
try:
 d=state();assert d[0x600]==0 and d[0x6b4]==1 and d[0x6e2]==1
 shot('title-one-player.png');x.tap('F3');time.sleep(.15);assert state()[0x6b4]==2
 shot('title-two-players.png');x.tap('Left');time.sleep(.15);assert state()[0x6b4]==1
 x.tap('Right');time.sleep(.15);assert state()[0x6b4]==2
 x.tap('F4');time.sleep(.5 if arcade else 1.8);d=state()
 assert d[0x600]==(7 if arcade else 2) and d[0x6b4]==2 and d[0x601]==0
 if arcade:
  menu_pixels=np.array(shot('chooser.png'))
  # Inspect the saved pixels directly; every choice must retain all icons.
  icon_mask=np.zeros(menu_pixels.shape[:2],bool)
  body_y=48+(menu_pixels.shape[0]-448)//2
  for panel in range(6):
   y=body_y+(panel//3)*176;left=16+(panel%3)*208
   icon_mask[y+32:y+140,left+20:left+188]=True
  x.record();time.sleep(2.2);x.record()
  # Holding and releasing the stick moves only once; wrap remains available.
  x.key('Left',True);time.sleep(.35);x.key('Left',False);time.sleep(.15)
  assert state()[0x638]==5
  time.sleep(.15);assert state()[0x638]==5
  x.tap('Right');time.sleep(.15);assert state()[0x638]==0
  for column in range(3):
   x.tap('Down');time.sleep(.15);assert state()[0x638]==column+3
   x.tap('Up');time.sleep(.15);assert state()[0x638]==column
   if column<2:x.tap('Right');time.sleep(.15)
 entries=[]
 for act in range(6 if arcade else 1):
  x.tap('F5');time.sleep(1.3);d=state();assert d[0x600]==0 and d[0x6b4]==1
  x.tap('Control_R');time.sleep(.4 if arcade else 1.8)
  if arcade:
   assert state()[0x600]==7
   for _ in range(act):x.tap('Right');time.sleep(.08)
   assert state()[0x638]==act
   choice_pixels=np.array(shot('choice-'+str(act+1)+'.png'))
   assert np.array_equal(choice_pixels[icon_mask],menu_pixels[icon_mask]),('Icons changed after reset/navigation',act)
   x.tap('Control_R');time.sleep(1.8)
  d=state();assert d[0x600]==2 and d[0x601]==act and not d[0x6ab]
  assert d[0x610]==int(args.standard=='pal')
  assert not d[0x608] and not d[0x609] and not d[0x61d] and d[0x68c]<=2
  shot('act-'+str(act+1)+'.png');entries.append(act+1)
 if arcade:
  x.tap('F5');time.sleep(1.3);x.tap('F4');time.sleep(.4)
  # Explicit isolated counter fixture, without editing cartridge code.
  x.monitor(['c 06d3 05 00 05 00 05 00','c 0638 01','c 06d9 00'])
  x.tap('Right');time.sleep(.15);assert state()[0x638]==3
  time.sleep(.15);assert state()[0x638]==3
  x.tap('Left');time.sleep(.15);assert state()[0x638]==1
  locked_pixels=np.array(shot('locked-acts.png'))
  assert np.array_equal(locked_pixels[icon_mask],menu_pixels[icon_mask]),'Lockout altered the icons'
  x.tap('Control_R');time.sleep(1.8);d=state();assert d[0x600]==2 and d[0x601]==1
 r.update(title_player_controls=True,start_and_fire=True,reset_returns_title=True,
          natural_stage_entries=entries,lockout_fixture=arcade)
finally:x.close()
if arcade:
 stream=json.loads(subprocess.check_output(['ffprobe','-v','error','-select_streams','v:0','-show_entries','stream=width,height','-of','json',str(x.out/'capture.avi')]))['streams'][0]
 raw=subprocess.check_output(['ffmpeg','-v','error','-i',str(x.out/'capture.avi'),'-f','rawvideo','-pix_fmt','rgb24','-'])
 frames=np.frombuffer(raw,np.uint8).reshape(-1,stream['height'],stream['width'],3)[2:-2]
 assert len(frames)>80
 changed=np.any(frames!=frames[0],axis=(0,2,3))
 r.update(static_menu_frames=len(frames),varying_rows=np.flatnonzero(changed).tolist())
 assert not changed.any(),'Chooser has unstable raster rows'
(x.out/'ui.json').write_text(json.dumps(r,indent=2));print(r)
