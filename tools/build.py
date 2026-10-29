#!/usr/bin/env python3
"""Build Type 63 Flash MegaCart 4 MiB with a native 16 KiB banking window."""
import os,shutil,subprocess,struct,json,re,argparse
from pathlib import Path
from pack_audio import pack
from lion_celebration import install as install_lion_celebration
from lion_blend_cache import install as install_lion_blend_cache
from trapeze_native_hero import build as build_trapeze_native_hero
from compiled_actors import build as build_compiled_actors
from compiled_balls import build as build_compiled_balls
from hidden_reward_art import build as build_hidden_reward_art
R=Path(__file__).resolve().parents[1]; B=R/'build';B.mkdir(exist_ok=True)
parser=argparse.ArgumentParser()
parser.add_argument('--chooser',choices=['arcade','automatic'],default='arcade',
                    help='Arcade selector, or fixed automatic progression without any selector')
args=parser.parse_args()
chooser=args.chooser=='arcade'
(B/'build-options.inc').write_text('ARCADE_CHOOSER='+str(int(chooser))+'\n')
(B/'build-profile.json').write_text(json.dumps({'selection':args.chooser,'main_acts_per_show':30},indent=2)+'\n')
fallback=Path(os.environ.get('CC65_BIN','/usr/bin'))
def tool(n):
 p=shutil.which(n) or str(fallback/n)
 if not Path(p).exists():raise SystemExit('Install cc65 (ca65 and ld65).')
 return p
def run(args):
 env=os.environ.copy()
 if not shutil.which('ca65'):env['CC65_HOME']=str(fallback.parent/'share/cc65')
 subprocess.run(args,check=True,cwd=R,env=env)
