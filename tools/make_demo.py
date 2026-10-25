"""Regenerate ordinary joystick/fire demo streams after a gameplay change.
Build once first, run this script, then build again to embed the new inputs.
"""
from pathlib import Path
import sys,json,struct
R=Path(__file__).resolve().parents[1];sys.path.insert(0,str(R/'tests'))
from playthrough import run
reports=[run(a) for a in range(7)]
assert all(r['result']=='clear' for r in reports)
data=bytearray(14)
for a in range(7):
 inputs=json.loads((R/f'build/inputs-act-{a+1}.json').read_text())
 struct.pack_into('<H',data,a*2,0x9000+len(data))
 previous=None;count=0
 for joy,fire in inputs+[[0,0]]*255:
  value=joy|(fire<<7)
  if value!=previous or count==255:
   if count:data.extend([count,previous])
   previous=value;count=0
  count+=1
 if count:data.extend([count,previous])
assert len(data)<=0x1800,'Demo packets overlap HUD templates'
(R/'assets/demo-inputs.bin').write_bytes(data)
print('Prepared',len(data),'RLE bytes; rebuild the cartridge to embed them.')
