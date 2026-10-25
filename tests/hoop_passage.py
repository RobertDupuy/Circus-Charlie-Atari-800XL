"""Check the actual cartridge's opening against its complete jumping actor.

This is a geometry check, independent of the compositor's reference masks.
Read both ANTIC glyph pixels and the double-width PM flame bytes from native
RAM. Remove the actor only while measuring the opening, then render the actor
alone at every legal central crossing height. Its full silhouette must fit
with two clear scanlines at both ends. --car can demonstrate an older failure.
"""
import argparse,hashlib,json
from cpu import Machine,ROOT

parser=argparse.ArgumentParser()
parser.add_argument('--car')
parser.add_argument('--labels',help='Symbol file built with --car; required for an older cartridge')
args=parser.parse_args()
if args.car and not args.labels:parser.error('--car requires its matching --labels file')
cart=args.car or ROOT/'build/Circus-Charlie-SIC512.car'

def occupied(m,back,x,y):
    row=y//8;band=0 if row<8 else 1 if row<17 else 2
    code=m.m[0x3800+back*1024+row*40+x//4]&127
    bits=m.m[0x4000+back*3072+band*1024+code*8+y%8]
    return bool((bits>>(6-2*(x%4)))&3)

def setup(back):
    m=Machine(cart,labels=args.labels);m.stage(0);m.wordset('world',500);m.call('update_camera')
    m.set('back',back);m.set('lion_potcount',0)
    for slot in range(4):m.m[m.labels['lion_active']+slot]=0
    return m

openings={}
for back in (0,1):
    for small in (False,True):
        for phase in range(4):
            for shift in range(4):
                m=setup(back);m.wordset('anim_clock',phase*4)
                m.m[m.labels['lion_active']]=1
                m.m[m.labels['hoop_type']]=2 if small else 0
                m.m[m.labels['passed']]=1  # Bag collected: inspect the empty aperture.
                center=500+shift;m.m[0x940]=center&255;m.m[0x950]=center>>8
                m.m[m.labels['gfx_draw_hero']]=0x60
                m.call('render_frame')
                left=m.m[m.labels['pm_x']];dma=0x5800+back*0x800+0x400
                clear=[]
                for y in range(72,128 if small else 144):
                    flame=m.m[dma+40+y]
                    solid=any(occupied(m,back,left+col,y) or flame&(1<<(7-col//2)) for col in (7,8))
                    clear.append(not solid)
                runs=[];start=None
                for y,empty in enumerate(clear+[False],72):
                    if empty and start is None:start=y
                    elif not empty and start is not None:runs.append((start,y-1));start=None
                openings[back,small,phase,shift]=max(runs,key=lambda a:a[1]-a[0])

bounds={}
for back in (0,1):
    for height in range(27,56):
        for animation in (0,8,16):
            m=setup(back);m.set('jumping',1);m.set('jump_pixels',height)
            m.wordset('anim_clock',animation);m.call('render_frame')
            x=m.get('gfx_hero_x');y=m.get('gfx_hero_y');rows=[]
            for row in range(y,y+32):
                if any(occupied(m,back,col,row) for col in range(x,x+24)):rows.append(row)
            assert rows,('empty actor',height,animation)
            bounds[back,height,animation]=(min(rows),max(rows))

checks=0;failures=[];headroom=999;footroom=999
for (back,small,phase,shift),(top,bottom) in openings.items():
    for height in range(43 if small else 27,56):
        for animation in (0,8,16):
            head,feet=bounds[back,height,animation]
            headroom=min(headroom,head-top);footroom=min(footroom,bottom-feet);checks+=1
            if head<top+2 or feet>bottom-2:
                failures.append((small,phase,shift,back,height,animation,head,feet,top,bottom))

report={'native_opening_variants':len(openings),'native_actor_frames':len(bounds),
        'silhouette_fit_cases':checks,'minimum_headroom_scanlines':headroom,
        'minimum_footroom_scanlines':footroom,'geometry_failures':len(failures),
        'includes_double_width_pm_flames':True,'required_clearance_scanlines':2,
        'car_sha256':hashlib.sha256(__import__('pathlib').Path(cart).read_bytes()).hexdigest()}
print(json.dumps(report,indent=2))
assert not failures,('Actor crosses the visible rim',failures[:6])
if not args.car:(ROOT/'build/hoop-passage.json').write_text(json.dumps(report,indent=2))
