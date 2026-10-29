"""Prepare ANTIC-4 cell stamps and PM shapes for a 512K SIC cartridge.
All shifting and mask construction is performed here, never on the Atari.
"""
from pathlib import Path
import math,json,struct,re
from collections import Counter
import numpy as np
import bold_art as bold
import act3_assets as act3
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[1]
STUDY=ROOT.parent/'circus-study'
BUILD=ROOT/'build'
BUILD.mkdir(exist_ok=True)
REF=np.load(ROOT/'assets/reference.npz')
PAL=np.array([[0,0,0],[230,60,75],[255,255,255],[245,195,58],[75,160,220]],np.uint8)
def sprite(n,local=2):
    return np.array([0,3,local,1],np.uint8)[REF['sprites'][n-128]]
def combine(parts,w,h):
    a=np.zeros((h,w),np.uint8)
    for im,x,y in parts:
        view=a[y:y+im.shape[0],x:x+im.shape[1]]
        view[im!=0]=im[im!=0]
    return a
def char(a,b):return combine([(sprite(a),0,0),(sprite(b,2),0,16)],12,37)

FONT={
'A':['01110','10001','10001','11111','10001','10001','10001'],
'B':['11110','10001','10001','11110','10001','10001','11110'],
'C':['01111','10000','10000','10000','10000','10000','01111'],
'D':['11110','10001','10001','10001','10001','10001','11110'],
'E':['11111','10000','10000','11110','10000','10000','11111'],
'F':['11111','10000','10000','11110','10000','10000','10000'],
'G':['01111','10000','10000','10111','10001','10001','01111'],
'H':['10001','10001','10001','11111','10001','10001','10001'],
'I':['11111','00100','00100','00100','00100','00100','11111'],
'J':['00111','00010','00010','00010','10010','10010','01100'],
'K':['10001','10010','10100','11000','10100','10010','10001'],
'L':['10000','10000','10000','10000','10000','10000','11111'],
'M':['10001','11011','10101','10101','10001','10001','10001'],
'N':['10001','11001','10101','10011','10001','10001','10001'],
'O':['01110','10001','10001','10001','10001','10001','01110'],
'P':['11110','10001','10001','11110','10000','10000','10000'],
'Q':['01110','10001','10001','10001','10101','10010','01101'],
'R':['11110','10001','10001','11110','10100','10010','10001'],
'S':['01111','10000','10000','01110','00001','00001','11110'],
'T':['11111','00100','00100','00100','00100','00100','00100'],
'U':['10001','10001','10001','10001','10001','10001','01110'],
'V':['10001','10001','10001','10001','10001','01010','00100'],
'W':['10001','10001','10001','10101','10101','11011','10001'],
'X':['10001','10001','01010','00100','01010','10001','10001'],
'Y':['10001','10001','01010','00100','00100','00100','00100'],
'Z':['11111','00001','00010','00100','01000','10000','11111'],
'0':['01110','10001','10011','10101','11001','10001','01110'],
'1':['00100','01100','00100','00100','00100','00100','01110'],
'2':['01110','10001','00001','00010','00100','01000','11111'],
'3':['11110','00001','00001','01110','00001','00001','11110'],
'4':['00010','00110','01010','10010','11111','00010','00010'],
'5':['11111','10000','10000','11110','00001','00001','11110'],
'6':['01110','10000','10000','11110','10001','10001','01110'],
'7':['11111','00001','00010','00100','01000','01000','01000'],
'8':['01110','10001','10001','01110','10001','10001','01110'],
'9':['01110','10001','10001','01111','00001','00001','01110'],
'!':['00100','00100','00100','00100','00100','00000','00100'],
'-':['00000','00000','00000','11111','00000','00000','00000'],
'/':['00001','00001','00010','00100','01000','10000','10000'],
':':['00000','00100','00100','00000','00100','00100','00000'],
'.':['00000','00000','00000','00000','00000','00110','00110']}
def font():
    b=bytearray(1024)
    for c,rows in FONT.items():b[ord(c)*8:ord(c)*8+8]=bytes([int(row,2)<<2 for row in rows]+[0])
    return b

