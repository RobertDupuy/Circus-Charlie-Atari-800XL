"""Pixel reference for near-rim occlusion, using the assembled cartridge.

Render an ordinary actor-over-hoop frame with the new final pass disabled.
Independently composite only the near semicircle into the actor's private
cells, then compare the native result. The far side and resident glyphs must
remain unchanged. Fixtures exercise rendering; normal playthroughs are separate.
"""
import sys,json
import numpy as np
from cpu import Machine,ROOT
sys.path.insert(0,str(ROOT/'tools'))
import bold_art

def read_pixels(m,back):
    screen=np.array(m.m[0x3800+back*1024:0x3800+back*1024+880],np.uint8).reshape(22,40)
    fonts=np.array(m.m[0x4000+back*3072:0x4000+back*3072+3072],np.uint8).reshape(3,128,8)
    band=np.array([0]*8+[1]*9+[2]*5)
    bits=fonts[band[:,None],screen&127]
    values=(bits[:,:,:,None]>>np.array([6,4,2,0]))&3
    values=np.where((values==3)&((screen[:,:,None,None]&128)!=0),4,values)
    return values.transpose(0,2,1,3).reshape(176,160).copy(),screen,fonts

m=Machine();m.stage(0)
m.wordset('world',500);m.call('update_camera');m.set('jumping',1)
for i in range(4):m.m[m.labels['lion_active']+i]=0
m.m[m.labels['lion_active']]=1
m.c.at_save_slot(0)
count=changed=near_pixels=0;peak=0
for small in (False,True):
    for phase in range(4):
        near=bold_art.hoop(phase,small).copy();near[:4]=0;near[:,8:]=0
        for height in (0,8,24,40,55):
            for delta in range(-8,26,3):
                for back in (0,1):
                    m.c.at_restore_slot(0)
                    m.set('back',back);m.set('jump_pixels',height);m.wordset('anim_clock',phase*4)
                    m.m[m.labels['hoop_type']]=2 if small else 0
                    pos=500+delta;m.m[0x940]=pos&255;m.m[0x950]=pos>>8
                    m.c.at_save_slot(1)
                    m.m[m.labels['lion_hoop_foreground']]=0x60
                    m.call('render_frame');before,screen,fonts=read_pixels(m,back)
                    expected=before.copy();left=pos-8-m.word('camera')
                    for y,x in zip(*np.nonzero(near)):
                        py=int(y)+72;px=int(x)+left
                        if not (0<=px<160 and 0<=py<176):continue
                        row=py//8;col=px//4;band=0 if row<8 else 1 if row<17 else 2
                        code=int(screen[row,col]);glyph=code&127;first=m.m[0x650+band]
                        if not first<=glyph<first+m.m[m.labels['gfx_reserve']+band]:continue
                        colour=int(near[y,x])
                        if colour==3 and code&128:colour=2
                        expected[py,px]=colour
                    m.c.at_restore_slot(1);peak=max(peak,m.call('render_frame'))
                    actual,after_screen,after_fonts=read_pixels(m,back)
                    assert np.array_equal(actual,expected),(small,phase,height,delta,back)
                    assert np.array_equal(screen,after_screen),'Foreground must not allocate or change screen codes'
                    for band in range(3):
                        n=m.m[0x650+band]
                        assert np.array_equal(fonts[band,:n],after_fonts[band,:n]),'Resident glyph was modified'
                    assert np.array_equal(actual[:,left+8:],before[:,left+8:]),'Far side changed'
                    changes=int(np.count_nonzero(actual!=before))
                    near_pixels+=changes;changed+=bool(changes);count+=1
                    assert m.get('fault')==0

assert changed>100 and near_pixels>1000,(changed,near_pixels)

# Inject audio interrupts into the new banked foreground pass itself, with a
# real overlap already drawn. Ordinary initial-stage IRQ tests have no hoop
# crossing and therefore do not exercise these new native ROM programs.
interrupts=0
for small in (False,True):
    m=Machine();m.stage(0);m.wordset('world',500);m.call('update_camera')
    m.set('jumping',1);m.set('jump_pixels',40);m.wordset('anim_clock',4)
    for i in range(4):m.m[m.labels['lion_active']+i]=int(i==0)
    m.m[m.labels['hoop_type']]=2 if small else 0
    m.m[0x940]=500&255;m.m[0x950]=500>>8
    m.call('audio_init');m.call('audio_start',a=0,x=0);m.call('audio_start',a=14,x=1)
    nmi=m.labels['nmi'];m.m[0xfffa]=nmi&255;m.m[0xfffb]=nmi>>8
    m.set('loading',0);m.set('ready',0);m.set('phase',0)
    entry=m.labels['lion_hoop_foreground'];opcode=m.m[entry];m.m[entry]=0x60
    m.call('render_frame');m.m[entry]=opcode;m.c.at_save_slot(0)
    cycles=m.call('lion_hoop_foreground');expected=bytes(m.m[0x3400:0x6800])
    for kind in (0x40,0x80):
        for delay in range(20,cycles,97):
            m.c.at_restore_slot(0);m.m[0xd40f]=kind;m.set('dli_index',1)
            m.c.at_force_nmi(delay);m.call('lion_hoop_foreground')
            assert bytes(m.m[0x3400:0x6800])==expected,('foreground interrupt',small,kind,delay)
            assert m.get('fault')==0;interrupts+=1
report={'pixel_reference_cases':count,'cases_with_visible_occlusion':changed,
        'near_side_pixel_changes':near_pixels,'far_side_unchanged':True,
        'screen_codes_and_resident_glyphs_unchanged':True,'peak_render_cpu_cycles':peak,
        'foreground_audio_interrupt_cases':interrupts}
(ROOT/'build/hoop-depth.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report,indent=2))