(B/'main.cfg').write_text('MEMORY { LIONRAM: start=$FE00,size=$0100,file="'+str(B/'liongfx.bin')+'",fill=yes,fillval=$00; CLIPRAM: start=$0E40,size=$00C0,file="'+str(B/'top-clip.bin')+'",fill=yes,fillval=$00; AUXRAM: start=$0400,size=$0200,file="'+str(B/'aux.bin')+'",fill=yes,fillval=$00; RAM: start=$1000,size=$2000,file=%O,fill=yes,fillval=$00; EXTRA: start=$B000,size=$0F00,file="'+str(B/'water.bin')+'",fill=yes,fillval=$FF; XLRAM: start=$C000,size=$1000,file="'+str(B/'xl.bin')+'",fill=yes,fillval=$00; MASK: start=$FC00,size=$0100,file="'+str(B/'alpha.bin')+'",fill=yes,fillval=$00; GFX: start=$F000,size=$0C00,file="'+str(B/'graphics.bin')+'",fill=yes,fillval=$00; MECH: start=$E000,size=$1000,file="'+str(B/'mechanics.bin')+'",fill=yes,fillval=$00; FIDELITYROM: start=$AD00,size=$1200,file="'+str(B/'fidelity.bin')+'",fill=yes,fillval=$FF; APPARATUSROM: start=$8000,size=$3F00,file="'+str(B/'apparatus.bin')+'",fill=yes,fillval=$FF; TITLERAM: start=$D840,size=$00C0,file="'+str(B/'title.bin')+'",fill=yes,fillval=$00; COMPLETEROM: start=$8000,size=$3000,file="'+str(B/'complete.bin')+'",fill=yes,fillval=$FF; CONTACTROM: start=$A000,size=$0400,file="'+str(B/'tramp-contact.bin')+'",fill=yes,fillval=$FF; TRAMPROM: start=$8000,size=$2000,file="'+str(B/'trampoline.bin')+'",fill=yes,fillval=$FF; DETAILROM: start=$8000,size=$0E00,file="'+str(B/'details.bin')+'",fill=yes,fillval=$FF; CHOOSERROM: start=$8000,size=$0800,file="'+str(B/'chooser.bin')+'",fill=yes,fillval=$FF; SYSTEMROM: start=$B400,size=$0B00,file="'+str(B/'system.bin')+'",fill=yes,fillval=$FF; }\nSEGMENTS { LIONGFX: load=LIONRAM,type=ro; TOPCLIP: load=CLIPRAM,type=ro; DETAILS: load=DETAILROM,type=ro; CHOOSER: load=CHOOSERROM,type=ro,optional=yes; AUX: load=AUXRAM,type=ro; CODE: load=RAM,type=ro; WATER: load=EXTRA,type=ro,optional=yes; TITLE: load=TITLERAM,type=ro; COMPLETE: load=COMPLETEROM,type=ro; TRAMPOLINE: load=TRAMPROM,type=ro; TRAMPCONTACT: load=CONTACTROM,type=ro; SYSTEM: load=SYSTEMROM,type=ro; FIDELITY: load=FIDELITYROM,type=ro; APPARATUS: load=APPARATUSROM,type=ro; XL: load=XLRAM,type=ro; MECHANICS: load=MECH,type=ro; GFX: load=GFX,type=ro; MASK: load=MASK,type=ro; }\n')
# The compiled hero uses banks 64..175; Dolphin contact uses bank 253.
p=B/'main.cfg'
s=p.read_text().replace('MEMORY {', 'MEMORY { FUSEDRAM: start=$FF00,size=$0100,file="'+str(B/'fused.bin')+'",fill=yes,fillval=$00; SILHOUETTEROM: start=$8000,size=$3F00,file="'+str(B/'contact.bin')+'",fill=yes,fillval=$FF;').replace('SEGMENTS {', 'SEGMENTS { FUSED: load=FUSEDRAM,type=ro; CONTACT: load=SILHOUETTEROM,type=ro,align=$100;')
p.write_text(s)
s=p.read_text().replace('MEMORY {', 'MEMORY { ACTORDISPATCHROM: start=$8000,size=$0400,file="'+str(B/'actor-dispatch.bin')+'",fill=yes,fillval=$FF; ACTORHELPROM: start=$B800,size=$0700,file="'+str(B/'actor-helper.bin')+'",fill=yes,fillval=$FF;').replace('SEGMENTS {', 'SEGMENTS { ACTORDISPATCH: load=ACTORDISPATCHROM,type=ro; ACTORHELP: load=ACTORHELPROM,type=ro;')
p.write_text(s)
(B/'boot.cfg').write_text('MEMORY { ROM: start=$BF00,size=$100,file=%O,fill=yes,fillval=$FF; }\nSEGMENTS { BOOT: load=ROM,type=ro; }\n')
s=p.read_text().replace('MEMORY {','MEMORY { BALLDRAWROM: start=$8000,size=$0800,file="'+str(B/'ball-draw.bin')+'",fill=yes,fillval=$FF;').replace('SEGMENTS {','SEGMENTS { BALLDRAW: load=BALLDRAWROM,type=ro;')
p.write_text(s)
s=p.read_text().replace('MEMORY {','MEMORY { HIDDENROM: start=$8000,size=$3800,file="'+str(B/'hidden-rewards.bin')+'",fill=yes,fillval=$FF;').replace('SEGMENTS {','SEGMENTS { HIDDEN: load=HIDDENROM,type=ro;')
p.write_text(s)
for asset in ['asset-banks.bin','common.bin']:
 shutil.copy(R/'assets'/asset,B/asset)