def backgrounds():
    crowd=REF['crowd'].copy()
    result=[]
    for act in range(7):
        a=np.zeros((176,160),np.uint8)
        cy=104 if act==1 else 120 if act==5 else 16
        a[cy:cy+48]=crowd
        for y in ([158,174] if act==1 else [72,94,118,142,166]):a[y,:]=1
        if act==1:a[96,:]=2
        if act==5:
            a[:4,:]=4;a[166,:]=2
        if act==2:a[166,:]=0
        if act==6:
            a[166:,:]=0
            a[170:,:]=4
            for x in range(160):
                a[168+(x%4)//2,x]=2
                if x%4<2:a[173,x]=2
        maps=[];fonts=[];counts=[]
        for band in range(3):
            unique={b'\0'*8:0};screen=[]
            for row in range([0,8,17][band],[8,17,22][band]):
                for col in range(40):
                    block=a[row*8:row*8+8,col*4:col*4+4].copy()
                    alt=128 if np.count_nonzero(block==4)>np.count_nonzero(block==3) else 0
                    block[block==(3 if alt else 4)]=2;block[block==4]=3
                    pattern=bytes(sum(int(v)<<(6-2*j) for j,v in enumerate(line)) for line in block)
                    if pattern not in unique:unique[pattern]=len(unique)
                    screen.append(unique[pattern]|alt)
            assert len(unique)<90
            counts.append(len(unique));maps.extend(screen);fonts.extend(b''.join(unique).ljust(1024,b'\0'))
        data=bytearray([255])*16384
        data[:3072]=bytes(fonts);data[3072:3072+880]=bytes(maps)
        # Forty rotations of the crowd's six rows; all generated offline.
        crowdrow=cy//8
        for shift in range(40):
            part=bytearray()
            for y in range(crowdrow,crowdrow+6):
                row=maps[y*40:y*40+40];part.extend(row[shift:]+row[:shift])
            data[4096+shift*240:4096+(shift+1)*240]=part
        result.append((data,counts,crowdrow))
    return result

def sg_horse():
    return REF['horse'].copy()

def poses():
    ims=[];names=[]
    def add(name,a):names.append(name);ims.append(a)
    for n,a,b in [('stand',135,136),('walk1',135,144),('walk2',135,145),('jump',137,138),('swing1',149,150),('swing2',151,152),('fall',153,154),('arms',147,148)]:add(n,char(a,b))
    for n in range(3):add('lion'+str(n),combine([(sprite(129+n*2,3),0,2),(sprite(130+n*2,3),12,0)],24,23))
    horse=sg_horse()
    for n in range(3):
        a=horse.copy()
        if n==1:a[24:]=np.roll(a[24:],1,axis=1)
        if n==2:a[24:]=np.roll(a[24:],-1,axis=1)
        add('horse'+str(n),a)
    for phase in range(4):
        a=np.zeros((24,20),np.uint8)
        for y in range(24):
            for x in range(20):
                dx=(x-9.5)/9.5;dy=(y-11.5)/11.5
                if dx*dx+dy*dy<=1:
                    sector=int(((math.atan2(dy,dx)+phase*math.pi/8)%(2*math.pi))/(math.pi/3))
                    a[y,x]=[2,1,2,3,2,1][sector]
        add('ball'+str(phase),a)
    tipx=[];tipy=[]
    # Four real rope geometries, sixteen unique angles each. Timing sequences
    # traverse these in both directions (42/24 steps), without live drawing.
    for kind,(length,extent) in enumerate([(84,38),(72,30),(62,24),(94,36)]):
        maxangle=math.asin(2*extent/length)
        for pose in range(16):
            angle=-maxangle+2*maxangle*pose/15
            x=round(length*math.sin(angle)/2);y=round(8+length*math.cos(angle))
            a=Image.new('L',(81,104));d=ImageDraw.Draw(a)
            d.line([(40,0),(40+x,y)],fill=2,width=1)
            d.line([(37+x,y),(43+x,y)],fill=3,width=1)
            add(f'rope-{kind}-{pose}',np.array(a));tipx.append(x);tipy.append(y)
    for phase in range(2):
        a=np.zeros((28,8),np.uint8)
        for y in range(28):
            w=1+y//6
            for x in range(8):
                if abs(x-3.5+math.sin((y+phase*3)/3))<w/2:a[y,x]=3 if y>14 else 1
        add('flame'+str(phase),a)
    for lion in range(3):
        for rider in [1,2,3]:
            add(f'lion-rider-{lion}-{rider}',combine([(ims[8+lion],0,24),(ims[rider],6,0)],24,47))
    # Screen stamps leave all four hardware players available for dolphins.
    a=np.zeros((9,16),np.uint8);a[1:3,:]=2;a[0,2:14]=3
    a[4:9,2]=2;a[4:9,13]=2
    add('water-trampoline',a)
    a=np.zeros((14,8),np.uint8);a[1:3,2:6]=3;a[4:12,1:7]=3;a[5:10,3:5]=2
    add('water-money-bag',a)
    a=np.zeros((8,32),np.uint8);a[1:3,:]=2;a[3:8,2:4]=1;a[3:8,28:30]=1
    add('water-finish-platform',a)
    return ims,names,tipx,tipy

def pm_shapes():
    shapes=[];heights=[];sizes=[]
    def add(a,size=0):
        assert a.shape[1]==8 and a.shape[0]<=96
        heights.append(a.shape[0]);sizes.append(size)
        shapes.append(bytes(sum((1 if v else 0)<<(7-i) for i,v in enumerate(row)) for row in a).ljust(96,b'\0'))
    for frame in range(4):
        a=np.zeros((84,8),np.uint8)
        for y in range(84):
            t=(y-41.5)/39
            if abs(t)<=1:
                r=max(1,round(3*math.sqrt(1-t*t)))
                a[y,3-r]=1;a[y,4+r if 4+r<8 else 7]=1
                if (y+frame*2)%7<2:a[y,max(0,2-r)]=1;a[y,min(7,5+r)]=1
        add(a,1)
    for n in range(4):
        a=sprite(139+n%4,3);ys,xs=np.where(a!=0);a=a[ys.min():ys.max()+1,xs.min():xs.max()+1]
        a=np.array(Image.fromarray(a).resize((8,14),Image.Resampling.NEAREST))
        add(a)
    for frame in range(2):
        a=np.zeros((18,8),np.uint8);a[10:17,1:7]=1;a[11:15,2:6]=0
        for x in [1,3,5,7]:a[3+((x+frame)%3)*2:11,x]=1
        add(a,1)
    for phase in range(2):
        a=np.zeros((8,8),np.uint8);a[0:2,:]=1;a[4,:]=1;a[6,:]=1
        add(a,1)
    a=np.zeros((9,8),np.uint8);a[1:3,:]=1;a[4:9,1]=1;a[4:9,6]=1;add(a,1)
    a=np.zeros((14,8),np.uint8);a[1:3,2:6]=1;a[4:12,1:7]=1;a[5:10,3:5]=0;add(a)
    a=np.zeros((20,8),np.uint8)
    for y in range(20):a[y,1+(y%3):min(8,4+(y%4))]=1
    add(a,1)
    a=np.zeros((8,8),np.uint8);np.fill_diagonal(a,1);np.fill_diagonal(np.fliplr(a),1);add(a)
    a=np.zeros((8,8),np.uint8);a[1:3,:]=1;add(a,3)
    # Four single-bit, double-width PM poses: rising, crest, diving, splash.
    for phase in range(4):
        pixels=bold.dolphin(phase)==4
        add(pixels.reshape(24,8,2).any(axis=2).astype(np.uint8),1)
    return b''.join(shapes),heights,sizes

class Bank(bytearray):
    def __setitem__(self,key,value):
        super().__setitem__(key,value)
        assert len(self)==16384,(key,len(value),len(self))

def trapeze_budget(ims):
    # Exact top-font occupancy bound for every actual hero pose and X shift.
    # Lower fonts have ample room for the 25-cell whole-silhouette bound.
    counts=[]
    for top in range(64):
        maximum=0
        for pose in (3,4,6):
            for sx in range(4):
                a=np.zeros((104,20),np.uint8)
                a[top:top+38,sx:sx+16]=ims[pose]
                maximum=max(maximum,sum(a[y:y+8,x:x+4].any() for y in range(0,64,8) for x in range(0,20,4)))
        counts.append(maximum)
    assert max(counts)<=25
    (ROOT/'src/trapeze-budget.inc').write_text('; Generated top-font hero occupancy by screen Y.\ntrapeze_top_budget:\n .byte '+','.join(map(str,counts))+'\n')

def build():
    act3.tables();act3.sword_masks()
    bg=bold.backgrounds();ims,names,tx,ty=poses();ims,names=bold.actors(ims,names);rom=[Bank([255]*16384) for _ in range(32)]
    trapeze_budget(ims)
    act3.hero_contacts()
    from completion_assets import poses as completion_poses
    core=bold.hoop(0);core[core==1]=0
    cached=[bold.install_resident(bg,0,core,72),bold.install_resident(bg,2,act3.pedestal(),128),bold.install_resident(bg,5,bold.trampoline(),164)]
    cached += [bold.install_resident(bg,0,bold.pot(p),142,False) for p in range(2)]
    cached += [bold.install_resident(bg,2,np.zeros((1,1),np.uint8),138,False) for p in range(2)]
    cached += [bold.install_resident(bg,4,bold.horse(p),134,False,shifts=(1,)) for p in range(3)]
    from arcade_rope_assets import prepare as prepare_arcade_ropes
    rope_records,rope_atlas,rope_maps=prepare_arcade_ropes(bg)
    rope_cache=[{} for _ in range(3)]
    hero_blend={}
    # Old rope pose IDs remain empty; the apparatus renderer owns its directory.
    for pid in range(18,82):ims[pid]=np.zeros((1,1),np.uint8)
    for width in range(2,8):
        for phase in range(2):
            ims[30+(width-2)*2+phase]=bold.spring(phase,width*6)
    im=Image.new('L',(32,4));draw=ImageDraw.Draw(im)
    draw.rectangle((0,0,31,3),fill=2);draw.line((1,0,30,0),fill=4)
    ims[42]=np.array(im)
    ims[43]=np.array(Image.fromarray(bold.trampoline()).resize((32,10),Image.Resampling.NEAREST))
    water_codes=[0]*40
    cached.append(bold.install_resident(bg,6,act3.pedestal(32),128,False))
    cached += [bold.install_resident(bg,scene,act3.pedestal(32) if scene==2 else ims[95] if scene else np.zeros_like(ims[95]),128 if scene==2 else 164,False) for scene in (2,0,1,4,5)]
    raised=bold.hoop(0,True);raised[raised==1]=0
    cached.append(bold.install_resident(bg,0,raised,72,False))
    cached.append(bold.install_resident(bg,0,bold.goal_platform(),155,False,shifts=(0,)))
    cached += [bold.install_resident(bg,0,bold.distance_sign(label),168,False,shifts=(0,)) for label in ('60M','50M','40M','30M','20M','10M','GOAL')]
    cached.append(bold.install_resident(bg,5,ims[42],64,False))
    cached.append(bold.install_resident(bg,5,ims[43],164,False))
    ims,names=act3.sprites(ims,names)
    for p in range(96,100):
        cached.append(bold.install_resident(bg,2,ims[p],144,False,shifts=(0,2)))
    cached.append(bold.install_resident(bg,6,act3.pedestal(),128,False))
    # Three unused generic directory entries hold individual support legs.
    # Completion poses, the trapeze directory, and its native compositors stay
    # at their original IDs; both legs reuse the same narrow stamp.
    leg_ids=[82,83,95]
    leg_images={pid:bold.spring_leg(top) for pid,top in zip(leg_ids,(112,120,128))}
    (ROOT/'src/horse-legs.inc').write_text('; Generated by tools/assets.py: support heights 112/120/128.\nhorse_leg_pose: .byte '+','.join(map(str,leg_ids))+'\n')
    # Springboards and support legs share immutable patterns in both bands.
    spring_freq=Counter();leg_patterns=[]
    for pid,sprite in list(enumerate(ims[30:42],30))+list(leg_images.items()):
        sy=0
        for sx in (range(4) if pid in leg_images else (0,2)):
            a=np.zeros((((sprite.shape[0]+sy+7)//8)*8,((sprite.shape[1]+sx+3)//4)*4),np.uint8)
            a[sy:sy+sprite.shape[0],sx:sx+sprite.shape[1]]=sprite
            for row in range(a.shape[0]//8):
                for col in range(a.shape[1]//4):
                    tile=a[row*8:row*8+8,col*4:col*4+4]
                    if tile.any():
                        pat=bold.tile_bytes(tile)[0];spring_freq[pat]+=1
                        if pid in leg_images and tile.any(axis=1).all() and pat not in leg_patterns:leg_patterns.append(pat)
    # Include the legs' floor-line combinations in the shared glyph cache.
    ground=bg[4][0][3072+20*40]
    ground_pixels=np.array([[(v>>shift)&3 for shift in (6,4,2,0)] for v in bg[4][0][2048+(ground&127)*8:2048+(ground&127)*8+8]],np.uint8)
    for sx in range(4):
        tile=ground_pixels.copy();tile[:6,sx]=2
        pat=bold.tile_bytes(tile)[0]
        if pat not in leg_patterns:leg_patterns.append(pat)
    assert max(bg[4][1][1:])<=48
    spring_weights=ROOT/'assets/spring-cache-weights.json'
    if spring_weights.exists():
        weights={bytes.fromhex(k):v for k,v in json.loads(spring_weights.read_text()).items()}
        if set(weights)<=set(spring_freq):spring_freq=Counter({pat:weights.get(pat,0)*100000+n for pat,n in spring_freq.items()})
    assert bg[4][1][1]==11
    patterns=leg_patterns+[p for p,_ in spring_freq.most_common() if p not in leg_patterns]
    spring_cached={p:48+i for i,p in enumerate(patterns[:63])}
    for band in (1,2):
        for pattern,code in spring_cached.items():
            if band==2 and code>=87:continue
            if band==1:code-=37
            bg[4][0][band*1024+code*8:band*1024+(code+1)*8]=pattern
        bg[4][1][band]=74 if band==1 else 87
    assert len(cached)==32
    before=bg[4][1].copy()
    for top in (112,120,128):
        cached.append(bold.install_resident(bg,4,bold.spring_leg(top),top+16,False))
        assert all(a<=b for a,b in zip(bg[4][1],before)),('Support leg cache overflow',before,bg[4][1])
        bg[4][1][:]=before # Cache padding/duplicates are reserved IDs too.
    brown_freq=Counter()
    for sprite in ims[102:106]:
        for sx in range(4):
            a=np.zeros((24,16),np.uint8);a[7:24,sx:sx+12]=sprite
            for row in range(3):
                for col in range(4):
                    tile=a[row*8:row*8+8,col*4:col*4+4]
                    if tile.any():brown_freq[bold.tile_bytes(tile)[0]]+=1
    assert bg[1][1][1]==4
    brown_cached={p:4+i for i,(p,_) in enumerate(brown_freq.most_common(52))}
    for pattern,code in brown_cached.items():bg[1][0][1024+code*8:1024+(code+1)*8]=pattern
    bg[1][1][1]=56
    # White dolphin details share immutable tiles; the blue bodies stay in PM.
    water_freq=Counter()
    for sprite in ims[112:116]:
        for sx in range(4):
            for sy in range(8):
                a=np.zeros((32,20),np.uint8);a[sy:sy+24,sx:sx+16]=sprite
                for row in range(4):
                    for col in range(5):
                        tile=a[row*8:row*8+8,col*4:col*4+4]
                        if tile.any():water_freq[bold.tile_bytes(tile)[0]]+=1
    assert bg[6][1][1:]==[18,31],bg[6][1]
    water_cached={p:31+i for i,(p,_) in enumerate(water_freq.most_common(52))}
    for band,adjust in ((1,13),(2,0)):
        for pattern,code in water_cached.items():
            code-=adjust;bg[6][0][band*1024+code*8:band*1024+(code+1)*8]=pattern
        bg[6][1][band]=83-adjust
    print('Resident counts',[(i,b[1]) for i,b in enumerate(bg)])
    assert bg[6][0][:1024]==bg[2][0][:1024], 'Water must retain the trampoline crowd glyphs'
    for i,(data,counts,crowdrow) in enumerate(bg[:6]):rom[i+1]=data
    ims,names=act3.sprites(ims,names)
    ball_art=[p.copy() for p in ims[14:18]]
    projectile_art={p:ims[p].copy() for p in (82,83,110,111)}
    ims,names=completion_poses(ims,names)
    from details_assets import install as install_details
    ims,names=install_details(ims,names)
    # MAME's Tightrope clear alternates sprite quadrants AD-B0 and B1-B4.
    # Slots 100/101 had no emitted payload; Act 3 uses cached poses 96-99.
    for pid,base in ((100,0xad),(101,0xb1)):
        ims[pid]=bold.charlie(base,pid);names[pid]='tightrope-victory-'+str(pid-100)
    ims[99]=bold.tightrope_goal_decks();names[99]='tightrope-raised-decks'
    # The goal has fixed Y and four-pixel scenery alignment. A tiny tile atlas
    # is installed in RAM once per stage; subsequent frames only write codes.
    canvas=np.zeros((32,56),np.uint8);canvas[5:25]=ims[99]
    patterns=[];records=[]
    for row in range(4):
        for col in range(14):
            tile=canvas[row*8:row*8+8,col*4:col*4+4]
            if not tile.any():continue
            pat,alt=bold.tile_bytes(tile)
            if pat not in patterns:patterns.append(pat)
            records.extend((col,9+row,56+patterns.index(pat)|alt))
    data='; Generated raised Tightrope deck tiles and clipped cell records.\n'
    data+='TIGHTROPE_GOAL_COUNT='+str(56+len(patterns))+'\n'
    data+='tightrope_goal_tiles:\n .byte '+','.join(map(str,b''.join(patterns)))+'\n'
    assert len(patterns)*8<128
    data+='TIGHTROPE_GOAL_BYTES='+str(len(patterns)*8)+'\n'
    data+='.proc tightrope_goal_blit\n'
    for row in sorted(set(records[1::3])):
        cells=[(records[i],records[i+2]) for i in range(0,len(records),3) if records[i+1]==row]
        data+=' lda #<'+str(row*40)+'\n sta z_cell\n ldy z_col\n'
        if cells[0][0]:data+=' tya\n clc\n adc #'+str(cells[0][0])+'\n tay\n'
        prior=None
        for col,glyph in cells:
            data+=' cpy #40\n bcs @row'+str(row)+'\n'
            if glyph!=prior:data+=' lda #'+str(glyph)+'\n'
            data+=' sta (z_cell),y\n iny\n';prior=glyph
        data+='@row'+str(row)+':\n'
    data+=' rts\n.endproc\n'
    (ROOT/'src/tightrope-finish-data.inc').write_text(data)
    # A small gold grip at the exact rope endpoint. Reuse an unused pose;
    # new directory entries would overlap the native compositor tail.
    ims[110]=np.full((1,5),3,np.uint8);names[110]='trapeze-handlebar'
    for pid in leg_ids:names[pid]='horse-support-legs'
    # Actors are now immutable shared glyphs, split across the last two fonts.
    ims.append(bold.money_bag());names.append("hoop-bag-precomposed")
    while len(ims)<119:ims.append(np.zeros((1,1),np.uint8));names.append('unused')
    for pid,im in zip(act3.TRAMP_HERO_IDS,act3.hero_poses()):
        ims[pid]=im;names[pid]='trampoline-Charlie-'+str(act3.TRAMP_HERO_IDS.index(pid))
    directory=bytearray(16384);bank=8;used=0;dedup={};records=0;cellsmax=0;bag_records={}
    for pid,original_im in enumerate(ims):
        im=leg_images.get(pid,original_im)
        # The trapeze goal/rescue decks use cached objects 25/26; their duplicate
        # generic poses 42/43 are never dispatched. Keep every ID and cached
        # deck unchanged while reclaiming the duplicate bytes for the finish.
        unused=(pid in (7,42,43,82,83,95) or 96<=pid<100) and pid not in leg_images and pid not in act3.TRAMP_HERO_IDS
        for sx in range(4):
            for sy in range(8):
                # Ropes have a fixed vertical anchor; duplicate directory entries,
                # not payloads, for the seven unused Y variants.
                yy=3 if pid in (0,5) else 5 if pid==99 else (2 if sy==2 else 7) if pid in (100,101) else 0 if pid==111 else 0 if pid in leg_images else 0 if pid in (8,9,10,14,15,16,17,93) or 18<=pid<82 or pid==116 else 7 if 102<=pid<106 else 0 if 96<=pid<99 else sy
                # Spring decks are snapped to even pixels by gfx_springs.
                # Duplicate odd directory slots instead of storing unused art.
                # The victory composite is anchored at X=108 by complete_begin
                # in every rank. Share its unused X shifts as well as Y shifts.
                xx=0 if pid in (0,5,99,100,101) else sx&2 if 30<=pid<=41 else sx
                if pid in act3.TRAMP_HERO_IDS:xx=sx&2;yy=sy&6
                a=np.zeros((((im.shape[0]+yy+7)//8)*8,((im.shape[1]+xx+3)//4)*4),np.uint8)
                a[yy:yy+im.shape[0],xx:xx+im.shape[1]]=im
                data=bytearray();count=0
                for y in range(0 if unused else a.shape[0]//8):
                    for x in range(a.shape[1]//4):
                        tile=a[y*8:y*8+8,x*4:x*4+4]
                        if not np.any(tile):continue
                        pixels=tile.copy()
                        if False:
                            # Fixed Y=0 trapezes never overlap the scrolling crowd.
                            # Bake the same background that runtime masking used:
                            # top cyan becomes white, and two red arena lines.
                            for yy in range(8):
                                row=y*8+yy
                                color=3 if row==0 else 2 if row==2 else 0
                                if color:pixels[yy,pixels[yy]==0]=color
                        d,alt=bold.tile_bytes(pixels)
                        m=bytes(sum((0 if v else 3)<<(6-2*j) for j,v in enumerate(line)) for line in tile)
                        opaque=64 if np.all(tile!=0) else 0
                        if pid==116:
                            # The bag has a fixed offset inside its hoop. Compose
                            # its six cells offline, including any hoop edge
                            # selected by this horizontal alignment. This is the
                            # same colour conversion as the masked runtime path.
                            old=np.zeros((8,4),np.uint8)
                            for py in range(8):
                                for px in range(4):
                                    hx=x*4+px-sx+3;hy=y*8+py+24
                                    if 0<=hx<raised.shape[1] and 0<=hy<raised.shape[0]:old[py,px]=raised[hy,hx]
                            if alt:old[old==3]=2
                            pixels[pixels==(3 if alt else 4)]=2
                            pixels[pixels==4]=3
                            pixels[pixels==0]=old[pixels==0]
                            d=bytes(sum(int(v)<<(6-2*j) for j,v in enumerate(line)) for line in pixels)
                            opaque=64
                        if False:
                            band=0 if y<8 else 1 if y<17 else 2;cached_glyph=rope_cache[band].get(d)
                            data.extend(bytes([x|alt,y,255])+d if cached_glyph is None else bytes([x|alt,y,cached_glyph|alt]))
                        else:
                            if (30<=pid<=41 or pid in leg_images) and d in spring_cached and y<4:
                                data.extend(bytes([x|alt|opaque|32,y|((spring_cached[d]-47)<<2)])+d)
                            elif 112<=pid<116 and d in water_cached:
                                data.extend(bytes([x|alt|opaque|32,y|((water_cached[d]-30)<<2)])+d)
                            elif 102<=pid<106 and d in brown_cached:
                                data.extend(bytes([x|alt|opaque|32,y|((brown_cached[d]-3)<<2)])+d)
                            else:data.extend(bytes([x|alt|opaque,y])+d)
                        count+=1
                if pid<8 or 84<=pid<93:
                    chunks=[data[i:i+10] for i in range(0,len(data),10)]
                    if pid in (3,4) and sx==0:hero_blend[(pid-3)*8+sy]=[bytes(c[2:]) for c in chunks]
                    if pid==2 and sx==0 and sy==2:hero_blend[16]=[bytes(c[2:]) for c in chunks]
                    width=a.shape[1]//4;height=a.shape[0]//8
                    headers=bytearray([3+width*height,width,height])+bytearray(width*height)
                    for index,c in enumerate(chunks):headers[3+c[1]*width+(c[0]&31)]=(index+1)|(c[0]&192)
                    data=headers+bytearray(b''.join(c[2:] for c in chunks))
                key=bytes(data)
                if pid==116 and sy==0:
                    # One bag may be live. Its six glyphs have fixed slots after
                    # the hero reservation; copy prepared bytes with native
                    # stores, including the underlying raised hoop edge.
                    bag_records[sx]=key
                if key in dedup:b,offset=dedup[key]
                else:
                    if used+len(data)>16128:bank+=1;used=0
                    assert bank<30,('ROM overflow',bank,pid)
                    b,offset=bank,used;rom[b][offset:offset+len(data)]=data;used+=len(data);dedup[key]=(b,offset)
                address=0x8000+offset;v=sx*8+sy;off=pid*128+v*4
                directory[off:off+4]=bytes([b,address&255,address>>8,count]);records+=1;cellsmax=max(cellsmax,count)
    assert all(len(v)==16384 for v in rom), [(i,len(v))for i,v in enumerate(rom)if len(v)!=16384]
    # Old rope directory slots hold 91 angles x four pixel alignments.
    for i,(data,n) in enumerate(rope_records):
        if used+len(data)>16128:bank+=1;used=0
        rom[bank][used:used+len(data)]=data;address=0x8000+used
        directory[0x900+i*4:0x904+i*4]=bytes([bank,address&255,address>>8,n])
        used+=len(data)
    if used+len(rope_atlas)>16128:bank+=1;used=0
    rom[bank][used:used+len(rope_atlas)]=rope_atlas;address=0x8000+used
    directory[0xeb0:0xeb3]=bytes([bank,address&255,address>>8]);used+=len(rope_atlas)
    (ROOT/'assets/rope-cache-map.bin').write_bytes(b''.join(m.ljust(512,b'\xff') for m in rope_maps))
    animation_ends={}
    for data,(b,offset) in dedup.items():animation_ends[b]=max(animation_ends.get(b,0),offset+len(data))
    # The rope stream follows the ordinary prepared sprites sequentially.
    for b in range(min(animation_ends),bank):animation_ends[b]=16128
    animation_ends[bank]=used
    assert bank<20, 'Prepared animations overlap native fixed-object blitters'
    assert all(len(v)==16384 for v in rom), ('rope',[(i,len(v))for i,v in enumerate(rom)if len(v)!=16384])
    mem_z_cell=int(re.search(r"^z_cell=\$([0-9A-Fa-f]+)",(ROOT/"src/memory.inc").read_text(),re.M)[1],16)
    mem_z_bg=int(re.search(r"^z_bg=\$([0-9A-Fa-f]+)",(ROOT/"src/memory.inc").read_text(),re.M)[1],16)
    mem_z_tmp2=int(re.search(r"^z_tmp2=\$([0-9A-Fa-f]+)",(ROOT/"src/memory.inc").read_text(),re.M)[1],16)
    mem_z_num=int(re.search(r"^z_num=\$([0-9A-Fa-f]+)",(ROOT/"src/memory.inc").read_text(),re.M)[1],16)
    assert len(cached)*24<=0x380 and 0x380+len(cached)*12<=0x580
    native_bank=20;native_used=1536;native_ends={}
    for kind,variants in enumerate(cached):
        for sx,record in enumerate(variants):
            for back in range(2):
                code=bytearray();by_glyph={}
                for j in range(0,len(record),3):
                    x,row,glyph=record[j:j+3];offset=row*40+x;address=0x3800+back*1024+offset
                    by_glyph.setdefault(glyph,[]).append(address)
                # Repeated rim/hanger cells share their immediate load.
                # X remains the screen column throughout this hidden-buffer pass.
                for glyph,addresses in by_glyph.items():
                    code.extend((0xa9,glyph))
                    for address in addresses:code.extend((0x9d,address&255,address>>8))
                if kind in (1,10,11,27,28,29,30,31,32,33,34):
                    # Clip columns once, then write all their fixed-height rows.
                    # This also handles negative left-edge columns modulo 256.
                    code=bytearray();by_column={}
                    for j in range(0,len(record),3):
                        x,row,glyph=record[j:j+3]
                        by_column.setdefault(x,{}).setdefault(glyph,[]).append(0x3800+back*1024+row*40)
                    for col,groups in by_column.items():
                        body=bytearray((0xa8,))
                        for glyph,addresses in groups.items():
                            body.extend((0xa9,glyph))
                            for address in addresses:body.extend((0x99,address&255,address>>8))
                        assert len(body)<128
                        code.extend((0x8a,0x18,0x69,col,0xc9,40,0xb0,len(body)))
                        code.extend(body)
                    code.extend((0xa4,mem_z_num))
                if 32<=kind<=34:
                    # One program draws both support columns. X is the left
                    # column; z_tmp2 supplies the independently clipped right.
                    # Four variants encode left alignment and width parity.
                    left=(sx&2)|1;right=(left+2*(sx&1)+1)&3
                    code=bytearray()
                    for side,alignment in enumerate((left,right)):
                        body=bytearray();groups={}
                        for j in range(0,len(variants[alignment]),3):
                            _,row,glyph=variants[alignment][j:j+3]
                            groups.setdefault(glyph,[]).append(0x3800+back*1024+row*40)
                        for glyph,addresses in groups.items():
                            body.extend((0xa9,glyph))
                            for address in addresses:body.extend((0x99 if side else 0x9d,address&255,address>>8))
                        if side:code.extend((0xa4,mem_z_tmp2))
                        code.extend((0xc0 if side else 0xe0,40,0xb0,len(body)))
                        code.extend(body)
                    code.extend((0xa4,mem_z_num))
                code.append(0x60)
                if kind>=25 or kind in (1,10,11):
                    if used+len(code)>16128:bank+=1;used=0
                    address=0x8000+used;entry=(kind*8+sx*2+back)*3
                    rom[20][entry:entry+3]=bytes([0x20|bank,address&255,address>>8])
                    rom[bank][used:used+len(code)]=code;used+=len(code)
                    animation_ends[bank]=used
                    continue
                if native_used+len(code)>0x3f00:
                    native_ends[native_bank]=native_used;native_bank+=1;native_used=0
                address=0x8000+native_used;entry=(kind*8+sx*2+back)*3
                rom[20][entry:entry+3]=bytes([0x20|native_bank,address&255,address>>8])
                rom[native_bank][native_used:native_used+len(code)]=code;native_used+=len(code)
    for kind,variants in enumerate(cached):
        for sx,record in enumerate(variants):
            blob=bytes([len(record)//3])+record
            if kind>=25 or kind in (1,10,11):
                if used+len(blob)>16128:bank+=1;used=0
                address=0x8000+used;entry=0x380+(kind*4+sx)*3
                rom[20][entry:entry+3]=bytes([0x20|bank,address&255,address>>8])
                rom[bank][used:used+len(blob)]=blob;used+=len(blob)
                animation_ends[bank]=used
                continue
            if native_used+len(blob)>0x3f00:
                native_ends[native_bank]=native_used;native_bank+=1;native_used=0
            address=0x8000+native_used;entry=0x380+(kind*4+sx)*3
            rom[20][entry:entry+3]=bytes([0x20|native_bank,address&255,address>>8])
            rom[native_bank][native_used:native_used+len(blob)]=blob;native_used+=len(blob)
    assert all(len(v)==16384 for v in rom), ('fixed',[(i,len(v))for i,v in enumerate(rom)if len(v)!=16384])
    for sx,record in bag_records.items():
        assert bg[0][1][1]+35+len(record)//10<=128
        for back in range(2):
            program=bytearray()
            for i in range(0,len(record),10):
                cell=record[i:i+10];col=cell[0]&31;row=12+cell[1]
                glyph=bg[0][1][1]+35+i//10
                body=bytearray([0xa8,0xa9,glyph|(cell[0]&128),0x99,(0x3800+back*1024+row*40)&255,(0x3800+back*1024+row*40)>>8])
                values={}
                for scan,v in enumerate(cell[2:]):values.setdefault(v,[]).append(scan)
                for v,scans in values.items():
                    body.extend((0xa9,v))
                    for scan in scans:
                        dest=0x4400+back*0xc00+glyph*8+scan
                        body.extend((0x8d,dest&255,dest>>8))
                program.extend((0x8a,0x18,0x69,col,0xc9,40,0xb0,len(body)))
                program.extend(body)
            program.append(0x60);address=0x8000+native_used
            entry=0x580+(sx*2+back)*2
            rom[20][entry:entry+2]=bytes((address&255,address>>8))
            rom[20][native_used:native_used+len(program)]=program;native_used+=len(program)
    # The two full hoop rectangles have fixed vertical spans. Restoring their
    # uniform background rows with native stores saves address work per row.
    for height in (7,9):
        for width in (4,5):
            for back in range(2):
                program=bytearray();by_glyph={}
                for row in range(9,9+height):
                    glyph=bg[0][0][3072+row*40]
                    for col in range(width):
                        dest=0x3800+back*1024+row*40+col
                        by_glyph.setdefault(glyph,[]).append(dest)
                for glyph,addresses in by_glyph.items():
                    program.extend((0xa9,glyph))
                    for dest in addresses:
                        program.extend((0x9d,dest&255,dest>>8))
                program.append(0x60);address=0x8000+native_used
                entry=0x590+(((height==9)*2+(width==5))*2+back)*2
                rom[20][entry:entry+2]=bytes((address&255,address>>8))
                rom[20][native_used:native_used+len(program)]=program;native_used+=len(program)
    native_ends[native_bank]=native_used
    assert native_bank==20, 'Native stores overlap alternate background bank'
    for scene,(data,counts,_) in enumerate(bg):
        out=bytearray(2048);offset=16
        for band,n in enumerate(counts):
            n=min(n,(2048-offset)//8);out[6+band]=n
            address=0x6c00+offset;out[band]=address&255;out[3+band]=address>>8
            for v in data[band*1024:band*1024+n*8]:out[offset]=v & ~(v>>1&0x55);offset+=1
        assert offset<=2048
        rom[21][scene*2048:(scene+1)*2048]=out
    native_ends[21]=0x3800
    act3.bags(bg,ims[94])
    act3.bags(bg,ims[94],water=True)
    # Scroll the complete six-row spectator strip, including the two bunting
    # rows below the audience. Rotate the original map directly: the older
    # four-row reference tables stay in their existing, bounded ROM area.
    # Identical phase vectors share one load in the native copy program.
    assert bank<18, 'Animation overlaps native crowd banks'
    for scene,nb,codebase,data_start in ((0,18,0x2000,0),(1,19,0x2000,0),(5,19,0x3000,0x1000)):
        data,_,crowdrow=bg[scene];vectors={};details={}
        # Repeated audience/bunting patterns share loads; isolated posts and
        # the entrance are overlaid at their wrapped camera-relative column.
        # This reproduces the complete map while avoiding 240 separate loads.
        for row in range(6):
            original=data[3072+(crowdrow+row)*40:3072+(crowdrow+row+1)*40]
            options=[]
            for period in (1,2,4,5,8,10,20,40):
                base=bytes(Counter(original[col::period]).most_common(1)[0][0] for col in range(period))
                changes=[(col,value) for col,value in enumerate(original) if value!=base[col%period]]
                options.append((period*4+160+len(changes)*11,period,base,changes))
            _,period,base,changes=min(options)
            for col in range(40):
                vector=bytes(base[(col+shift)%period] for shift in range(40))
                vectors.setdefault(vector,[]).append(row*40+col)
            for col,value in changes:details.setdefault(col,{}).setdefault(value,[]).append(row)
        offset=data_start;programs=[bytearray(),bytearray()]
        for vector,cells in vectors.items():
            address=0x8000+offset;rom[nb][offset:offset+40]=vector;offset+=64
            for back in range(2):
                programs[back].extend((0xbd,address&255,address>>8))
                for cell in cells:
                    dest=0x3800+back*0x400+crowdrow*40+cell
                    programs[back].extend((0x8d,dest&255,dest>>8))
        for col,values in details.items():
            address=0x8000+offset
            rom[nb][offset:offset+40]=bytes((col-shift)%40 for shift in range(40));offset+=64
            for back in range(2):
                programs[back].extend((0xbc,address&255,address>>8))
                for value,rows in values.items():
                    programs[back].extend((0xa9,value))
                    for row in rows:
                        dest=0x3800+back*0x400+(crowdrow+row)*40
                        programs[back].extend((0x99,dest&255,dest>>8))
        assert offset<= (0x1000 if scene==1 else 0x2000)
        for back,program in enumerate(programs):
            program.append(0x60);assert len(program)<0x800
            start=codebase+back*0x800;rom[nb][start:start+len(program)]=program
        native_ends[nb]=0x3000 if nb==18 else 0x3f00
    # Edge-clipped hoop/pot stores avoid iterating invisible cells in the
    # densest Act 1 layouts. The lookup is [kind][back][x & 63], three bytes.
    eb,ep=22,0x900
    for group,kind,width in ((0,0,16),(1,3,16),(2,4,16),(3,16,16),(4,17,32)):
        for px in list(range(-32,0))+list(range(128 if kind==17 else 140,160)):
            record=cached[kind][px&3]
            for back in range(2):
                program=bytearray();by_glyph={}
                for i in range(0,len(record),3):
                    col,row,glyph=record[i:i+3];col+=px//4
                    if 0<=col<40:
                        dest=0x3800+back*0x400+row*40+col
                        by_glyph.setdefault(glyph,[]).append(dest)
                for glyph,addresses in by_glyph.items():
                    program.extend((0xa9,glyph))
                    for dest in addresses:program.extend((0x8d,dest&255,dest>>8))
                program.append(0x60)
                if ep+len(program)>0x3f00:native_ends[eb]=ep;eb+=1;ep=0x1200 if eb==23 else 0
                address=0x8000+ep;slot=(group*128+back*64+(px&63))*3
                rom[22][slot:slot+3]=bytes((eb|32,address&255,address>>8))
                rom[eb][ep:ep+len(program)]=program;ep+=len(program)
    native_ends[eb]=ep
    assert eb<=23
    # Transposed flame bytes: one small unrolled copy per physical player.
    # Repeated eight-pose scanline vectors share a load. This preserves every
    # PM byte while leaving room for the foreground rim and scrolling bunting.
    shapes=[]
    for phase in range(8):
        mask=bold.hoop(phase&3,phase>=4)==1
        shape=[sum(int(np.any(row[x*2:x*2+2]))<<(7-x) for x in range(8)) for row in mask]
        shapes.append(shape+[0]*(72-len(shape)))
    flame_vectors={}
    for y in range(72):
        vector=bytes(shapes[p][y] for p in range(8))
        rom[23][0x100+y*8:0x108+y*8]=vector
        flame_vectors.setdefault(vector,[]).append(y)
    hp=0x400
    for back in range(2):
        for slot in range(4):
            program=bytearray()
            for rows in flame_vectors.values():
                src=0x8100+rows[0]*8;program.extend((0xbd,src&255,src>>8))
                for y in rows:
                    dest=0x5800+back*0x800+0x400+slot*256+112+y
                    program.extend((0x8d,dest&255,dest>>8))
            program.append(0x60);address=0x8000+hp;entry=(back*4+slot)*2
            rom[23][entry:entry+2]=bytes((address&255,address>>8))
            rom[23][hp:hp+len(program)]=program;hp+=len(program)
    native_ends[23]=max(hp,native_ends.get(23,0))
    # The left half of each ring is the near side. It is composited into the
    # actor's private glyphs after Charlie/lion, while the far half remains
    # behind them. Keep the existing screen-code colour flag: in blue actor
    # cells a gold rim becomes a light highlight, without recolouring Charlie.
    # All eight flame poses and four horizontal alignments are prepared here.
    # Keep the directory clear of variable-length clipped hoop programs.
    # The new rim uses more of the existing vertical canvas, so their sizes
    # are no longer bounded by the previous hand-picked $1400 endpoint.
    assert native_ends[20] <= 0x3600, native_ends[20]
    mem={n:int(v,16) for n,v in re.findall(r'^(\w+)=\$([0-9A-Fa-f]+)',(ROOT/'src/memory.inc').read_text(),re.M)}
    foreground_bank=23;foreground_used=(native_ends[23]+127)&~127
    foreground_ranges=[(23,foreground_used),(24,0),(25,0),(bank,max(used,0x1400 if bank==17 else 0))]+[(b,0x1400 if b==17 else 0) for b in range(bank+1,18)]
    foreground_region=0;foreground_bytes=0
    for pose in range(8):
        near=bold.hoop(pose&3,pose>=4).copy()
        near[:4]=0;near[:,8:]=0
        for sx in range(4):
            a=np.zeros((((near.shape[0]+7)//8)*8,20),np.uint8)
            a[:near.shape[0],sx:sx+16]=near
            program=bytearray();page=0;foreground_fixups=[];colour_fixups=[]
            def emit(*values):program.extend(values)
            def absolute(op,address):emit(op,address&255,address>>8)
            for row in range(a.shape[0]//8):
                if not a[row*8:row*8+8].any():continue
                screen_row=row+9
                while page<screen_row*40//256:emit(0xe6,mem['z_map']+1);page+=1
                # Reject rows above/below the 32-pixel actor before inspecting
                # their cells. This is especially useful when walking below
                # the raised hoops; no glyphs then require compositing.
                absolute(0xad,mem['gfx_hero_y'])
                emit(0xc9,(screen_row+1)*8,0x90,3,0x4c,0,0);row_skip1=len(program)-2
                emit(0xc9,screen_row*8-31,0xb0,3,0x4c,0,0);row_skip2=len(program)-2
                for col in range(5):
                    tile=a[row*8:row*8+8,col*4:col*4+4]
                    if not tile.any():continue
                    screen_row=row+9;offset=screen_row*40+col
                    while page<offset//256:emit(0xe6,mem['z_map']+1);page+=1
                    band=1 if screen_row<17 else 2
                    count=bg[0][1][band];reserve=35 if band==1 else 28
                    emit(0xa0,offset&255,0xb1,mem['z_map'],0x85,mem['z_colorflag'],0x29,127,0xc9,count)
                    emit(0xb0,3,0x4c,0,0);skip1=len(program)-2
                    emit(0xc9,count+reserve,0x90,3,0x4c,0,0);skip2=len(program)-2
                    # Every private Act 1 glyph is in 64..127. After three
                    # shifts, carry is its high offset bit: 2 + carry gives
                    # the glyph page without five shifts or a runtime table.
                    assert 64<=count<count+reserve<=128
                    emit(0x0a,0x0a,0x0a,0x85,mem['z_glyph'],0xa9,2,0x69,0)
                    absolute(0x0d,mem['band_font']+band)
                    emit(0x85,mem['z_glyph']+1)
                    normal=bold.tile_bytes(tile)[0]
                    mask=bytes(sum((0 if v else 3)<<(6-2*j) for j,v in enumerate(line)) for line in tile)
                    # X selects the existing cell palette. Select the near
                    # rim's gold/light colour during the first masked store,
                    # avoiding a second read/write pass over Charlie's glyph.
                    if np.any(tile==3):emit(0xa2,0,0x24,mem['z_colorflag'],0x10,1,0xe8)
                    for scan,(pixels,keep) in enumerate(zip(normal,mask)):
                        if keep==255:continue
                        emit(0xa0,scan)
                        clear=sum((1 if v==3 else 0)<<(6-2*j) for j,v in enumerate(tile[scan]))
                        if keep:emit(0xb1,mem['z_glyph'],0x29,keep)
                        if clear:
                            emit(0x1d if keep else 0xbd,0,0)
                            colour_fixups.append((len(program)-2,bytes((pixels,pixels&~clear))))
                        else:emit(0x09 if keep else 0xa9,pixels)
                        emit(0x91,mem['z_glyph'])
                    # Absolute skip destinations are relocated after selecting
                    # the ROM region for this whole native program.
                    destination=len(program)
                    for fixup in (skip1,skip2):program[fixup:fixup+2]=struct.pack('<H',destination)
                    # Remember JMP operands; all other bytes are native 6502.
                    foreground_fixups.extend((skip1,skip2))
                for fixup in (row_skip1,row_skip2):
                    struct.pack_into('<H',program,fixup,len(program));foreground_fixups.append(fixup)
            emit(0x60)
            colour_offsets={}
            for fixup,pair in colour_fixups:
                if pair not in colour_offsets:
                    colour_offsets[pair]=len(program);program.extend(pair)
                struct.pack_into('<H',program,fixup,colour_offsets[pair])
                foreground_fixups.append(fixup)
            while foreground_used+len(program)>0x3f00:
                native_ends[foreground_bank]=foreground_used
                foreground_region+=1
                assert foreground_region<len(foreground_ranges), 'Hoop foreground ROM exhausted'
                foreground_bank,foreground_used=foreground_ranges[foreground_region]
            index=pose*4+sx;address=0x8000+foreground_used
            for fixup in foreground_fixups:
                destination=struct.unpack_from('<H',program,fixup)[0]+address
                struct.pack_into('<H',program,fixup,destination)
            foreground_fixups=[]
            rom[20][0x3600+index]=address&255
            rom[20][0x3620+index]=address>>8
            rom[20][0x3640+index]=foreground_bank|32
            rom[foreground_bank][foreground_used:foreground_used+len(program)]=program
            foreground_used+=len(program);foreground_bytes+=len(program)
    assert foreground_used<=0x3f00, 'Hoop foreground overlaps cartridge boot block'
    native_ends[foreground_bank]=foreground_used
    native_ends[20]=0x3680
    print('Hoop foreground native bytes:',foreground_bytes)
    # Compact native deck writers use two row pointers supplied by the
    # renderer. Overlaps retain ordinary masking; each native column clips itself.
    board_blob=bytearray();board_offsets=[]
    for width in range(2,8):
        sprite=ims[30+(width-2)*2]
        for sx in (0,2):
            padded=np.zeros((16,((sprite.shape[1]+sx+3)//4)*4),np.uint8)
            padded[:16,sx:sx+sprite.shape[1]]=sprite
            for middle in (False,True):
                board_offsets.append(len(board_blob));program=bytearray()
                for col in range(padded.shape[1]//4):
                    body=bytearray((0xa0,col))
                    for row in range(2):
                        tile=padded[row*8:row*8+8,col*4:col*4+4]
                        pattern,alt=bold.tile_bytes(tile);glyph=spring_cached[pattern]
                        assert glyph<87,('Uncached native deck',width,sx,row,col,glyph)
                        if not middle or row==0:glyph-=37
                        ptr=mem_z_cell if row==0 else mem_z_bg
                        body.extend((0xa9,glyph|alt,0x91,ptr))
                    # X is the signed screen column of the first sprite cell.
                    program.extend((0x8a,0x18,0x69,col,0xc9,40,0xb0,len(body)))
                    program.extend(body)
                board_blob.extend(program+b'\x60')
    # Foreground programs may also occupy the animation bank's old tail.
    # Allocate after their recorded end, never after the stale sprite cursor.
    while True:
        assert bank<18,'Native decks exceed the animation ROM pool'
        used=max(used,native_ends.get(bank,0),0x1400 if bank==17 else 0)
        if used+len(board_blob)<=16128:break
        bank+=1;used=0
    addresses=[0x8000+used+off for off in board_offsets]
    rom[bank][used:used+len(board_blob)]=board_blob;used+=len(board_blob);animation_ends[bank]=used
    (ROOT/'src/horse-boards.inc').write_text('; Generated native spring decks.\nHORSE_BOARD_BANK='+str(bank|32)+'\nhorse_board_lo: .byte '+','.join(str(a&255)for a in addresses)+'\nhorse_board_hi: .byte '+','.join(str(a>>8)for a in addresses)+'\n')
    (BUILD/'native-cache.json').write_text(json.dumps(native_ends))
    native_ends.update({b:max(native_ends.get(b,0),end) for b,end in animation_ends.items()})
    (ROOT/'assets/native-cache.json').write_text(json.dumps(native_ends))
    assert len(ims)*128<=0x3C00
    # Water shares the normal trampoline crowd, so only the bottom two fonts
    # and map are different. The unused directory-bank tail stores them.
    rom[3][0x3000:0x3800]=bg[6][0][1024:3072]
    rom[3][0x3800:0x3C00]=bg[6][0][3072:4096]
    # Native glyph compositors occupy the unused old rope-directory pages.
    # Their immediate masks/pixels preserve every foreground/background pixel.
    hp=0x1600+len(hero_blend)*2;lists={};freq=Counter(p for poses in hero_blend.values() for p in poses)
    (ROOT/'assets/hero-blend-patterns.json').write_text(json.dumps({str(k):[v.hex() for v in values] for k,values in hero_blend.items()}))
    weights=ROOT/'assets/hero-blend-weights.json'
    if weights.exists():freq=Counter({bytes.fromhex(k):v for k,v in json.loads(weights.read_text()).items()})
    extra_weights=ROOT/'assets/hero-extra-weights.json'
    if extra_weights.exists():freq.update({bytes.fromhex(k):v for k,v in json.loads(extra_weights.read_text()).items()})
    original_native=set(freq)
    # Longer sessions expose expensive masks absent from the earlier routes.
    # Preserve the original programs, then fill a bounded spill region.
    additions=json.loads((ROOT/'assets/hero-retry-weights.json').read_text())
    freq.update({bytes.fromhex(k):v for k,v in additions.items()})
    for variant in range(len(hero_blend)):
        lists[variant]=hp;address=0x8000+hp
        directory[0x1600+variant*2:0x1602+variant*2]=bytes((address&255,address>>8))
        hp+=len(hero_blend[variant])*2
    programs={};tail=0x3B80;suffixes={};spill=0x0E00;spill_suffixes={}
    assert len(ims)*128<=tail
    for pixels in sorted(freq,key=lambda p:(p in original_native,freq[p]),reverse=True):
        rows=[]
        for y,pixel in enumerate(pixels):
            mask=sum(3<<shift for shift in (0,2,4,6) if pixel&(3<<shift)==0)
            if not mask:continue
            row=bytearray((0xa0,y,0xb1,0xb0))
            if mask!=255:row.extend((0x29,mask))
            if pixel:row.extend((0x09,pixel))
            row.extend((0x91,0xb2));rows.append(bytes(row))
        rows.append(b'\x60');cut=len(rows);jump=None
        # Share exact instruction suffixes. This keeps every sampled pattern
        # native without consuming live sprite-directory entries.
        for i in range(len(rows)):
            suffix=b''.join(rows[i:])
            if len(suffix)>3 and suffix in suffixes:
                cut=i;jump=suffixes[suffix];break
        if cut==0:
            programs[pixels]=jump;continue
        code=bytearray(b''.join(rows[:cut]))
        if jump is not None:code.extend((0x4c,jump&255,jump>>8))
        if hp+len(code)<=0x2900:
            address=hp;hp+=len(code)
        elif tail+len(code)<=0x3F00:
            address=tail;tail+=len(code)
        else:
            # Bank 17's first 0x0E00 bytes hold presentation code; its tail
            # is unused by animation, audio, and all other native programs.
            cut=len(rows);jump=None
            for i in range(len(rows)):
                suffix=b''.join(rows[i:])
                if len(suffix)>3 and suffix in spill_suffixes:
                    cut=i;jump=spill_suffixes[suffix];break
            if cut==0:
                programs[pixels]=jump^0xC000;continue
            code=bytearray(b''.join(rows[:cut]))
            if jump is not None:code.extend((0x4c,jump&255,jump>>8))
            if spill+len(code)>0x1400:continue  # Native spring decks start here.
            address=0x8000+spill;programs[pixels]=address^0xC000
            rom[17][spill:spill+len(code)]=code;spill+=len(code)
            offset=0
            for i,row in enumerate(rows[:cut]):
                spill_suffixes[b''.join(rows[i:])]=address+offset;offset+=len(row)
            continue
        programs[pixels]=0x8000+address;directory[address:address+len(code)]=code
        offset=0
        for i,row in enumerate(rows[:cut]):
            suffixes[b''.join(rows[i:])]=0x8000+address+offset;offset+=len(row)
    native_ends[17]=max(native_ends.get(17,0),spill)
    for variant,pixels in hero_blend.items():
        for i,pixel in enumerate(pixels):
            address=programs.get(pixel,0);offset=lists[variant]+i*2
            directory[offset:offset+2]=bytes((address&255,address>>8))
    print('Native trapeze compositors',len(programs),'of',len(freq),'bytes',hp-0x1600+tail-0x3B80)
    native_ends[7]=max(0x3C00,tail)
    (ROOT/'assets/native-cache.json').write_text(json.dumps(native_ends))
    rom[7]=directory
    # Deduplicate the four alignments within each animation font. The spare
    # glyphs form two disjoint composition pools, one per display buffer.
    # Cell codes include the palette bit; no per-frame font copy is needed.
    ballbank=bytearray([255])*16384
    ball_flags=[]
    for phase in range(4):
        f=bytearray(1024);f[:16]=bg[3][0][2048:2064]
        patterns={bytes(f[i*8:i*8+8]):i for i in range(2)}
        for sx in range(4):
            a=np.zeros((32,24),np.uint8);a[30,:]=1
            ball=ball_art[phase];view=a[:30,sx:sx+ball.shape[1]];view[ball!=0]=ball[ball!=0]
            for y in range(4):
                for x in range(6):
                    tile=a[y*8:y*8+8,x*4:x*4+4]
                    pattern,alt=bold.tile_bytes(tile)
                    if pattern not in patterns:
                        code=len(patterns);patterns[pattern]=code;f[code*8:code*8+8]=pattern
                    ball_flags.append(patterns[pattern]|alt)
        assert len(patterns)<=66,('Ball font leaves insufficient composition space',phase,len(patterns))
        # The goal uses seven fixed codes in each screen's private pool.
        # Merging always reserves these codes, so earlier ball contacts cannot
        # overwrite a podium pattern before it enters view.
        goal=bytes([0,0,0,0,0,15,15,170,0,0,0,0,0,255,255,170,
                    0,0,0,0,0,240,240,170]+[255]*8+[170]*8+
                   [255]*5+[170,0,0]+[170]*6+[0,0])
        for base in (86,117):f[base*8:(base+7)*8]=goal
        ballbank[phase*1024:(phase+1)*1024]=f
    assert bank<=17, 'Bank 17 is the last animation bank (its prefix is reserved)'
    assert bank<30, 'Bank 30 reserves the XL upper-RAM program source'
    rom[31]=ballbank
    # Hero overlay metadata and three 8-bit masks per pose in a background tail.
    overlay_ids=list(range(8))+list(range(84,93))
    for i,pid in enumerate(overlay_ids):
        dx,h,masks=bold.OVERLAYS[pid];tops=[];heights=[]
        for c,m in enumerate(masks):
            ys=[y for y,v in enumerate(m) if v];top=min(ys) if ys else 0;bottom=max(ys)+1 if ys else 1
            tops.append(top);heights.append(bottom-top)
            rom[6][0x3000+i*144+c*48:0x3000+i*144+c*48+48]=m[top:bottom].ljust(48,b'\0')
        rom[6][0x2e00+i*12:0x2e00+i*12+12]=bytes(dx+tops+heights+[0,0,0])
    rom[6][0x2c00:0x2d00]=(ROOT/'assets/pal-map.bin').read_bytes()
    common=bytearray(4096);common[:1024]=font()
    pm,hs,sz=pm_shapes();pm=bytearray(pm)
    # The formerly unused PM 12 is the raised Tightrope goal's lattice tower.
    # Eight logical pixels, 88 scanlines; no rectangle overwrites the audience.
    tower=np.zeros((88,8),np.uint8)
    tower[:,0]=tower[:,5]=tower[:,7]=1
    for y in range(88):
        tower[y,1+(y%8)//2]=1;tower[y,4-(y%8)//2]=1
        if y%8==0:tower[y,:]=1
    pm[12*96:13*96]=bytes(sum(int(v)<<(7-x) for x,v in enumerate(row)) for row in tower).ljust(96,b'\0')
    hs[12]=88;sz[12]=0
    for phase in range(4):
        a=bold.hoop(phase)==1;hs[phase]=72
        shape=bytes(sum(int(np.any(row[x*2:x*2+2]))<<(7-x) for x in range(8)) for row in a).ljust(96,b'\0')
        pm[phase*96:(phase+1)*96]=shape
    for phase in range(4):
        a=bold.monkey(phase);mask=a!=0;mask[4:11,:7]=a[4:11,:7]==3
        hs[4+phase]=17;sz[4+phase]=1
        shape=bytes(sum(int(np.any(row[x*2:x*2+2]))<<(7-x) for x in range(8)) for row in mask).ljust(96,b'\0')
        pm[(4+phase)*96:(5+phase)*96]=shape
    for phase in range(2):
        a=bold.spring(phase)!=0;a[:3]=0;hs[10+phase]=12;sz[10+phase]=1
        shape=bytes(sum(int(np.any(row[x*2:x*2+2]))<<(7-x) for x in range(8)) for row in a).ljust(96,b'\0')
        pm[(10+phase)*96:(11+phase)*96]=shape
    for phase in range(4):
        a=bold.dolphin(phase)
        shape=bytes(sum(int(np.any(row[x*2:x*2+2]==4) and not np.any(np.isin(row[x*2:x*2+2],[1,2])))<<(7-x) for x in range(8)) for row in a).ljust(96,b'\0')
        pm[(17+phase)*96:(18+phase)*96]=shape
    common[1024:1024+len(pm)]=pm
    # Three Act 3 flame projectiles use otherwise idle hardware players.
    # Reuse obsolete pot PM IDs; Act 1 pots are cached character graphics.
    for pid,pose in ((8,82),(9,83)):
        shape=bytes(sum(int(v!=0)<<(7-x) for x,v in enumerate(row)) for row in projectile_art[pose]).ljust(96,b'\0')
        pm[pid*96:(pid+1)*96]=shape;hs[pid]=32;sz[pid]=0
    for pid,pose in ((10,110),(11,111)):
        a=projectile_art[pose]
        shape=bytes(sum(int(v!=0)<<(7-x) for x,v in enumerate(row)) for row in a).ljust(96,b'\0')
        pm[pid*96:(pid+1)*96]=shape;hs[pid]=16;sz[pid]=0
    common[1024:1024+len(pm)]=pm
    # Common data copied by bootstrap to $7000: masks, trig, PM metadata.
    common[3072:3328]=bytes(v & ~(v>>1&0x55) for v in range(256))
    common[3328:3392]=bytes(x&255 for x in tx);common[3392:3456]=bytes(ty)
    common[3456:3456+len(hs)]=bytes(hs);common[3488:3488+len(sz)]=bytes(sz)
    common[3520:3538]=bytes(n for _,ns,_ in bg[:6] for n in ns)
    common[3540:3546]=bytes(cr for _,_,cr in bg[:6])
    common[3552:3555]=bytes(bg[6][1])
    common[3584:3624]=bytes(water_codes)
    common[3648:4032]=bytes(ball_flags)
    (BUILD/'common.bin').write_bytes(common)
    from title_assets import install as install_title
    install_title(rom,bg)
    assert all(len(v)==16384 for v in rom), [(i,len(v))for i,v in enumerate(rom)if len(v)!=16384]
    (BUILD/'asset-banks.bin').write_bytes(b''.join(rom))
    (BUILD/'asset-info.json').write_text(json.dumps({'pose_names':names,'directory_entries':records,'unique_stamps':len(dedup),'animation_bytes':sum(len(k) for k in dedup),'last_animation_bank':bank,'largest_stamp_cells':cellsmax,'background_glyph_counts':[ns for _,ns,_ in bg],'PM_heights':hs},indent=2))
    can=Image.new('RGB',(640,400),(12,14,20));d=ImageDraw.Draw(can)
    for i,(name,im) in enumerate(zip(names[:18],ims[:18])):
        pic=Image.fromarray(PAL[im]).resize((im.shape[1]*4,im.shape[0]*2),Image.Resampling.NEAREST)
        x=(i%6)*105;y=(i//6)*125;can.paste(pic,(x,y+20));d.text((x,y),name,fill='white')
    (ROOT/'research').mkdir(exist_ok=True)
    can.save(ROOT/'research/prepared-actors.png')
    # The portable source package builds from these canonical prepared bytes.
    for name in ('common.bin','asset-banks.bin','asset-info.json'):
        (ROOT/'assets'/name).write_bytes((BUILD/name).read_bytes())
    print((BUILD/'asset-info.json').read_text())
if __name__=='__main__':build()
