"""Run the real unmodified cartridge at accelerated host speed.
Atari clocks, ANTIC DMA and deadlines remain unchanged; only host throttling is off.
Optional AVI is for visual inspection; turbo does not retain full audio.
Use demo_run.py at normal host speed for a deliverable with sound.
"""
from emulator import Atari,R
import time,json,re,sys,hashlib
standard=sys.argv[1] if len(sys.argv)>1 else 'ntsc'
name=sys.argv[2] if len(sys.argv)>2 else 'bold-check-'+standard
record='--record' in sys.argv
a=Atari(standard,name,sound=True)
reports=[];shots=[]
def memory():
 out={}
 for l in (a.out/f'{standard}.log').read_text().splitlines():
  m=re.match(r'^([0-9A-F]{4}): ((?:[0-9A-F]{2} ){15}[0-9A-F]{2})',l)
  if m:
   for j,b in enumerate(bytes.fromhex(m[2])):out[int(m[1],16)+j]=b
 return out
try:
 a.shot('title.png')
 if record:a.record()
 a.tap('F2');a.tap('F12');start=time.monotonic();i=0
 while time.monotonic()-start<180:
  time.sleep(.6);a.shot(f'frame-{i:03d}.png');i+=1
  a.monitor(['m 0600 06ef','m 0700 077f'])
  data=memory()
  if i%10==0:print(standard,'sample',i,'act',data.get(0x601),'missed',data.get(0x608),flush=True)
  if all(data.get(0x70f+j*16)==0xa5 for j in range(7)):break
 if record:a.record()
 for act in range(7):
  d=bytes(data.get(0x700+act*16+i,0) for i in range(16));word=lambda i:d[i]+256*d[i+1]
  host=(word(4)-word(0))&65535;frames=(word(6)-word(2))&65535
  reports.append(dict(act=act+1,completed=d[15]==0xa5,host_frames=host,presented_frames=frames,fps=round(frames*(59.922743 if standard=='ntsc' else 49.860759)/host,3) if host else 0,missed_deadlines=word(8),max_refresh_interval=d[10],renderer_faults=d[11],max_dirty_cells=d[12],lives=d[13]))
finally:a.close()
(a.out/'timing.json').write_text(json.dumps(reports,indent=2))
(a.out/'cartridge.sha256').write_text(hashlib.sha256((R/'build/Circus-Charlie-SIC512.car').read_bytes()).hexdigest()+'\n')
print(json.dumps(reports,indent=2),flush=True)
assert all(r['completed'] and not r['missed_deadlines'] and not r['renderer_faults'] and r['max_refresh_interval']==2 and r['lives']>=3 for r in reports), 'Hardware deadline/clear failed'