# Four phase bits per immutable ball glyph avoid scanning its eight rows on
# every podium overlap. Prepared assets themselves remain unchanged.
approved=(B/'asset-banks.bin').read_bytes()
opaque=[sum((1<<phase) for phase in range(4) if all((byte>>shift)&3 for byte in approved[31*16384+phase*1024+glyph*8:31*16384+phase*1024+glyph*8+8] for shift in (6,4,2,0))) for glyph in range(66)]
common=bytearray((B/'common.bin').read_bytes())
assert common[0xfc0:]==bytes(64)
common[0xfc0:]=bytes(opaque[2:])
(B/'common.bin').write_bytes(common)
rom=pack(bytearray((B/'asset-banks.bin').read_bytes()),chooser=chooser)
for name in ['main','boot']:
 run([tool('ca65'),'-g','-I',str(R/'src'),'-I',str(B),'-o',str(B/f'{name}.o'),str(R/f'src/{name}.s')])
 run([tool('ld65'),'-C',str(B/f'{name}.cfg'),'-m',str(B/f'{name}.map'),'-Ln',str(B/f'{name}.lbl'),'-o',str(B/f'{name}.bin'),str(B/f'{name}.o')])
assert len(rom)==524288
rom[17*16384:17*16384+0xE00]=(B/'details.bin').read_bytes()
rom[28*16384:28*16384+0x3000]=(B/'complete.bin').read_bytes()
water_bags=(R/'assets/water-bags.bin').read_bytes()
assert water_bags[0x600:]==bytes([255])*0x200, 'Water bag cache overlaps audio'
rom[28*16384+0x1000:28*16384+0x1800]=water_bags
rom[26*16384:26*16384+0x2000]=(B/'trampoline.bin').read_bytes()
rom[26*16384+0x2000:26*16384+0x2400]=(B/'tramp-contact.bin').read_bytes()
rom[26*16384+0x2340:26*16384+0x2400]=(B/'top-clip.bin').read_bytes()
rom[26*16384+0x2400:26*16384+0x3000]=(R/'assets/trampoline-hero-contacts.bin').read_bytes()
rom[26*16384+0x1e00:26*16384+0x2000]=(B/'aux.bin').read_bytes()
rom[29*16384:29*16384+0x3f00]=(B/'apparatus.bin').read_bytes()
rom[30*16384:30*16384+4096]=(B/'xl.bin').read_bytes()
rom[30*16384+0xf40:30*16384+0x1000]=(B/'title.bin').read_bytes()
rom[30*16384+4096:30*16384+8192]=(B/'mechanics.bin').read_bytes()
rom[30*16384+8192:30*16384+11264]=(B/'graphics.bin').read_bytes()
rom[30*16384+11264:30*16384+11520]=(B/'alpha.bin').read_bytes()
rom[30*16384+0x2d00:30*16384+0x3f00]=(B/'fidelity.bin').read_bytes()
rom[:8192]=(B/'main.bin').read_bytes();rom[8192:12288]=(B/'common.bin').read_bytes()
rom[0x3000:0x3F00]=(B/'water.bin').read_bytes()
demo=(R/'assets/demo-inputs.bin').read_bytes();rom[31*16384+4096:31*16384+4096+len(demo)]=demo
assert len(demo)<=0x1800,'Demonstration overlaps HUD templates'
rom[31*16384+0x3400:31*16384+0x3F00]=(B/'system.bin').read_bytes()
strings=dict(re.findall(r'^(\w+): .asciiz "([^"]*)"',(R/'src/tables.s').read_text(),re.M))
for a in range(7):
 h=bytearray(b' '*160)
 for off,key in [(0,'hud_label'),(40,'act'+str(a)),(80,'help'+str(a)),(120,'footer_controls')]:
  t=strings[key].encode();assert len(t)<=40;h[off:off+len(t)]=t
 off=31*16384+0x2800+a*160;rom[off:off+160]=h
# Reapply packets after padded program copies; reserved tails contain no code.
segments=(B/'main.map').read_text()
for name,limit in [('WATER',0x390),('DETAILS',0xE00),('COMPLETE',0xDA0),('TRAMPOLINE',0x1C00),('TRAMPCONTACT',0x340),('TOPCLIP',0xC0),('FUSED',0xFA),('CODE',0x2000),('SYSTEM',0x5C0),('APPARATUS',0x3770),('XL',0xf40),('FIDELITY',0x11f0)]:
 match=re.search(r'\b'+name+r'\s+Offs=[0-9A-F]+\s+Size=([0-9A-F]+)',segments)
 assert match and int(match[1],16)<=limit,(name,'audio tail overlap')
