"""Prepared distance boards, upright lion celebration and torn canvas."""
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw
import bold_art as bold
R=Path(__file__).resolve().parents[1]

def victory_charlie(phase):
    # A dedicated front view, drawn at native double-width pixel proportions.
    # Both eyes look out at the audience. Only the raised arms change: the
    # head, straight torso, separated legs and planted shoes never bob or sway.
    im=Image.new('L',(24,28));d=ImageDraw.Draw(im)
    for side in (0,1):
        def point(x,y):return (23-x if side else x,y)
        arm=[point(x,y) for x,y in ([(9,14),(7,10),(6,4)] if phase==0 else [(9,14),(5,10),(3,6)])]
        d.line(arm,fill=1,width=2)
        x,y=point(6,2) if phase==0 else point(3,4)
        d.rectangle((x-1,y-1,x,y+1),fill=2)
    # Keep moving sleeves out of the fixed head/body silhouette.
    d.rectangle((9,3,14,27),fill=0)
    # Blue cap, yellow hair, two eyes and a centred smile; no profile nose.
    d.rectangle((10,3,13,4),fill=4)
    d.rectangle((9,5,14,6),fill=4)
    d.rectangle((8,6,15,6),fill=4)
    d.rectangle((9,7,14,11),fill=2)
    d.point((8,8),fill=3);d.point((15,8),fill=3)
    d.point((10,8),fill=1);d.point((13,8),fill=1)
    d.point((11,10),fill=1);d.point((12,10),fill=1)
    d.rectangle((10,12,13,12),fill=2)
    # Jacket and collar, straight trousers, and two stationary shoes.
    d.rectangle((9,13,14,20),fill=1)
    d.line((10,13,11,14,12,14,13,13),fill=2)
    d.point((11,16),fill=3);d.point((11,18),fill=3)
    d.rectangle((10,21,13,22),fill=1)
    d.rectangle((10,23,10,26),fill=1)
    d.rectangle((13,23,13,26),fill=1)
    d.line((8,27,10,27),fill=2)
    d.line((13,27,15,27),fill=2)
    return np.array(im)

def install(ims,names):
    # Keep the lion's planted legs identical while Charlie waves to the crowd.
    last=np.nonzero(ims[84])[0].max()+1
    lion=np.array(Image.fromarray(ims[84][14:last]).resize((24,20),Image.Resampling.NEAREST))
    for phase,pid in enumerate((0,5)):
        canvas=np.zeros((48,24),np.uint8);canvas[28:]=lion
        canvas[:28]=victory_charlie(phase)
        ims[pid]=canvas;names[pid]='lion-victory-front-wave-'+str(phase)
        # Colour is already in the character pixels; do not reuse a walking
        # Charlie hardware-player mask on the taller celebration composite.
        bold.OVERLAYS[pid]=([0,0,0],48,[bytes(48)]*3)
    roof=Image.new('L',(24,8));d=ImageDraw.Draw(roof)
    d.polygon([(0,0),(8,0),(8,2),(6,3),(8,5),(5,7),(2,4),(0,4)],fill=2)
    d.polygon([(16,0),(23,0),(23,4),(20,5),(19,7),(16,4),(18,2)],fill=2)
    d.line((0,1,5,1,4,3,6,5),fill=3)
    d.line((19,1,23,1),fill=4);d.line((19,3,21,5),fill=4)
    ims[111]=np.array(roof);names[111]='torn-big-top'
    labels=['GOAL']+[str(i*10)+'M' for i in range(1,20)]
    patterns=[]
    for label in labels:
        art=bold.distance_sign(label)
        for col in range(4):
            tile,alt=bold.tile_bytes(art[:,col*4:col*4+4]);assert alt==128
            patterns.extend(tile)
    text='; Generated opaque 16 x 8 distance boards: GOAL, 10M .. 190M.\ndetail_sign_tiles:\n'
    for i in range(0,len(patterns),16):text+=' .byte '+','.join(map(str,patterns[i:i+16]))+'\n'
    bag=bold.money_bag();a=np.zeros((16,8),np.uint8);a[:14]=bag
    for label,values in [('detail_bag_pixels',[]),('detail_bag_masks',[])]:
        for row in range(2):
            for col in range(2):
                tile=a[row*8:row*8+8,col*4:col*4+4]
                pixels,alt=bold.tile_bytes(tile);assert alt==128
                values.extend(pixels if label.endswith('pixels') else [sum(3<<(6-x*2) for x,v in enumerate(line) if not v) for line in tile])
        text+=label+': .byte '+','.join(map(str,values))+'\n'
    (R/'src/details-art.inc').write_text(text)
    return ims,names
