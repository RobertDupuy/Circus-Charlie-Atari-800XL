"""Reproduce ball contact using actual title/chooser/joystick controls.

The monitor stops at hurt to inspect the two centres before the death state
changes. No position, collision, grace or cartridge instructions are patched.
"""
from emulator import Atari,R
from cpu import Machine
import argparse,time,re,json,hashlib

p=argparse.ArgumentParser();p.add_argument('standard',choices=['ntsc','pal'])
p.add_argument('--before',action='store_true');args=p.parse_args()
cart=R/'build/ball-bars/before.car' if args.before else R/'build/Circus-Charlie-SIC512.car'
lbl=R/'build/ball-bars/before.lbl' if args.before else R/'build/main.lbl'
labels=Machine(cart,lbl).labels
tag=('before' if args.before else 'fixed')+'-'+args.standard
x=Atari(args.standard,'ball-contact-'+tag,sound=True,cart=cart);log=x.out/(args.standard+'.log')

def tap(k):
    x.key(k,True);time.sleep(.15);x.key(k,False);time.sleep(.15)

def send(commands):
    off=log.stat().st_size
    x.p.stdin.write(('\n'.join(commands)+'\n').encode());x.p.stdin.flush()
    until=time.monotonic()+15
    while True:
        text=log.read_bytes()[off:].decode(errors='replace')
        if ' PC=' in text:return text
        assert time.monotonic()<until,('monitor timeout',commands,text[-500:])
        time.sleep(.01)

try:
    tap('F4');tap('Down');tap('Control_R')
    x.monitor(['bpc %04x'%labels['hurt']],False)
    x.key('Right',True)
    text=send(['cont'])
    x.key('Right',False)
    assert ('PC=%04X'%labels['hurt']) in text,text[-500:]
    rows={}
    for line in send(['m 0600','m 0900','show']).splitlines():
        hit=re.match(r'^([0-9A-F]{4}): ((?:[0-9A-F]{2} ){15}[0-9A-F]{2})',line)
        if hit:
            for i,b in enumerate(bytes.fromhex(hit[2])):rows[int(hit[1],16)+i]=b
    v=lambda n:rows[labels[n]]
    w=lambda n:v(n)+256*rows[labels[n]+1]
    assert v('act')==3 and v('mode')==2 and v('lives')==3
    centres=[rows[labels['ball_lo']+i]+256*rows[labels['ball_hi']+i] for i in range(5)]
    support=v('current_ball')
    distance=min(abs(c-centres[support]) for i,c in enumerate(centres) if i!=support and c<32767)
    assert distance==(20 if args.before else 14),(distance,centres)
    assert not v('fault') and not w('missed') and v('max_interval')<=2
    result=dict(standard=args.standard,car_sha256=hashlib.sha256(cart.read_bytes()).hexdigest(),
                physical_joystick_controls=True,old_failure_expected=args.before,
                centre_distance=distance,visible_diameter=14,visible_gap=max(0,distance-14),
                world=w('world'),renderer_faults=v('fault'),missed_deadlines=w('missed'))
    # Execute the loss, then freeze only for a post-assertion screenshot.
    send(['bpc %04x'%labels['game_tick'],'cont'])
    x.p.stdin.write(('c %04x 01\nbpc 0\ncont\n'%labels['paused']).encode());x.p.stdin.flush()
    time.sleep(.3);x.shot('contact.png')
finally:
    x.close()
(x.out/'result.json').write_text(json.dumps(result,indent=2)+'\n');print(result)
