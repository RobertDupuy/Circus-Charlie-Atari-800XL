"""Visible distance boards, high-jump rewards and a complete lion celebration.

Runs the assembled 6502. Pixel expectations come from the prepared source art;
normal neutral-input trampoline attempts exercise collection, roof contact,
falling, retries and the five-second game-over path.
"""
from cpu import Machine, ROOT
from pathlib import Path
import json, sys
import numpy as np
sys.path.insert(0,str(ROOT/'tools'))
import bold_art

def pixels(m,back=None):
    if back is None:back=m.get('back')
    result=np.zeros((176,160),np.uint8)
    for row in range(22):
        band=m.m[m.labels['row_band']+row]
        font=0x4000+back*3072+band*1024
        if m.get('act')==3 and band==2:font=m.m[m.labels['frame_ballfont']+back]*256
        for col in range(40):
            code=m.m[0x3800+back*1024+row*40+col]
            for y in range(8):
                b=m.m[font+(code&127)*8+y]
                for x,shift in enumerate((6,4,2,0)):
                    c=(b>>shift)&3
                    result[row*8+y,col*4+x]=4 if c==3 and code&128 else c
    return result

def bankcall(m,name):
    a=m.labels[name]
    for i,v in enumerate((0xa9,0x31,0x8d,0,0xd5,0x20,a&255,a>>8,0x60)):m.m[0x300+i]=v
    m.labels['_details_call']=0x300
    return m.call('_details_call')

def tick(m,joy=0,fire=0,render=True):
    m.wordset('host_frames',(m.word('host_frames')+1)&65535)
    m.set('input',joy);m.set('fire_latch',fire);m.call('game_tick')
    if m.get('need_stage'):m.call('load_stage')
    if render:
        m.set('back',m.get('back')^1);m.call('render_frame')
        assert not m.get('fault'),(m.get('act'),m.get('mode'),m.get('tramp_death_age'))

# Native high bag equals the generic masked stamp, including negative clipping,
# tent stripes, an empty sky cell, both buffers, and a readable blue dollar.
bag_cases=0;blue=0;cycles_saved=0
for back in (0,1):
    m=Machine();m.stage(2);m.set('passed',1);m.set('back',back);m.call('render_frame');m.c.at_save_slot(0)
    for x in range(-12,164,4):
        m.c.at_restore_slot(0);m.wordset('sprite_x',x&65535)
        a=bankcall(m,'detail_high_bag');actual=pixels(m)
        m.c.at_restore_slot(0);m.wordset('sprite_x',x&65535);m.set('sprite_y',8);m.set('sprite_pose',94)
        b=m.call('draw_stamp');expected=pixels(m)
        assert np.array_equal(actual,expected),('high bag pixels',back,x)
        for dy,dx in zip(*np.nonzero(bold_art.money_bag()==4)):
            if 0<=x+dx<160:
                assert actual[8+dy,x+dx]==4;blue+=1
        cycles_saved+=b-a;bag_cases+=1

# Every act has world-anchored meter boards; the horse's back-track boards
# leave its crowded spring/actor font untouched. Compare reused/fresh buffers.
sign_cases=0
for scene in range(7):
    m=Machine();m.stage(scene);m.c.at_save_slot(0)
    anchor=808 if scene==0 else 616 if scene==5 else m.word('stage_end')-8-3*192
    label='30M';expected=bold_art.distance_sign(label);expected[expected==3]=2
    for i,x in enumerate((156,120,72,20,3,0,-3,-12,72,156)):
        camera=anchor-x;back=i&1
        def place():
            m.wordset('camera',camera);m.wordset('world',camera+140);m.set('back',back)
        place();m.c.at_save_slot(1);m.call('render_frame');actual=pixels(m);m.c.at_save_slot(2)
        left=x//4*4;lo=max(0,left);hi=min(160,left+16);y=80 if scene==4 else 168
        assert np.array_equal(actual[y:y+8,lo:hi],expected[:,lo-left:hi-left]),('meter board',scene,x)
        m.c.at_restore_slot(0);place();m.call('render_frame')
        assert np.array_equal(actual,pixels(m)),('old marker pixels',scene,x)
        m.c.at_restore_slot(2);sign_cases+=1
    assert not m.get('fault')

# Cached celebration text must match freshly copied glyphs in every scene,
# through both display buffers and changes in the surrounding actor poses.
text_cases=0
for scene in range(7):
    m=Machine();m.stage(scene);m.call('finish_act')
    for i,t in enumerate((0,1,2,7,8,16,32,54,64,96,136,160,192,220)):
        m.set('clear_elapsed',t);m.set('back',i&1);m.c.at_save_slot(0)
        m.call('render_frame');actual=pixels(m);m.c.at_save_slot(1)
        m.c.at_restore_slot(0);m.m[m.labels['clear_text_cache']+(i&1)]=255
        m.call('render_frame');assert np.array_equal(actual,pixels(m)),('cached victory text',scene,t)
        m.c.at_restore_slot(1);text_cases+=1