if chooser:
 data=(R/'assets/chooser.bin').read_bytes()
 match=re.search(r'\bCHOOSER\s+Offs=[0-9A-F]+\s+Size=([0-9A-F]+)',segments)
 assert match and int(match[1],16)<=0x500,'Chooser code overlaps sound packets'
 assert len(data)<=0x900,'Chooser art overlaps sound packets'
 rom[27*16384:27*16384+0x800]=(B/'chooser.bin').read_bytes()
 rom[27*16384+0x800:27*16384+0x800+len(data)]=data
rom=install_lion_blend_cache(install_lion_celebration(pack(rom,chooser=chooser)))
# Pre-rotate Balls' restoration map to the fixed goal-camera crowd phase.
# Normal scrolling blitters keep their independent original source.
for row in range(3,9):
 off=4*16384+3072+row*40
 original=approved[off:off+40]
 rom[off:off+40]=original[16:]+original[:16]
boot=(B/'boot.bin').read_bytes();assert len(boot)==256
for b in range(32):rom[b*16384+16128:(b+1)*16384]=boot
# Existing SIC control values $20..$3F become physical MegaCart banks 32..63.
# No runtime translation or extra cycles. Power-on bank 254 runs the reset stub.
logical=bytes(rom)
rom=bytearray([255])*(4*1024*1024)
rom[32*16384:64*16384]=logical
for bank,data in enumerate(build_trapeze_native_hero(),64):
 rom[bank*16384:(bank+1)*16384]=data
 rom[bank*16384+0x3f00:(bank+1)*16384]=boot
for bank,data in enumerate(build_compiled_actors(),176):
 assert bank<238, 'Actor compiler overlaps ball renderer'
 rom[bank*16384:(bank+1)*16384]=data
 rom[bank*16384+0x3f00:(bank+1)*16384]=boot
for bank,data in enumerate(build_compiled_balls(),238):
 rom[bank*16384:(bank+1)*16384]=data
 rom[bank*16384+0x3f00:(bank+1)*16384]=boot
directory,compiled_rewards,reward_banks,reward_programs=build_hidden_reward_art()
rom[242*16384:242*16384+0x3800]=(B/'hidden-rewards.bin').read_bytes()
assert int(re.search(r'\bHIDDEN\s+Offs=[0-9A-F]+\s+Size=([0-9A-F]+)',segments)[1],16)<=0x3000
rom[242*16384+0x3000:242*16384+0x3000+len(compiled_rewards)]=compiled_rewards
rom[242*16384+0x3800:242*16384+0x3800+len(directory)]=directory
rom[242*16384+0x3f00:243*16384]=boot
for bank,data in enumerate(reward_banks,243):
 assert bank<253,'Hidden rewards overlap visible-contact bank'
 rom[bank*16384:(bank+1)*16384]=data
 rom[bank*16384+0x3f00:(bank+1)*16384]=boot
for bank,data in enumerate(reward_programs):
 assert bank<32,'Reward programs overlap game banks'
 rom[bank*16384:(bank+1)*16384]=data
 rom[bank*16384+0x3f00:(bank+1)*16384]=boot
rom[253*16384:253*16384+0x3f00]=(B/'contact.bin').read_bytes()
rom[253*16384+0x3f00:254*16384]=boot
rom[254*16384+0x3f00:255*16384]=boot
(B/'game-banks.bin').write_bytes(logical)
(B/'Circus-Charlie-MegaCart4M.rom').write_bytes(rom)
(B/'Circus-Charlie-MegaCart4M.car').write_bytes(b'CART'+struct.pack('>III',63,sum(rom)&0xffffffff,0)+rom)
print((B/'main.map').read_text().split('Exports list')[0])
print('Built',B/'Circus-Charlie-MegaCart4M.car')
