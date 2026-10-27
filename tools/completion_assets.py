"""Native celebration poses assembled from the supplied arcade sprite pixels."""
import numpy as np
from PIL import Image
from act3_assets import tile,convert

def pair(top,bottom,w=12,h=32):return convert(np.concatenate([tile(top),tile(bottom)]),w,h)
def square(codes,w=20,h=32):
 p=[tile(c) for c in codes]
 return convert(np.block([[p[0],p[1]],[p[2],p[3]]]),w,h)
def poses(ims,names):
 assert len(ims)==116,len(ims)
 art=[('prize-coin',convert(tile(0x143),8,12)),
      ('reward-bird-0',np.fliplr(convert(np.concatenate([tile(0x144),tile(0x145)],axis=1),24,16))),
      ('reward-bird-1',np.fliplr(convert(np.concatenate([tile(0x146),tile(0x147)],axis=1),24,16))),
      ('celebration-partner-0',square([0x176,0x177,0x17e,0x17f])),
      ('celebration-partner-1',square([0x174,0x175,0x17c,0x17d])),
      ('celebration-charlie-0',pair(0x155,0x15d)),
      ('celebration-charlie-kiss',pair(0x15a,0x17b)),
      ('secret-doll',convert(tile(0x14f),10,16))]
 for pid,(n,a) in zip((8,9,10,14,15,16,17,93),art):ims[pid]=a;names[pid]=n
 return ims,names
