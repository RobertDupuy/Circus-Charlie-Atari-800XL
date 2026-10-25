"""Capture the unchanged cartridge at normal speed, retaining full POKEY audio."""
from emulator import Atari,R
import time,json,hashlib
m=Atari('ntsc','act1-final-video',sound=True)
try:
 m.record();m.tap('F2');start=time.monotonic()
 for seconds,label in [(4,'early'),(9,'middle'),(15,'late'),(20.8,'goal')]:
  while time.monotonic()-start<seconds:time.sleep(min(.25,seconds-(time.monotonic()-start)))
  m.shot(label+'.png')
 while time.monotonic()-start<25:time.sleep(.25)
 m.record();m.monitor(['m 0700 0790'],False)
finally:m.close()
(m.out/'cartridge.sha256').write_text(hashlib.sha256((R/'build/Circus-Charlie-SIC512.car').read_bytes()).hexdigest()+'\n')
print(m.out/'capture.avi')
