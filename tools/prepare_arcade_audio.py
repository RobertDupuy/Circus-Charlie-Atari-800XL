"""Project executed arcade SN76489 states onto a stock four-channel POKEY.

Original source command/timing captures are made by arcade_sound.c. This script
does not invent tunes. Music keeps melody, harmony and bass; the fourth part is
percussion or doubled melody. A low note uses a joined 16-bit pair. An effect
temporarily owns that pair, leaving two music parts audible. PAL/NTSC have
separately tuned divisors and event timing. No conversion runs in the game loop.
"""
from pathlib import Path
import numpy as np,json,math
R=Path(__file__).resolve().parents[1];SRC=R/'assets/audio/source-traces';OUT=R/'assets/audio';OUT.mkdir(exist_ok=True)
SN=14318181/8
CLOCK={'ntsc':1789790,'pal':1773447}
RATE={'ntsc':59.922743*2,'pal':49.860759*2}

def volume(v,gain=10):return 0 if (int(v)&15)==15 else max(1,round(gain*10**(-(int(v)&15)/10)))
def tone(s,ch):
 p=int(s[ch*2]);v=volume(s[ch*2+1]);f=SN/(32*(p or 1024))
 return f,(v if f<14000 else 0)
def small(f,v,clock):
 d=max(0,min(255,round(clock/(56*f)-1)))
 return [d,0xa0|v] if v else [0,0]
def joined(f,v,clock,noise=False):
 # Fast-clock joined channel 3+4: divide by N+7 (and by 2 for a pure tone).
 d=max(0,min(65535,round(clock/((1 if noise else 2)*f)-7)))
 return [d&255,0,d>>8,(0x80 if noise else 0xa0)|v,0x28] if v else [0,0,0,0,0]
def music_frame(s,clock):
 lead=tone(s,0);harmony=tone(s,1);bass=tone(s,4)
 # Source harmony and bass never need a low joined voice simultaneously.
 if harmony[1] and harmony[0]<clock/(56*256):harmony,bass=bass,harmony
 result=small(*lead,clock)+small(*harmony,clock)+[0,0]+small(*bass,clock)+[0]
 if bass[1] and bass[0]<clock/(56*256):result[4:9]=joined(*bass,clock)
 else:
  extra=tone(s,2)
  noisevol=volume(s[7],8)
  if noisevol:
   mode=int(s[6]);p=(16,32,64,int(s[4]) or 1024)[mode&3]
   # Match the source noise clock, preserving the original volume envelope.
   d=max(0,min(255,round(clock/(28*(SN/(16*p)))-1)))
   result[4:6]=[d,0x80|noisevol]
  elif extra[1]:result[4:6]=small(*extra,clock)
 return bytes(result)
def effect_frame(s,clock):
 tonef,v=tone(s,5);v=volume(s[11],13) if v else 0
 noisevol=volume(s[15],12)
 if noisevol:
  mode=int(s[14]);p=(16,32,64,int(s[12]) or 1024)[mode&3]
  return bytes(joined(SN/(16*p),noisevol,clock,True))
 return bytes(joined(tonef,v,clock))

def encode(frames,loop):
 # [duration, 16-bit register mask, changed bytes], terminated by duration 0.
 # Build packs complete packets into banks and resolves end/loop links.
 packets=[];i=0;previous=bytes(len(frames[0]));loop_packet=None
 while i<len(frames):
  if i==loop:loop_packet=len(packets)
  end=i+1
  while end<len(frames) and frames[end]==frames[i] and end-i<255 and end!=loop:end+=1
  mask=(1<<len(previous))-1 if i==0 or i==loop else sum(1<<j for j in range(len(previous)) if previous[j]!=frames[i][j])
  packets.append(bytes([end-i,mask&255,mask>>8])+bytes(frames[i][j] for j in range(len(previous)) if mask>>j&1))
  previous=frames[i];i=end
 return packets,loop_packet

def main():
 manifest=[]
 for standard in ('ntsc','pal'):
  for cmd in list(range(0x13,0x1e))+list(range(0x41,0x53)):
   effect=cmd>=0x40
   if effect:
    d=np.load(SRC/f'command-{cmd:02x}.npz');raw=d['registers'];times=np.arange(len(raw))/int(d['rate']);loop=None
    active=np.any((raw[:,[11,15]]&15)<15,axis=1);last=np.where(active)[0][-1] if active.any() else 0
    raw=raw[:last+2];times=times[:last+2];duration=times[-1]+1/240
   else:
    d=np.load(SRC/f'track-{cmd:02x}.npz');raw=d['registers'];times=d['times'];loop=int(d['loop']);duration=times[-1]+8192/3579545.25
    if cmd in (0x17,0x1d):loop=None
   sample_times=np.arange(math.ceil(duration*RATE[standard]))/RATE[standard]
   indices=np.clip(np.searchsorted(times,sample_times,side='right')-1,0,len(raw)-1)
   frames=[(effect_frame if effect else music_frame)(raw[i],CLOCK[standard]) for i in indices]
   if loop is None:
    frames.append(bytes(len(frames[0])));loop_frame=None
   else:loop_frame=min(len(frames)-1,round(times[loop]*RATE[standard]))
   packets,loop_packet=encode(frames,loop_frame)
   filename=f'{standard}-{cmd:02x}.json'
   (OUT/filename).write_text(json.dumps({'packets':[list(p) for p in packets],'loop_packet':loop_packet},separators=(',',':')))
   row={'standard':standard,'command':cmd,'kind':'effect' if effect else 'music','file':filename,'frames':len(frames),'loop_frame':loop_frame,'packets':len(packets),'bytes':sum(map(len,packets))+4}
   manifest.append(row);print(row,flush=True)
 (OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
 print('Total encoded bytes:',sum(r['bytes'] for r in manifest))
if __name__=='__main__':main()
