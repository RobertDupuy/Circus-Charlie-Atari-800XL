from emulator import Atari
import time
x=Atari('ntsc','audio-smoke',sound=True)
try:
 x.record();time.sleep(.4);x.key('F2',True);time.sleep(.4);x.key('F2',False);time.sleep(5);x.record();x.shot('frame.png');x.monitor(['m 0600 0610','m d830 d840'],False)
finally:x.close()
print((x.out/'ntsc.log').read_text()[:2800])
