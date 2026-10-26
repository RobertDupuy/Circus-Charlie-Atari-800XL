"""Atari800 PAL/NTSC timing: normal input replay after native stage setup.
Only initial state and the demo's input packet bytes differ in each fixture.
Active code, collisions, graphics, audio and buffering are the release bytes.
"""
from emulator import Atari,R
from cpu import Machine
import sys,time,json,struct,re,os
standard=sys.argv[1] if len(sys.argv)>1 else 'ntsc'
cases=[tuple(map(int,s.split(':'))) for s in sys.argv[2].split(',')]
reports=[]
for scene,rank in cases:
 a=2 if scene==6 else scene
 suffix=f'-rank-{rank}' if rank else ''
 inputs=json.loads((R/f'assets/routes/mechanics-route-{scene}-{rank}.json').read_text())
 packets=bytearray();previous=None;count=0
 for joy,fire in inputs+[[0,0]]*255:
  value=joy|(fire<<7)
  if value!=previous or count==255:
   if count:packets.extend([count,previous])
   previous=value;count=0
  count+=1
 if count:packets.extend([count,previous])
 rom=bytearray((R/'build/Circus-Charlie-SIC512.car').read_bytes()[16:]);base=31*16384+0x1000
 struct.pack_into('<H',rom,base+scene*2,0x900e)
 rom[base+14:base+14+len(packets)]=packets
 fixture=R/f'build/mechanics-fixture-{standard}-{scene}-{rank}.car'
 fixture.write_bytes(b'CART'+struct.pack('>III',56,sum(rom)&0xffffffff,0)+rom)
 m=Machine();m.stage(scene,rank)
 commands=[f'c 06b7 {rank:02x}',f'c 0602 {rank+1:02x}',f'c 0648 {m.word("stage_end")&255:02x} {m.word("stage_end")>>8:02x}']
 # Install the complete rank-specific initial simulation state, including
 # the held rope point; presentation/IRQ state stays owned by Atari800.
 commands += ['c 0600 01', 'c 062e 5a']
 for address,length in [(0x620,0x0e),(0x63a,0x0a),(0x6b4,5),(0x6d3,6),(0x900,0xa0),(0xf00,0x100),(0xd900,0x100),(0xdc00,0x10)]:
  for start in range(address,address+length,16):
   commands.append(f'c {start:04x} '+' '.join(f'{m.m[i]:02x}' for i in range(start,min(start+16,address+length))))
 tag=os.environ.get('CIRCUS_RUN_TAG','')
 machine=Atari(standard,f'mechanics-{tag+"-" if tag else ""}{standard}-{scene}-{rank}',cart=fixture,sound=True)
 try:
  # Enter the correct scene using the real chooser, then reload this same
  # scene with the prerecorded input stream enabled. No hidden title selector.
  def press(key):
   machine.key(key,True);time.sleep(.13);machine.key(key,False);time.sleep(.14)
  press('F4');time.sleep(.3)
  for _ in range(a):press('Right')
  press('Control_R');time.sleep(.3)
  machine.monitor(['c 06ab 01','c 0639 01']);time.sleep(.3)
  machine.monitor(commands+['m 0600 06bf'])
  setup={}
  for line in (machine.out/f'{standard}.log').read_text().splitlines():
   match=re.match(r'^([0-9A-F]{4}): ((?:[0-9A-F]{2} ){15}[0-9A-F]{2})',line)
   if match:
    for i,v in enumerate(bytes.fromhex(match[2])):setup[int(match[1],16)+i]=v
  assert (setup.get(0x600),setup.get(0x601),setup.get(0x638),setup.get(0x6ab),setup.get(0x6b7))==(1,a,scene,1,rank),('fixture initial state',setup)
  assert setup.get(0x61d)==0,('fixture already has a renderer fault before play',setup.get(0x61d))

  # Introduction plus the input stream, then the clear recording is complete.
  duration=len(inputs)/59.7+2.0
  if os.environ.get('CIRCUS_HARDWARE_FAST'):
   machine.key('F12',True);time.sleep(.15);machine.key('F12',False)
   # A delayed host key event must not truncate a valid longer input route.
   # Monitor pauses consume wall time even if turbo was not accepted.
   until=time.monotonic()+max(45,len(inputs)/59.7*2+8)
   while time.monotonic()<until:
    time.sleep(.3);machine.monitor([f'm {0x700+scene*16:04x} {0x70f+scene*16:04x}'])
    lines=(machine.out/f'{standard}.log').read_text().splitlines()
    rows=[re.match(r'^([0-9A-F]{4}): ((?:[0-9A-F]{2} ){15}[0-9A-F]{2})',l) for l in lines]
    values=[bytes.fromhex(r[2]) for r in rows if r and int(r[1],16)==0x700+scene*16]
    if values and values[-1][15]==0xa5:break
  else:
   until=time.monotonic()+duration
   while time.monotonic()<until:time.sleep(min(1,until-time.monotonic()))
  machine.shot('end.png');machine.monitor(['m 0700 0790','m dc00 dc20','m 0600 06df'],False)
 finally:machine.close()
 data={}
 for line in (machine.out/f'{standard}.log').read_text().splitlines():
  match=re.match(r'^([0-9A-F]{4}): ((?:[0-9A-F]{2} ){15}[0-9A-F]{2})',line)
  if match:data[int(match[1],16)]=bytes.fromhex(match[2])
 d=data.get(0x700+scene*16,b'\0'*16);word=lambda i:d[i]+256*d[i+1]
 host=(word(4)-word(0))&65535;frames=(word(6)-word(2))&65535
 extra=data.get(0xdc00,b'\0'*16)
 report=dict(scene=scene,rank=rank,completed=d[15]==0xa5,host_frames=host,presented_frames=frames,
 fps=round(frames*(59.922743 if standard=='ntsc' else 49.860759)/host,3) if host else 0,
 missed_deadlines=word(8),max_refresh_interval=d[10],renderer_faults=d[11],max_dirty_cells=d[12],lives=d[13],monkey_leaps=extra[1],trampoline_rescues=extra[2],pm_overflow=extra[6])
 reports.append(report);print(report,flush=True)
 (machine.out/'result.json').write_text(json.dumps(report,indent=2))
 assert report['completed'] and report['missed_deadlines']==0 and report['max_refresh_interval']==2 and report['renderer_faults']==0 and report['lives']>=3,report
