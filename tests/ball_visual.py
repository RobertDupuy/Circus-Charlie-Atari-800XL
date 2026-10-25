from emulator import Atari
import time
from pathlib import Path
a=Atari('ntsc','ball-investigate',sound=True)
try:
 a.monitor(['c 0638 02','c 0617 01']);time.sleep(.5)
 a.shot('title.png')
 a.monitor(['m 0600 06ef','m 3a80 3b70','m 3e80 3f70','m dc80 dc8f','m 4800 483f','m 5400 543f'])
finally:a.close()
