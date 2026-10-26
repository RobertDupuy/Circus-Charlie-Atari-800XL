"""Native Atari800 replay of a natural loss, retry and exact-top edge landing.

Only joystick/fire samples are supplied at the normal game_tick boundary.
No cartridge instructions, checkpoints, collision or actor state are patched.
The rank-zero case enters Horse through actual title/chooser controls.
"""
from emulator import Atari,R
from cpu import Machine
import argparse,time,re,json,hashlib
p=argparse.ArgumentParser();p.add_argument('standard',choices=['ntsc','pal'])
p.add_argument('--before',action='store_true');args=p.parse_args()
cart=R/'build/horse-investigation/before-Circus-Charlie-SIC512.car' if args.before else R/'build/Circus-Charlie-SIC512.car'
labels_path=R/'build/horse-investigation/before-main.lbl' if args.before else R/'build/main.lbl'
labels=Machine(cart,labels_path).labels
case=json.loads((R/'tests/fixtures/horse-edge-losses.json').read_text())['cases'][0]
tag=('before' if args.before else 'fixed')+'-'+args.standard
x=Atari(args.standard,'horse-contact-'+tag,sound=True,cart=cart);log=x.out/(args.standard+'.log')
def tap(k):x.key(k,True);time.sleep(.15);x.key(k,False);time.sleep(.15)
def send(commands):
 off=log.stat().st_size
 x.p.stdin.write(('\n'.join(commands)+'\n').encode());x.p.stdin.flush()
 until=time.monotonic()+5
 while True:
  s=log.read_bytes()[off:].decode(errors='replace')
  if ' PC=' in s:return s
  assert time.monotonic()<until,('Monitor response',commands,s)
  time.sleep(.002)
def sample():
 rows={}
 for line in send(['m 0600','m 0900','show']).splitlines():
  hit=re.match(r'^([0-9A-F]{4}): ((?:[0-9A-F]{2} ){15}[0-9A-F]{2})',line)
  if hit:
   for j,b in enumerate(bytes.fromhex(hit[2])):rows[int(hit[1],16)+j]=b
 v=lambda n:rows[labels[n]]
 w=lambda n:v(n)+256*rows[labels[n]+1]
 return dict(mode=v('mode'),lives=v('lives'),world=w('world'),height=v('jump_pixels'),velocity=v('velocity'),
             clock=w('scene_clock'),fault=v('fault'),missed=w('missed'),interval=v('max_interval'),
             stage_hurt=v('stage_hurt'),jumping=v('jumping'),loading=v('loading'))
samples=[]
try:
 tap('F4');tap('Down');tap('Right');tap('Control_R')
 x.monitor(['bpc %04x'%labels['game_tick']]);time.sleep(.1)
 r=sample()
 while r['mode']==1:
  send(['cont']);r=sample()
 assert r['mode']==2 and r['world']==47 and r['clock']==0,r
 for i,(joy,fire)in enumerate(case['inputs']):
  if i==len(case['inputs'])-1:
   r=sample();samples.append(dict(tick=i,**r));assert r['world']==1145 and r['height']==8 and r['lives']==2,r
  send(['c %04x %02x'%(labels['input'],joy),'c %04x %02x'%(labels['fire_latch'],fire),'cont'])
  if i%100==0:
   r=sample();samples.append(dict(tick=i+1,**r));print(tag,i+1,r,flush=True)
 r=sample();samples.append(dict(tick=len(case['inputs']),**r))
 assert r['world']==1147 and r['stage_hurt'],r
 assert r['mode']==(3 if args.before else 2)and r['lives']==(1 if args.before else 2),r
 if not args.before:
  assert r['height']==8 and r['velocity']<128 and r['jumping'],r
  for _ in range(8):send(['c %04x 08'%labels['input'],'cont'])
  assert sample()['mode']==2
 assert not r['missed']and not r['fault']and r['interval']<=2,r
 # Pause only after replay, to capture the resulting scene without advancing it.
 x.p.stdin.write(('c %04x 01\nbpc 0\ncont\n'%labels['paused']).encode());x.p.stdin.flush();time.sleep(.3)
 x.shot('contact.png')
finally:x.close()
report=dict(standard=args.standard,car_sha256=hashlib.sha256(cart.read_bytes()).hexdigest(),input_replay=True,
            title_and_chooser_controls=True,prior_natural_losses=1,old_failure_expected=args.before,result=r,samples=samples)
(x.out/'result.json').write_text(json.dumps(report,indent=2)+'\n');print('PASS',tag,flush=True)
