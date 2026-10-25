"""One-time extraction from the preceding verified ROM study.
Normal builds use assets/reference.npz and do not require the source ROMs.
"""
from pathlib import Path
import numpy as np
from PIL import Image
R=Path(__file__).resolve().parents[1];S=R.parent/'circus-study'
ram=(S/'evidence/c64/act-1-180.ram').read_bytes()
sprites=np.zeros((27,21,12),np.uint8)
for n in range(128,155):
 for y in range(21):
  for x in range(12):sprites[n-128,y,x]=(ram[n*64+y*3+x//4]>>(6-2*(x%4)))&3
rgb=np.array(Image.open(S/'evidence/c64/act-1-180.png').convert('RGB'))[36:236,32:352]
ix=np.zeros((200,160),np.uint8)
for c,v in {(255,255,255):2,(129,51,56):1,(142,60,151):1,(237,241,113):3,(117,206,200):4,(86,172,77):4}.items():ix[np.all(rgb[:,::2]==c,axis=2)]=v
v=(S/'evidence/sg-play/frame-3600.vram').read_bytes();horse=np.zeros((32,32),np.uint8)
for pattern,x,y in [(156,0,16),(160,16,16),(144,16,0)]:
 for py in range(16):
  for px in range(16):
   b=v[0x1800+(pattern&252)*8+(16 if px>=8 else 0)+py]
   if b&(128>>(px&7)):horse[y+py,x+px]=2
np.savez_compressed(R/'assets/reference.npz',sprites=sprites,crowd=ix[24:72],horse=np.maximum(horse[:,::2],horse[:,1::2]))
