"""Full native-game demo through real Atari800, with hardware timing counters."""
import sys,time,re,json,subprocess
from emulator import Atari,R
standard=sys.argv[1] if len(sys.argv)>1 else 'ntsc'
a=Atari(standard,sys.argv[2] if len(sys.argv)>2 else 'audio-full-'+standard,sound=True)
try:
 a.shot('title.png');a.record();time.sleep(3);a.tap('F2');start=time.monotonic();lastprint=-1
 while time.monotonic()-start<285:
  elapsed=time.monotonic()-start
  if int(elapsed)//20!=lastprint:
   lastprint=int(elapsed)//20;print(standard,'seconds',round(elapsed),flush=True)
   a.shot(f'frame-{int(elapsed):03d}.png')
  time.sleep(.2)
 a.record();time.sleep(.2)
 a.shot('finished.png');a.monitor(['m 0600 06e0','m 0700 0790','m d800 d840'],False)
 time.sleep(.2)
finally:a.close()
if standard=='ntsc':
 subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-y','-i',str(a.out/'capture.avi'),'-vf','scale=iw*2:ih*2:flags=neighbor','-c:v','libx264','-preset','fast','-crf','20','-pix_fmt','yuv420p','-c:a','aac','-b:a','160k','-movflags','+faststart',str(a.out/'Circus-Charlie-playthrough.mp4')],check=True)
text=(a.out/f'{standard}.log').read_text();data={}
for l in text.splitlines():
 m=re.match(r'^([0-9A-F]{4}): ((?:[0-9A-F]{2} ){15}[0-9A-F]{2})',l)
 if m:data[int(m[1],16)]=bytes.fromhex(m[2])
reports=[]
for act in range(7):
 d=data.get(0x700+act*16,b'\0'*16);word=lambda i:d[i]+256*d[i+1]
 host=(word(4)-word(0))&65535;frames=(word(6)-word(2))&65535
 reports.append({'act':act+1,'completed':d[15]==0xa5,'host_frames':host,'presented_frames':frames,'fps':round(frames*(59.922743 if standard=='ntsc' else 49.860759)/host,3) if host else 0,'missed_deadlines':word(8),'max_refresh_interval':d[10],'renderer_faults':d[11],'max_dirty_cells':d[12],'lives':d[13]})
(a.out/'timing.json').write_text(json.dumps(reports,indent=2));print(json.dumps(reports,indent=2))
assert all(r['completed'] and r['missed_deadlines']==0 and r['renderer_faults']==0 and r['max_refresh_interval']==2 and r['lives']>=3 for r in reports), 'Hardware playthrough or frame deadline failed'
