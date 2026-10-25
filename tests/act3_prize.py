"""Prepared prizes must preserve generic pixels over the moving crowd."""
from cpu import Machine,ROOT
import numpy as np,json

def pixels(m):
 screen=np.array(m.m[0x3800+m.get('back')*1024:0x3800+m.get('back')*1024+880],np.uint8).reshape(22,40)
 fonts=np.array(m.m[0x4000+m.get('back')*3072:0x4000+m.get('back')*3072+3072],np.uint8).reshape(3,128,8)
 band=np.array([m.m[m.labels["row_band"]+r] for r in range(22)])
 bits=fonts[band[:,None],screen&127]
 values=bits[:,:,:,None]>>np.array([6,4,2,0])&3
 return np.where((values==3)&((screen[:,:,None,None]&128)!=0),4,values)

cases=0;saved=0
for scene in (2,6):
 m=Machine();m.stage(scene);m.c.at_save_slot(0)
 for index in range(25):
  world=(48 if scene==6 else 52)+index//3*192+index%3*66
  for delta in (-8,-1,0,3,12,40,81,140,159):
   for shift in range(4):
    camera=max(0,world-delta+shift)
    for back in (0,1):
     m.c.at_restore_slot(0);m.wordset('camera',camera);m.set('back',back)
     m.set('tramp_index',index);m.wordset('world',camera+60)
     m.c.at_save_slot(1);a=m.call('render_frame');actual=pixels(m)
     m.c.at_restore_slot(1);entry=m.labels['tramp_bag'];target=m.labels['water_stamp' if scene==6 else 'draw_stamp']
     m.m[entry]=0x4c;m.m[entry+1]=target&255;m.m[entry+2]=target>>8
     b=m.call('render_frame');expected=pixels(m)
     assert np.array_equal(actual,expected),(scene,index,delta,shift,back)
     saved+=b-a;cases+=1
report=dict(pixel_reference_cases=cases,mean_cpu_cycles_saved=round(saved/cases,1))
(ROOT/'build/act3-prize.json').write_text(json.dumps(report,indent=2));print(report)
