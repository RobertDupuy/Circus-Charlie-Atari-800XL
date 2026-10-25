"""Objective audio checks; these do not replace listening on physical hardware."""
from pathlib import Path
import sys,json,math,wave
import numpy as np
from scipy.signal import resample,fftconvolve
from scipy.ndimage import uniform_filter1d
R=Path(__file__).resolve().parents[1]
source=R/'assets/audio/source-traces'
sys.path.insert(0,str(R/'tools'))
from prepare_arcade_audio import tone,music_frame,CLOCK
errors=[]
for standard,clock in CLOCK.items():
 for command in range(0x13,0x1e):
  raw=np.load(source/f'track-{command:02x}.npz')['registers']
  for state in raw[::4]:
   lead=tone(state,0);harmony=tone(state,1);bass=tone(state,4)
   if harmony[1] and harmony[0]<clock/(56*256):harmony,bass=bass,harmony
   registers=music_frame(state,clock)
   for ch,(frequency,volume) in zip((0,1,3),(lead,harmony,bass)):
    if not volume:continue
    if ch==3 and registers[8]==0x28:
     actual=clock/(2*(registers[4]+256*registers[6]+7))
    else:actual=clock/(56*(registers[ch*2]+1))
    errors.append(abs(1200*math.log2(actual/frequency)))
pitch={'samples':len(errors),'median_abs_cents':round(float(np.median(errors)),2),'p95_abs_cents':round(float(np.percentile(errors,95)),2),'max_abs_cents':round(max(errors),2)}
report={'retained_voice_pitch':pitch}
if len(sys.argv)>1:
 path=Path(sys.argv[1])
 with wave.open(str(path)) as w:
  assert w.getsampwidth()==2 and w.getnchannels()==1
  rate=w.getframerate();x=np.frombuffer(w.readframes(w.getnframes()),'<i2').astype(float)/32768
 report['recorded_pokey']={'seconds':round(len(x)/rate,3),'rms':round(float(np.sqrt(np.mean(x*x))),4),'peak':round(float(np.max(abs(x))),4),'clipped_samples':int(np.sum(abs(x)>=.999))}
 # Locate the first exact applause sample in the actual mixed POKEY recording.
 p=np.fromfile(R/'assets/audio/applause.bin',np.uint8)
 expected=np.column_stack([p>>4,p&15]).ravel().astype(float)-8;expected-=expected.mean()
 pcm_rate=1789790/228
 observed=resample(x[:30*rate],round(min(30,len(x)/rate)*pcm_rate))
 # Atari800 PCM retains a DC offset; hardware AC coupling removes it.
 observed-=uniform_filter1d(observed,257)
 corr=fftconvolve(observed,expected[::-1],mode='valid')
 energy=fftconvolve(observed**2,np.ones(len(expected)),mode='valid')
 normalized=corr/np.sqrt(np.maximum(energy,1e-20)*sum(expected**2))
 where=int(np.argmax(normalized));report['applause_in_recording']={'start_seconds':round(where/pcm_rate,3),'normalized_correlation':round(float(normalized[where]),4)}
 assert report['recorded_pokey']['clipped_samples']==0
 assert report['recorded_pokey']['rms']>.01
 assert normalized[where]>.65,report['applause_in_recording']
(R/'build/audio-quality.json').write_text(json.dumps(report,indent=2));print(json.dumps(report,indent=2))
