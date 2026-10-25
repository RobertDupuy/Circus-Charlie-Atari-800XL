"""Execute the complete DAC stream with PAL/NTSC VBI interruptions."""
from cpu import Machine,ROOT
import numpy as np,json

p=np.fromfile(ROOT/'assets/audio/applause.bin',np.uint8)
expected=np.column_stack([p>>4,p&15]).ravel()|16
reports=[]
for pal,lines,clock in ((0,262,1789790),(1,312,1773447)):
 m=Machine();m.set('pal',pal);m.stage(0)
 m.set('mode',4);m.set('ready',0);m.set('loading',0);m.call('render_frame')
 m.m[0x6db]=1
 n=m.labels['nmi'];m.m[0xfffa]=n&255;m.m[0xfffb]=n>>8
 m.m[0xd40e]=0x40;m.c.at_video_timing(lines)
 path=ROOT/f'build/pcm-{pal}.trace';m.c.at_write_trace(str(path).encode(),0xd207)
 m.call('pcm_play');m.c.at_write_trace(None,0)
 writes=np.loadtxt(path,dtype=np.int64)
 assert np.array_equal(writes[:-1,1],expected) and writes[-1,1]==0
 duration=(writes[-2,0]-writes[0,0])/clock
 target=(len(expected)-1)*228/clock
 assert abs(duration-target)<.001,(pal,duration,target)
 reports.append(dict(standard='pal' if pal else 'ntsc',samples=len(expected),
                     exact_payload=True,duration_seconds=round(duration,6),
                     expected_seconds=round(target,6)))
(ROOT/'build/pcm-payload.json').write_text(json.dumps(reports,indent=2));print(reports)
