"""Pixel reference checks for the prepared object paths and double-buffer edge erasure."""
from cpu import Machine, ROOT
from playthrough import controls
import hashlib, json

def pixels(m,back):
 out=bytearray()
 for row in range(22):
  band=0 if row<8 else 1 if row<17 else 2
  for scan in range(8):
   for col in range(40):
    code=m.m[0x3800+back*0x400+row*40+col]
    bits=m.m[0x4000+back*0xc00+band*0x400+(code&127)*8+scan]
    for shift in (6,4,2,0):
     v=(bits>>shift)&3;out.append(4 if v==3 and code&128 else v)
 return bytes(out)

# Compare a reused screen/font buffer with a fresh-stage rendering. The
# fixture covers partial clipping, every horizontal shift and both buffers.
m=Machine();m.stage(0);m.c.at_save_slot(0);count=0
for world in list(range(0,65))+list(range(64,-1,-1)):
 for height in (0,28,64,92):
  back=count&1;m.wordset('world',world);m.call('update_camera');m.set('jump_pixels',height);m.set('back',back)
  m.c.at_save_slot(1);m.call('render_frame');actual=pixels(m,back);m.c.at_save_slot(2)
  m.c.at_restore_slot(0);m.wordset('world',world);m.call('update_camera');m.set('jump_pixels',height);m.set('back',back)
  m.call('render_frame');expected=pixels(m,back)
  assert actual==expected,('edge restore',world,height,back)
  m.c.at_restore_slot(2);count+=1
report={'edge_restore_frames':count,'edge_pixels_identical':True}
(ROOT/'build/bold-render.json').write_text(json.dumps(report,indent=2));print(report)

# The complete audience/bunting strip rotates with the camera. Check six
# rows against the original map, including the font-band boundary and wrap.
rom=(ROOT/'build/Circus-Charlie-SIC512.car').read_bytes()[16:];crowds=0
for scene in range(7):
 m=Machine();m.stage(scene);a=2 if scene==6 else scene
 for phase in range(40):
  for back in range(2):
   m.wordset('camera',phase*4);m.set('back',back);m.m[m.labels['z_map']+1]=0x38+back*4
   m.call('scroll_crowd');cy=13 if a in (1,5) else 3
   actual=bytes(m.m[0x3800+back*1024+cy*40+i] for i in range(240))
   expected=bytearray()
   for row in range(cy,cy+6):
    off=(a+1)*16384+3072+row*40
    original=rom[off:off+40];expected.extend(original[phase:]+original[:phase])
   assert actual==expected,('audience/bunting',scene,phase,back);crowds+=1
# Compare each clipped native-object program with the generic clipped records.
m=Machine();m.stage(0);m.set('back',0);m.call('render_frame');m.c.at_save_slot(0)
p=m.labels['gfx_cached_select'];code=bytes(m.m[p:p+200]);edge=m.labels['gfx_native_edge']
patch=p+code.index(bytes((0x4c,edge&255,edge>>8)));edges=0
for kind in (0,3,4,16,17):
 for x in list(range(-32,0))+list(range(128 if kind==17 else 140,160)):
  for back in range(2):
   results=[]
   for reference in (False,True):
    m.c.at_restore_slot(0);m.set('back',back);m.m[m.labels['z_map']+1]=0x38+back*4
    m.set('gfx_cached_kind',kind);m.wordset('sprite_x',x&65535)
    if reference:
     for i in range(3):m.m[patch+i]=0xea
    m.call('gfx_cached_select');results.append(bytes(m.m[0x3800+back*1024+i] for i in range(880)))
   assert results[0]==results[1],('clipped object',kind,x,back);edges+=1
report.update(crowd_reference_cases=crowds,scrolling_rows=6,bunting_scrolls_with_camera=True,clipped_object_reference_cases=edges)

# The native money-bag copy must match its prepared clipped stamp, including
# negative X and both font buffers. Its parent hoop owns the dirty rectangle.
m=Machine();m.stage(0);m.set('back',0);m.call('render_frame');m.c.at_save_slot(0)
bags=0
for x in range(-8,160):
 for back in range(2):
  results=[]
  for native in (False,True):
   m.c.at_restore_slot(0);m.set('back',back);m.m[m.labels['z_map']+1]=0x38+back*4
   for band in range(3):m.m[m.labels['band_font']+band]=0x40+back*12+band*4
   m.set('gfx_cached_kind',16);m.wordset('sprite_x',(x-3)&65535);m.call('gfx_cached_select')
   m.wordset('sprite_x',x&65535);m.set('sprite_y',96);m.set('sprite_pose',116)
   m.call('lion_arcade_bag_draw' if native else 'draw_stamp')
   results.append(pixels(m,back))
  assert results[0]==results[1],('money bag',x,back);bags+=1
report['money_bag_reference_cases']=bags

# Native clearing of the fixed hoop rectangles must restore the same screen
# bytes as the general rectangle loop at every legal column and buffer.
m=Machine();m.stage(0);m.call('render_frame');m.c.at_save_slot(0)
restore=m.labels['gfx_restore_rects'];fast=m.labels['lion_restore_ring_rect']
code=bytes(m.m[restore:restore+256]);patch=restore+code.index(bytes((0x20,fast&255,fast>>8)))
clears=0
for height in (7,9):
 for width in (4,5):
  for col in range(41-width):
   for back in range(2):
    results=[]
    for reference in (False,True):
     m.c.at_restore_slot(0);m.set('back',back);m.m[m.labels['z_map']+1]=0x38+back*4
     m.m[m.labels['gfx_rect_count']+back]=4
     rect=0xde00+back*256;offset=360+col
     for i,v in enumerate((offset&255,offset>>8,width,height|128)):m.m[rect+i]=v
     for i in range(880):m.m[0x3800+back*1024+i]=(i*13+31)&255
     if reference:
      for i,v in enumerate((0x18,0xea,0xea)):m.m[patch+i]=v
     m.call('gfx_restore_rects');results.append(bytes(m.m[0x3800+back*1024+i] for i in range(880)))
    assert results[0]==results[1],('hoop clear',height,width,col,back);clears+=1
report['hoop_restore_reference_cases']=clears
(ROOT/'build/bold-render.json').write_text(json.dumps(report,indent=2));print(report)
