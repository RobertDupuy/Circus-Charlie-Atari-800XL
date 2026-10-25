import ctypes,re,subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
if not (ROOT/'build/atari_cpu.so').exists():
 subprocess.run(['cc','-shared','-O2','-fPIC',str(ROOT/'tests/atari_cpu.c'),'-o',str(ROOT/'build/atari_cpu.so')],check=True)
class Machine:
 def __init__(self,cart=None,labels=None):
  self.c=ctypes.CDLL(str(ROOT/'build/atari_cpu.so'))
  self.c.at_memory.restype=ctypes.POINTER(ctypes.c_uint8)
  self.c.at_call.restype=ctypes.c_int64;self.c.at_run.restype=ctypes.c_int64
  self.labels={m[2]:int(m[1],16) for l in Path(labels or ROOT/'build/main.lbl').read_text().splitlines() if (m:=re.match(r'al ([0-9A-F]+) \.(.+)',l))}
  for n,h in re.findall(r'^(\w+)=\$([0-9A-Fa-f]+)',(ROOT/'src/memory.inc').read_text(),re.M):self.labels[n]=int(h,16)
  assert self.c.at_init(str(cart or ROOT/'build/Circus-Charlie-SIC512.car').encode(),0xbf00)
  assert self.c.at_run(0x1000,1000000)>0
  self.m=self.c.at_memory()
 def call(self,n,a=0,x=0,y=0):
  cyc=self.c.at_call(self.labels[n],a,x,y)
  assert cyc>0,(n,cyc,hex(self.c.at_pc()))
  return cyc
 def get(self,n):return self.m[self.labels[n]]
 def set(self,n,v):self.m[self.labels[n]]=v
 def word(self,n):p=self.labels[n];return self.m[p]+256*self.m[p+1]
 def wordset(self,n,v):p=self.labels[n];self.m[p]=v&255;self.m[p+1]=(v>>8)&255
 def stage(self,a,rank=0):
  self.m[0x603]=3;self.m[0x600]=1;self.m[0x601]=2 if a==6 else a;self.m[0x60e]=1
  self.set('water',int(a==6))
  self.m[0x6d3+(2 if a==6 else a)]=rank;self.set('round',rank+1);self.set('difficulty',0);self.set('next_extra',2);self.set('players',1)
  self.call('load_stage');self.m[0x600]=2
if __name__=='__main__':
 m=Machine()
 for a in range(6):
  m.stage(a)
  print(a,'render',m.call('render_frame'),'fault',m.get('fault'),'dirty',m.m[0x657],flush=True)
