"""Normal-speed native capture of Act 1 flames and the complete repaired Act 3."""
from emulator import Atari,R
import time,subprocess,json,hashlib
parts=[]
for scene,seconds in ((0,13),(2,33)):
 a=Atari('ntsc',f'act3-release-video-{scene}',sound=True)
 try:
  a.record();a.monitor([f'c 0638 {scene:02x}','c 0618 01'])
  start=time.monotonic();i=0
  while time.monotonic()-start<seconds:
   time.sleep(.5)
   if time.monotonic()-start>=i*2:
    a.shot(f'frame-{i:02}.png');i+=1
  a.record();a.monitor(['m 0700 0790','gtia'],False)
 finally:a.close()
 parts.append(a.out/'capture.avi')
listing=R/'build/act3-video-parts.txt'
listing.write_text(''.join("file '"+str(p)+"'\n" for p in parts))
target=R/'build/Circus-Charlie-Act3-and-Ring-Flames.mp4'
subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-y','-f','concat','-safe','0','-i',str(listing),'-vf','scale=iw*2:ih*2:flags=neighbor','-c:v','libx264','-preset','fast','-crf','20','-pix_fmt','yuv420p','-c:a','aac','-b:a','160k','-movflags','+faststart',str(target)],check=True)
print(target)
(R/'build/act3-video.json').write_text(json.dumps(dict(car_sha256=hashlib.sha256((R/'build/Circus-Charlie-SIC512.car').read_bytes()).hexdigest(),normal_host_speed=True,sound=True,sections=['Act 1 ring flames','Complete Act 3 normal demo']),indent=2))
