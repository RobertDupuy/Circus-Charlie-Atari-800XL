"""Convert the executed arcade DAC applause to a 4-bit POKEY intermission.
The stock XL plays at one sample per two scanlines. No PCM runs during play.
"""
from pathlib import Path
import numpy as np,json,hashlib
from scipy.signal import resample_poly
R=Path(__file__).resolve().parents[1]
a=np.load(R/'assets/audio/source-traces/dac80.npz')['writes']
t=(a[:,0]-a[0,0])/3579545.25
rate=1789790/228
samples=np.arange(round(t[-1]*rate))/rate
# DAC writes include the original changing envelope. Interpolate and preserve it.
y=np.interp(samples,t,a[:,2]).astype(float)
# Remove the changing DC pedestal (POKEY/arcade audio output is AC coupled).
from scipy.ndimage import uniform_filter1d
y-=uniform_filter1d(y,size=257,mode='nearest')
peak=max(abs(y));y=np.clip(np.round(y*(7/peak)+8),0,15).astype(np.uint8)
if len(y)%2:y=np.append(y,8)
packed=(y[::2]<<4)|y[1::2]
(R/'assets/audio/applause.bin').write_bytes(packed.astype(np.uint8).tobytes())
(R/'assets/audio/applause.json').write_text(json.dumps({'source_command':'80','samples':len(y),'bytes':len(packed),'ntsc_rate':rate,'pal_rate':1773447/228,'ntsc_seconds':len(y)/rate,'pal_seconds':len(y)/(1773447/228),'source':'Executed original audio CPU DAC writes; not a substitute noise effect','source_sha256':hashlib.sha256(a.tobytes()).hexdigest()},indent=2))
print(len(y),len(packed))
