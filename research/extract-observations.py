"""Summarize measured original-game RAM; no manual/game-guide inputs.
Run research/run-arcade.sh runjump, neutral, play and sweep first.
The sweep scenario deliberately freezes clearance: not unmodified gameplay.
"""
from pathlib import Path
import csv,json
from collections import Counter
R=Path(__file__).resolve().parents[1]
O=R/'evidence';O.mkdir(exist_ok=True)
def frames(name):
 p=R/'build/arcade-act1'/name
 rows=list(csv.DictReader((p/'events.csv').open()));data=(p/'frames.bin').read_bytes()
 assert len(data)==len(rows)*8192,(name,len(rows),len(data))
 for i,event in enumerate(rows):
  b=data[i*8192:(i+1)*8192]
  yield int(event['frame']),b

def world(b):return b[0x203]*256-b[0x204]-b[0x205]/256
observed=[];takeoff=None
for frame,b in frames('runjump'):
 if frame>=820 and takeoff is None and b[0xb0]:takeoff=frame
 if takeoff is not None and frame-takeoff<=63:
  velocity=b[0xb5]*256+b[0xb6]
  if velocity>=32768:velocity-=65536
  observed.append([frame-takeoff,frame,216-b[0xb7],velocity,world(b)])
with (O/'arcade-act1-jump.csv').open('w') as f:
 w=csv.writer(f);w.writerow(['relative_frame','mame_frame','height_pixels','vertical_velocity_8_8','world_pixels']);w.writerows(observed)
assert len(observed)==64 and max(row[2] for row in observed)==55
# Preserve every active object sample in the uninterrupted instrumented run.
rows=[];releases=[];old=[0]*4;pots=Counter()
for frame,b in frames('sweep'):
 if frame<800 or b[0x800]!=1:continue
 progress=world(b)
 for slot,address in enumerate((0x26d0,0x2700,0x2730,0x2760)):
  a=address-0x2000;active=b[a]!=0;x=b[a+6]+b[a+7]/256
  if active:rows.append([frame,round(progress,4),'money' if slot==3 else 'normal',slot,round(x,4),b[a+4]])
  if active and not old[slot]:releases.append([frame,slot,'money' if slot==3 else 'normal',round(progress,4),round(x,4)])
  old[slot]=active
 for address in (0x24b0,0x24f0,0x2530):
  a=address-0x2000;x=b[a+6]+b[a+7]/256
  if b[a]==2 and 0<x<220 and progress<1752:pots[round((x+progress-64)*2)/2]+=1
with (O/'arcade-act1-object-frames.csv').open('w') as f:
 w=csv.writer(f);w.writerow(['mame_frame','world_pixels','type','slot','screen_x','screen_y']);w.writerows(rows)
with (O/'arcade-act1-releases.csv').open('w') as f:
 w=csv.writer(f);w.writerow(['mame_frame','slot','type','world_pixels','screen_x']);w.writerows(releases)
transitions=[];old=None
for frame,b in frames('play'):
 state=(b[0x800],b[0x220])
 if state!=old and frame>=780:transitions.append({'frame':frame,'act1_state_2800':state[0],'raw_2220':state[1]});old=state
report={'method':'Direct KONAMI-1 disassembly plus per-frame MAME RAM observations',
 'original_rom_sha256':'a3356f8a621b7b234b8a8342bcfce03a89e64775259621f25c05ddd0f67280c0',
 'mame_version':'0.251','mame_frame_hz':60,'physical_arcade_hz':6144000/(384*264),
 'jump_samples':len(observed),'jump_apex_display_pixels':55,
 'sweep_warning':'Clearance RAM frozen each frame to isolate uninterrupted waves; not ordinary gameplay',
 'ordinary_input_play_warning':'Reactive joystick/fire player cleared Act 1 after one death',
 'sweep_pot_distances_from_initial_hero':sorted(p for p,n in pots.items() if n>=4 and 0<p<1752),
 'pot_filter':'Subtract initial hero screen X=64; require at least four stable observations to exclude end-camera clamp transients',
 'ordinary_play_state_transitions':transitions}
(O/'arcade-act1-observations.json').write_text(json.dumps(report,indent=2))
print(report)
