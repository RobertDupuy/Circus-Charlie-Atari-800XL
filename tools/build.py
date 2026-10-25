#!/usr/bin/env python3
"""Build the 512 KiB SIC! ROM and MAME/Atari800 CAR container using cc65."""
import os,shutil,subprocess,struct,json,re
from pathlib import Path
from pack_audio import pack
R=Path(__file__).resolve().parents[1]; B=R/'build';B.mkdir(exist_ok=True)
fallback=Path(os.environ.get('CC65_BIN','/usr/bin'))
def tool(n):
 p=shutil.which(n) or str(fallback/n)
 if not Path(p).exists():raise SystemExit('Install cc65 (ca65 and ld65).')
 return p
def run(args):
 env=os.environ.copy()
 if not shutil.which('ca65'):env['CC65_HOME']=str(fallback.parent/'share/cc65')
 subprocess.run(args,check=True,cwd=R,env=env)
(B/'main.cfg').write_text('MEMORY { AUXRAM: start=$0400,size=$0200,file="'+str(B/'aux.bin')+'",fill=yes,fillval=$00; RAM: start=$1000,size=$2000,file=%O,fill=yes,fillval=$00; EXTRA: start=$B000,size=$0F00,file="'+str(B/'water.bin')+'",fill=yes,fillval=$FF; XLRAM: start=$C000,size=$1000,file="'+str(B/'xl.bin')+'",fill=yes,fillval=$00; MASK: start=$FC00,size=$0100,file="'+str(B/'alpha.bin')+'",fill=yes,fillval=$00; GFX: start=$F000,size=$0C00,file="'+str(B/'graphics.bin')+'",fill=yes,fillval=$00; MECH: start=$E000,size=$1000,file="'+str(B/'mechanics.bin')+'",fill=yes,fillval=$00; FIDELITYROM: start=$AD00,size=$1200,file="'+str(B/'fidelity.bin')+'",fill=yes,fillval=$FF; APPARATUSROM: start=$8000,size=$3F00,file="'+str(B/'apparatus.bin')+'",fill=yes,fillval=$FF; TITLERAM: start=$D840,size=$00C0,file="'+str(B/'title.bin')+'",fill=yes,fillval=$00; COMPLETEROM: start=$8000,size=$3000,file="'+str(B/'complete.bin')+'",fill=yes,fillval=$FF; TRAMPROM: start=$8000,size=$2000,file="'+str(B/'trampoline.bin')+'",fill=yes,fillval=$FF; SYSTEMROM: start=$B400,size=$0B00,file="'+str(B/'system.bin')+'",fill=yes,fillval=$FF; }\nSEGMENTS { AUX: load=AUXRAM,type=ro; CODE: load=RAM,type=ro; WATER: load=EXTRA,type=ro,optional=yes; TITLE: load=TITLERAM,type=ro; COMPLETE: load=COMPLETEROM,type=ro; TRAMPOLINE: load=TRAMPROM,type=ro; SYSTEM: load=SYSTEMROM,type=ro; FIDELITY: load=FIDELITYROM,type=ro; APPARATUS: load=APPARATUSROM,type=ro; XL: load=XLRAM,type=ro; MECHANICS: load=MECH,type=ro; GFX: load=GFX,type=ro; MASK: load=MASK,type=ro; }\n')
(B/'boot.cfg').write_text('MEMORY { ROM: start=$BF00,size=$100,file=%O,fill=yes,fillval=$FF; }\nSEGMENTS { BOOT: load=ROM,type=ro; }\n')
for asset in ['asset-banks.bin','common.bin']:
 shutil.copy(R/'assets'/asset,B/asset)
rom=pack(bytearray((B/'asset-banks.bin').read_bytes()))
for name in ['main','boot']:
 run([tool('ca65'),'-g','-I',str(R/'src'),'-I',str(B),'-o',str(B/f'{name}.o'),str(R/f'src/{name}.s')])
 run([tool('ld65'),'-C',str(B/f'{name}.cfg'),'-m',str(B/f'{name}.map'),'-Ln',str(B/f'{name}.lbl'),'-o',str(B/f'{name}.bin'),str(B/f'{name}.o')])
assert len(rom)==524288
rom[28*16384:28*16384+0x3000]=(B/'complete.bin').read_bytes()
rom[28*16384+0x1000:28*16384+0x1800]=(R/'assets/water-bags.bin').read_bytes()
rom[26*16384:26*16384+0x2000]=(B/'trampoline.bin').read_bytes()
rom[26*16384+0x1e00:26*16384+0x2000]=(B/'aux.bin').read_bytes()
rom[26*16384+0x2000:26*16384+0x3000]=(R/'assets/act3-bags.bin').read_bytes()
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
for name,limit in [('COMPLETE',0x1000),('TRAMPOLINE',0x1e00),('CODE',0x2000),('SYSTEM',0x600),('APPARATUS',0x3900),('XL',0xf00)]:
 match=re.search(r'\b'+name+r'\s+Offs=[0-9A-F]+\s+Size=([0-9A-F]+)',segments)
 assert match and int(match[1],16)<=limit,(name,'audio tail overlap')
rom=pack(rom)
boot=(B/'boot.bin').read_bytes();assert len(boot)==256
for b in range(32):rom[b*16384+16128:(b+1)*16384]=boot
(B/'Circus-Charlie-SIC512.rom').write_bytes(rom)
(B/'Circus-Charlie-SIC512.car').write_bytes(b'CART'+struct.pack('>III',56,sum(rom)&0xffffffff,0)+rom)
print((B/'main.map').read_text().split('Exports list')[0])
print('Built',B/'Circus-Charlie-SIC512.car')
