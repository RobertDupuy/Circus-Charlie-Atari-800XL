"""NTSC/PAL controls, natural misses, retry timing, game over and restart.

The late-horse scenario restores a checkpoint obtained from an ordinary-input
CPU replay which misses the final jump. The cartridge code is never patched;
all subsequent lives are lost naturally and the continue timer expires.
"""
from emulator import Atari,R
from cpu import Machine
import argparse,json,re,time,hashlib
p=argparse.ArgumentParser();p.add_argument('standard',choices=['ntsc','pal']);a=p.parse_args()
# Obtain the exact real-death checkpoint before starting native emulation.
m=Machine();m.stage(4);seq=json.loads((R/'assets/routes/mechanics-route-4-0.json').read_text());last=max(i for i,(_,f) in enumerate(seq)if f)
for i,(joy,fire) in enumerate(seq):
 m.set('input',joy);m.set('fire_latch',fire if i<last else 0);m.call('game_tick')
 if m.get('mode')!=2:break
assert m.get('mode')==3 and m.word('world')>=3620
checkpoint=bytes(m.m[0xda00:0xdb00])
x=Atari(a.standard,'ball-horse-'+a.standard,sound=True);samples=[];results=[]
def press(key):x.key(key,True);time.sleep(.22);x.key(key,False);time.sleep(.18)
def sample():
 x.monitor(['m 0600','m 0970','m dc00']);d={}
 for line in (x.out/(a.standard+'.log')).read_text().splitlines():
  hit=re.match(r'^([0-9A-F]{4}): ((?:[0-9A-F]{2} ){15}[0-9A-F]{2})',line)
  if hit:
   for j,v in enumerate(bytes.fromhex(hit[2])):d[int(hit[1],16)+j]=v
 w=lambda k:d[k]+256*d[k+1]
 r=dict(mode=d[0x600],act=d[0x601],selected=d[0x638],need_stage=d[0x639],lives=d[0x603],world=w(0x620),feet=d[0x629],drop=d[0x6f2],
        fault=d[0x61d],missed=w(0x608),interval=d[0x68c],clock=w(0x62c),loading=d[0x61a],restores=d[0xdc07])
 samples.append(r);return r
def until(predicate,seconds=10):
 end=time.monotonic()+seconds
 while time.monotonic()<end:
  r=sample()
  if predicate(r):return r
  time.sleep(.2)
 raise AssertionError(('State transition did not arrive',r))
def choose(act):
 until(lambda r:r['mode']==7 and not r['need_stage'] and not r['loading'])
 press('Down');until(lambda r:r['selected']==3)
 if act==4:press('Right');until(lambda r:r['selected']==4)
 press('Control_R')
 return until(lambda r:r['mode'] in (1,2) and r['act']==act and not r['loading'] and not r['need_stage'])
try:
 for name,act in [('balls',3),('horse-early',4),('horse-late',4)]:
  press('F5');until(lambda r:r['mode']==0 and not r['loading'])
  press('F4');choose(act)
  if name=='horse-late':
   commands=['c %04x '%(0xda00+j)+checkpoint[j:j+16].hex(' ') for j in range(0,256,16)]
   commands+=['c 0600 01','c 0603 03','c 063a 01','c 0639 01']
   x.monitor(commands)
  start=time.monotonic();previous=None;states=set();start_sample=len(samples)
  while time.monotonic()-start<90:
   time.sleep(.25);r=sample();states.add(r['mode'])
   assert not r['fault']
   if r['mode']==2 and r['clock']>0:assert not r['missed'] and r['interval']<=2,r
   key=(r['mode'],r['lives'])
   if key!=previous:
    print(name,r,flush=True);x.shot(name+'-%d-%d.png'%(r['mode'],r['lives']));previous=key
   if r['mode']==3 and r['drop']==(30 if act==3 else 14):x.shot(name+'-floor.png')
   if r['mode']==6:
    assert r['feet']==166 and r['lives']==0
    x.shot(name+'-continue.png')
   if r['mode']==0 and not r['loading'] and not r['need_stage']:
    assert r['lives']==0
    x.shot(name+'-title.png');break
  else:raise AssertionError((name,'No game over'))
  assert {1,2,3,6,0}<=states and 5 not in states,states
  press('Control_R');until(lambda r:r['mode']==7 and not r['loading'])
  x.shot(name+'-restart-chooser.png')
  choose(act);r=until(lambda r:r['mode']==2)
  assert r['lives']==3 and r['act']==act and not r['fault']
  x.shot(name+'-new-game.png')
  results.append(dict(scenario=name,timeout_to_title=True,gameover_restart=True,samples=samples[start_sample:]))
finally:x.close()
report=dict(standard=a.standard,car_sha256=hashlib.sha256((R/'build/Circus-Charlie-SIC512.car').read_bytes()).hexdigest(),
            late_checkpoint_fixture=True,scenarios=results)
(x.out/'result.json').write_text(json.dumps(report,indent=2));print('PASS',a.standard)
