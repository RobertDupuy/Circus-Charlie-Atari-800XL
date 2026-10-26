"""Native Atari800 visual checks and neutral-input trampoline losses/retries."""
from emulator import Atari,R
from pathlib import Path
import hashlib,json,re,sys,time
import numpy as np
standard=sys.argv[1] if len(sys.argv)>1 else 'ntsc'
name='presentation-'+standard

def read_memory(a):
    result={}
    for l in (a.out/f'{standard}.log').read_text().splitlines():
        m=re.match(r'^([0-9A-F]{4}): ((?:[0-9A-F]{2} ){15}[0-9A-F]{2})',l)
        if m:
            for i,v in enumerate(bytes.fromhex(m[2])):result[int(m[1],16)+i]=v
    return result

def press(a,key):
    a.key(key,True);time.sleep(.13);a.key(key,False);time.sleep(.14)

def trampoline_check():
 a=Atari(standard,name+'-trampoline',sound=True);samples=[];shots=[];intro_start={}
 try:
    press(a,'F4');time.sleep(.2)
    for _ in range(2):press(a,'Right')
    press(a,'Control_R')
    until=time.monotonic()+100;seen_play=False;deaths=set();countdown=set()
    for i in range(500):
        assert time.monotonic()<until,'Natural trampoline attempt timed out'
        a.monitor(['m 0600 06ff'])
        d=read_memory(a)
        row=dict(mode=d.get(0x600),lives=d.get(0x603),height=d.get(0x628),bounces=d.get(0x63d),
                 feet=d.get(0x629),death_drop=d.get(0x6f2),
                 presented=d.get(0x606,0)+256*d.get(0x607,0),loading=d.get(0x61a),
                 render_busy=d.get(0x60a),
                 reason=d.get(0x6f7),age=d.get(0x6f8),seconds=d.get(0x6bb),
                 missed=d.get(0x608,0)+256*d.get(0x609,0),fault=d.get(0x61d),interval=d.get(0x68c))
        samples.append(row)
        mode=row['mode'];seen_play|=mode==2
        label=None
        if mode==2:
            assert row['death_drop']==0,('retry below trampoline',row)
        if mode in (1,2):
            intro_start.setdefault(row['lives'],row['presented'])
        # Do not interpret a foreground scratch coordinate partway through
        # stage loading as an already published picture. Check after two flips.
        if mode in (1,2) and row['lives']<3 and not row['loading'] and ((row['presented']-intro_start[row['lives']])&65535)>=2:
            assert row['death_drop']==0,('retry below trampoline',row)
            if mode==1:assert row['height']==0,('wrong retry height',row)
            # Feet is scratch while draw_scene is in progress. Its stable
            # value and the displayed head position both need to be correct.
            if mode==1 and not row['render_busy']:assert row['feet']==130,('wrong retry feet',row)
            retry='retry-'+str(row['lives'])+'.png'
            if retry not in shots:label=retry
        if mode==2 and row['bounces']==0 and 'bag.png' not in shots:label='bag.png'
        if mode==2 and row['bounces']==3 and 60<=row['height']<76 and 'high-jump.png' not in shots:label='high-jump.png'
        if mode==3:
            assert row['reason']==4
            deaths.add(row['lives'])
            if row['height']>=89 and 'roof-hit.png' not in shots:label='roof-hit.png'
            if 0<row['height']<60 and 'fall-from-roof.png' not in shots:label='fall-from-roof.png'
        if mode==6:
            countdown.add(row['seconds'])
            if 'continue.png' not in shots:label='continue.png'
        if mode==0 and seen_play:
            a.shot('title-after-timeout.png');shots.append('title-after-timeout.png');break
        if label:
            im=a.shot(label);shots.append(label)
            if label.startswith('retry-'):
                top=(im.height-448)//2+48
                head=np.asarray(im)[top+70*2:top+118*2,16+50*4:16+70*4].astype(int)
                green=(head[:,:,1]>head[:,:,0]+25)&(head[:,:,1]>head[:,:,2]+25)
                assert np.count_nonzero(~green)>40,('Charlie is below the pedestal',row)
    else:raise AssertionError('No title return')
    assert deaths=={0,1,2},deaths
    assert countdown=={1,2,3,4,5},countdown
    assert {'bag.png','roof-hit.png','fall-from-roof.png','retry-2.png','retry-1.png','continue.png','title-after-timeout.png'}<=set(shots),shots
    bad=[s for s in samples if s['fault'] or s['missed'] or (s['mode'] in (2,3,6) and s['interval']>2)]
    assert not bad,bad[:5]
 finally:a.close()
 report=dict(standard=standard,car_sha256=hashlib.sha256((R/'build/Circus-Charlie-SIC512.car').read_bytes()).hexdigest(),natural_roof_losses=3,continue_countdown=sorted(countdown,reverse=True),
            returned_to_title=True,missed_deadlines=max(s['missed'] for s in samples),screenshots=shots,samples=samples)
 (a.out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
 print({k:v for k,v in report.items() if k!='samples'},flush=True)

if '--lion-only' not in sys.argv:trampoline_check()

# Native pictures of the actual finish state. Only game state is installed;
# the cartridge renderer, IRQs, palette and frame buffers are unmodified.
a=Atari(standard,name+'-lion',sound=True)
try:
    press(a,'F4');time.sleep(.2);press(a,'Control_R');time.sleep(.3)
    digests={}
    for elapsed,label in [(0,'dance-arms'),(8,'dance-step'),(54,'bird-and-bag'),(64,'money-drop')]:
        a.monitor(['c 0600 04','c 0620 52 05 da 04','c 0627 00 0b','c 062e e0',
                   'c 0648 52 05',f'c 06e4 {elapsed:02x} 01 01 00 00','c d93d 01'])
        a.shot(label+'.png')
        digests[label]=hashlib.sha256((a.out/(label+'.png')).read_bytes()).hexdigest()
    assert len(set(digests.values()))==4,digests
    a.monitor(['m 0600 06ff'])
    d=read_memory(a);assert not d[0x61d]
finally:a.close()
(a.out/'result.json').write_text(json.dumps(dict(standard=standard,
    car_sha256=hashlib.sha256((R/'build/Circus-Charlie-SIC512.car').read_bytes()).hexdigest(),
    finish_state_fixture=True,distinct_animation_frames=digests,renderer_faults=d[0x61d]),indent=2)+'\n')
