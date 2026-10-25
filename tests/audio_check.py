from emulator import Atari
import time,wave,json
import numpy as np
x=Atari('ntsc','audio-check',True)
for old in x.out.glob('*.wav'):old.unlink()
def toggle():
 x.key('Alt_L',True);x.tap('w');x.key('Alt_L',False)
try:
 toggle();x.tap('Control_R');time.sleep(1.8);x.key('Right',True);x.tap('Control_R');time.sleep(1);x.key('Right',False);time.sleep(2);x.monitor(['m 0600 0610','quit'],False);time.sleep(.4)
finally:x.close()
f=next(x.out.glob('*.wav'))
with wave.open(str(f)) as w:
 p=w.getparams();raw=w.readframes(w.getnframes())
a=np.frombuffer(raw,dtype='<i2' if p.sampwidth==2 else 'u1').astype(float)
if p.sampwidth==1:a-=128
r={'file':f.name,'sample_rate':p.framerate,'seconds':p.nframes/p.framerate,'peak':float(abs(a).max()),'rms':float(np.sqrt((a*a).mean()))}
r['variation_rms']=float(a.std())
assert r['variation_rms']>5 and r['seconds']>=0.25
# Short PCM smoke check; the dummy sound device need not run at wall-clock speed.
(x.out/'audio.json').write_text(json.dumps(r,indent=2));print(r)
