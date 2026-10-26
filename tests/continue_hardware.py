"""Natural final-life misses and five-second timeout in all seven scenes.

Ordinary controls enter each main act. A one-life fixture shortens the run;
the water variation has an explicit stage-entry fixture. Collisions, the
death animation, countdown and return to title run without cartridge patches.
"""
from emulator import Atari,R
from cpu import Machine
import argparse,hashlib,json,re,time

p=argparse.ArgumentParser();p.add_argument('standard',choices=['ntsc','pal'])
p.add_argument('--scenes',default='0,1,2,3,4,5,6');args=p.parse_args()
scenes=[int(s) for s in args.scenes.split(',')]
labels=Machine().labels
arcade=json.loads((R/'build/build-profile.json').read_text())['selection']=='arcade'
assert arcade,'Use the arcade build to exercise ordinary chooser entry'
x=Atari(args.standard,'continue-'+args.standard,sound=True)
log=x.out/(args.standard+'.log');reports=[]

def tap(key):
 x.key(key,True);time.sleep(.15);x.key(key,False);time.sleep(.12)

def monitor(commands):
 offset=log.stat().st_size;tap('F8');deadline=time.monotonic()+3
 while b' PC=' not in log.read_bytes()[offset:]:
  assert time.monotonic()<deadline,'Monitor did not open'
  time.sleep(.02)
 for command in commands:
  x.p.stdin.write((command+'\n').encode());x.p.stdin.flush();time.sleep(.05)
 x.p.stdin.write(b'cont\n');x.p.stdin.flush();deadline=time.monotonic()+3
 while b'Video Mode:' not in log.read_bytes()[offset:]:
  assert time.monotonic()<deadline,'Monitor did not resume'
  time.sleep(.02)
 time.sleep(.15)
 return log.read_bytes()[offset:].decode(errors='replace')

def sample():
 rows={}
 for line in monitor(['m 0600']).splitlines():
  hit=re.match(r'^([0-9A-F]{4}): ((?:[0-9A-F]{2} ){15}[0-9A-F]{2})',line)
  if hit:
   for j,b in enumerate(bytes.fromhex(hit[2])):rows[int(hit[1],16)+j]=b
 assert all(a in rows for a in range(0x600,0x700)),'Incomplete fresh monitor dump'
 value=lambda n:rows[labels[n]]
 word=lambda n:value(n)+256*rows[labels[n]+1]
 return dict(mode=value('mode'),act=value('act'),water=value('water'),lives=value('lives'),
             host=word('host_frames'),deadline=word('continue_deadline'),remaining=word('continue_ticks'),
             seconds=value('continue_secs'),loading=value('loading'),need_stage=value('need_stage'),
             selected=value('selected'),fault=value('fault'),missed=word('missed'),interval=value('max_interval'),
             scene_clock=word('scene_clock'))

def until(predicate,seconds=30):
 end=time.monotonic()+seconds
 while time.monotonic()<end:
  r=sample()
  if predicate(r):return r
  time.sleep(.12)
 raise AssertionError(('Transition did not arrive',r))

def choose(scene):
 until(lambda r:r['mode']==7 and not r['loading'] and not r['need_stage'])
 act=2 if scene==6 else scene
 if act>=3:tap('Down')
 for _ in range(act%3):tap('Right')
 until(lambda r:r['selected']==act)
 tap('Control_R')
 until(lambda r:r['mode'] in (1,2) and r['act']==act and not r['loading'] and not r['need_stage'])
 if scene==6:
  monitor(['c %04x 01'%labels['water'],'c 0600 01','c 0639 01'])
  until(lambda r:r['water']==1 and r['mode'] in (1,2) and not r['loading'] and not r['need_stage'])

def start(scene):
 tap('F5');until(lambda r:r['mode']==0 and not r['loading'] and not r['need_stage'])
 tap('F4');choose(scene)

def final_life(scene):
 monitor(['c 0603 01'])
 until(lambda r:r['mode']==2)
 if scene==5:
  time.sleep(.25);tap('Control_R') # Release the first trapeze too early.

def shot(name):time.sleep(.2);x.shot(name)

try:
 for scene in scenes:
  start(scene);final_life(scene)
  samples=[];digits=[];deadline=None;last_mode=None;end=time.monotonic()+40
  while time.monotonic()<end:
   r=sample();samples.append(r)
   assert not r['fault'],r
   assert r['mode']!=5,'Old permanent game-over screen reappeared'
   if r['mode']==2 and r['scene_clock']:
    assert not r['missed'] and r['interval']<=2,r
   if r['mode']!=last_mode:print(scene,r,flush=True);last_mode=r['mode']
   if r['mode']==6:
    assert r['lives']==0 and 1<=r['seconds']<=5
    deadline=r['deadline'];remaining=(deadline-r['host'])&65535
    assert abs(remaining-r['remaining'])<=3,(scene,r)
    if r['seconds'] not in digits:
     digits.append(r['seconds']);shot(f'act-{scene}-continue-{r["seconds"]}.png')
   if r['mode']==0 and not r['loading'] and not r['need_stage']:
    assert deadline is not None and ((r['host']-deadline)&65535)<=60,r
    shot(f'act-{scene}-title.png');break
   time.sleep(.1)
  else:raise AssertionError(('Timeout did not return to title',scene))
  assert digits==[5,4,3,2,1],(scene,digits)
  # Return without any input, remain on title, then deliberately start again.
  time.sleep(.4);assert sample()['mode']==0
  tap('Control_R');choose(2 if scene==6 else scene)
  r=until(lambda r:r['mode']==2)
  assert r['lives']==3 and not r['fault'],r
  shot(f'act-{scene}-new-game.png')
  accepted=False
  if scene in (2,4):
   start(scene);final_life(scene);until(lambda r:r['mode']==6 and r['seconds']<=3)
   tap('Control_R');r=until(lambda r:r['mode']==2 and r['lives']==3 and r['scene_clock']>0)
   assert not r['fault'] and not r['missed'] and r['interval']<=2,r
   shot(f'act-{scene}-accepted-continue.png');accepted=True
  reports.append(dict(scene=scene,life_count_fixture=1,water_entry_fixture=scene==6,natural_final_miss=True,
                      expected_tv_frames=250 if args.standard=='pal' else 300,seconds_shown=digits,
                      timeout_to_title=True,fresh_game=True,accepted_continue_checked=accepted,samples=samples))
  (x.out/'progress.json').write_text(json.dumps(reports,indent=2)+'\n')

 # A static artwork fixture displays the money hoop where its blue sign is
 # unobscured. Pixel identity/colour at every X alignment is checked separately.
 start(0);until(lambda r:r['mode']==2)
 m=Machine();m.stage(0);m.wordset('world',500);m.call('update_camera')
 commands=['c %04x 01'%labels['paused'],'c 0620 f4 01',
           'c %04x %02x %02x'%(labels['camera'],m.word('camera')&255,m.word('camera')>>8),
           'c d90c 01 00 00 00','c d910 01','c 0940 30','c 0950 02',
           'c %04x 00'%labels['passed']]
 monitor(commands);shot('money-bag.png')
finally:x.close()
report=dict(standard=args.standard,car_sha256=hashlib.sha256((R/'build/Circus-Charlie-SIC512.car').read_bytes()).hexdigest(),
            clock_source='unmodified Atari800 TV frame counter',scenarios=reports,money_bag_artwork_fixture=True)
(x.out/'result.json').write_text(json.dumps(report,indent=2)+'\n');print('PASS',args.standard,len(reports),'scenes')
