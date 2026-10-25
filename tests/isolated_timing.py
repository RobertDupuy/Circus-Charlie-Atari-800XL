from emulator import Atari
import time,json
for act,seconds in [(0,18),(5,15)]:
 a=Atari('ntsc','isolated-'+str(act+1))
 try:
  for _ in range(act):a.tap('F3');time.sleep(.15)
  a.tap('F2');time.sleep(seconds)
  a.shot('end.png');a.monitor(['m 0700 0790','m 0600 06b0'],False);time.sleep(.1)
 finally:a.close()
 print('Act',act+1,flush=True)
 for l in (a.out/'ntsc.log').read_text().splitlines():
  if l.startswith(f'{0x700+act*16:04X}:') or l.startswith('0780:'):print(l[:55],flush=True)