# Natural neutral input reaches a bag on the third bounce and the canvas on
# the fourth, then visibly falls instead of teleporting to the pedestal.
losses=[]
for rank in range(6):
    m=Machine();m.stage(2,rank)
    for attempt in range(3):
        seen_bag=False;collected=None;previous_height=0
        for t in range(300):
            if not m.get('passed'):
                if m.get('bounce_count')<3:assert m.get('jump_pixels')<=58
                seen_bag=True
            tick(m)
            if m.get('mode')==2:
                assert not m.get('death_drop'),('stale fall on retry',rank,attempt,t)
                assert m.get('feet')+m.get('jump_pixels')==130,('below trampoline',rank,attempt,t)
            if m.get('passed') and collected is None:collected=(m.get('bounce_count'),m.get('jump_pixels'))
            if m.get('mode')==3:break
            previous_height=m.get('jump_pixels')
        assert m.get('mode')==3 and m.get('tramp_death_reason')==4,(rank,attempt,t)
        if attempt==0:
            assert seen_bag and collected is not None and collected[0]==3 and collected[1]>=74
            prize_height=collected[1]
        else:
            assert not seen_bag and m.get('passed'), 'Collected bags must stay collected after retry'
        assert previous_height==91 and m.get('jump_pixels')==92
        hud=bytes(m.m[0x6a00+m.get('back')*160+80:0x6a00+m.get('back')*160+120])
        assert b'HEAD THROUGH THE BIG TOP' in hud
        tick(m);assert m.get('jump_pixels')==92
        high=pixels(m);heights=[]
        while m.get('mode')==3:
            heights.append(m.get('jump_pixels'));tick(m)
        assert 0 in heights and 59 in heights and max(heights)==92
        losses.append(dict(rank=rank,attempt=attempt,prize_height=prize_height,roof_height=92))
        if attempt<2:
            assert m.get('mode')==1 and not m.get('death_drop'),('retry intro retains fall',rank,attempt)
            assert m.get('feet')==130 and not m.get('jump_pixels'),('retry does not start on pedestal',rank,attempt)
            while m.get('mode')==1:tick(m)
            assert m.get('mode')==2 and not m.get('tramp_death_reason')
    assert m.get('mode')==6
    for _ in range(305):
        tick(m)
        if m.get('mode')==0:break
    assert m.get('mode')==0

# A win shows an upright front-facing wave and carried bag after any life.
for rank in range(6):
    m=Machine();m.stage(0,rank);m.call('finish_act')
    assert m.word('world')-m.word('camera')-12==108,'Prepared victory pose requires its fixed goal anchor'
celebrations=[]
for hurt in (0,1):
    m=Machine();m.stage(0);m.set('stage_hurt',hurt)
    route=json.loads((ROOT/'assets/routes/mechanics-route-0-0.json').read_text())
    for joy,fire in route:
        tick(m,joy,fire,render=False)
        if m.get('mode')==4:break
    assert m.get('mode')==4 and m.word('world')==m.word('stage_end')
    centre=m.word('world')-m.word('camera');platform=(centre-16)//4*4
    frames={}
    for t in range(144):
        m.set('back',t&1);m.call('render_frame');assert not m.get('fault')
        if t in (0,8,64,69):frames[t]=pixels(m)
        if t==64:
            for dy,dx in zip(*np.nonzero(bold_art.money_bag()==4)):
                assert frames[t][80+dy,centre-4+dx]==4
        m.call('game_tick')
    lion=frames[0][135:155,centre-12:centre+12]
    assert np.array_equal(lion,frames[8][135:155,centre-12:centre+12]),'Lion must keep planted feet'
    feet=np.nonzero(lion[-1])[0]+centre-12
    assert len(feet) and feet.min()>=platform and feet.max()<platform+32
    assert np.all(frames[0][155,feet]!=0),'Feet must meet the platform top'
    assert not np.array_equal(frames[0][107:122,centre-12:centre+12],frames[8][107:122,centre-12:centre+12]),'Raised arms must wave'
    assert np.array_equal(frames[0][110:135,centre-3:centre+3],frames[8][110:135,centre-3:centre+3]),'Head, upright torso and legs must stay planted'
    for frame in (frames[0],frames[8]):
        assert frame[115,centre-2]==frame[115,centre+1]==1,'Front view needs two visible eyes'
        assert np.all(frame[134,centre-4:centre-1]==2) and np.all(frame[134,centre+1:centre+4]==2),'Both shoes must stay at lion-back height'
    assert m.get('clear_bird') and m.get('clear_prize')==10
    celebrations.append(dict(prior_life_lost=bool(hurt),planted_lion=True,upright_front_view=True,stationary_body_and_feet=True,raised_arm_wave=True,blue_dollar_bag=True,coin_drops=10))

report=dict(meter_pixel_cases=sign_cases,high_bag_pixel_cases=bag_cases,blue_dollar_pixels=blue,celebration_text_cases=text_cases,
            mean_high_bag_cycles_saved=round(cycles_saved/bag_cases,1),natural_roof_losses=losses,celebrations=celebrations)
(ROOT/'build/presentation-details.json').write_text(json.dumps(report,indent=2)+'\n');print(report)
