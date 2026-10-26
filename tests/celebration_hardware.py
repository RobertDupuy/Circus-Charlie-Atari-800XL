"""Continuous native Act 1 victory, reached by the cartridge's normal demo.

No game state or executable bytes are patched. Read the live presentation
counters through the whole victory and inspect its captured POKEY audio.
Use --before to document the old freeze/silence rather than accept it.
"""
from emulator import Atari, R
from pathlib import Path
import argparse, hashlib, json, re, subprocess, time, wave
import numpy as np

p=argparse.ArgumentParser()
p.add_argument('standard',choices=['ntsc','pal'])
p.add_argument('--before',action='store_true')
args=p.parse_args()
cart=R/'build/celebration-retry/before.car' if args.before else R/'build/Circus-Charlie-SIC512.car'
name='celebration-'+('before-' if args.before else 'fixed-')+args.standard
a=Atari(args.standard,name,sound=True,cart=cart)
rows=[];recording=False

def sample():
    a.monitor(['m 0600 06ff','m d800 d83f'])
    mem={}
    for line in (a.out/(args.standard+'.log')).read_text().splitlines():
        hit=re.match(r'^([0-9A-F]{4}): ((?:[0-9A-F]{2} ){15}[0-9A-F]{2})',line)
        if hit:
            for i,v in enumerate(bytes.fromhex(hit[2])):mem[int(hit[1],16)+i]=v
    word=lambda address:mem[address]+256*mem[address+1]
    return dict(mode=mem[0x600],act=mem[0x601],host=word(0x604),presented=word(0x606),
                elapsed=mem[0x6e4],pcm_active=mem[0x6dc],pcm_pending=mem[0x6db],
                interval=mem[0x68c],fault=mem[0x61d],missed=word(0x608),
                music_active=bool(mem[0xd804]),
                music_audible=any(mem[i]&15 for i in (0xd811,0xd813,0xd815,0xd817)))

try:
    a.tap('F2')
    until=time.monotonic()+95
    while time.monotonic()<until:
        row=sample()
        if row['mode']==4 and row['act']==0:
            if not recording:
                a.record();recording=True
            rows.append(row)
            if len(rows) in (1,4,8,12):a.shot('victory-%02d.png'%len(rows))
        elif recording:
            break
        time.sleep(.10)
    assert recording and len(rows)>=6,rows
    a.record();recording=False
finally:a.close()

stalls=[]
for old,new in zip(rows,rows[1:]):
    host=(new['host']-old['host'])&65535
    frames=(new['presented']-old['presented'])&65535
    if host>=4 and (new['elapsed']==old['elapsed'] or frames<host//2-2):
        stalls.append(dict(host_frames=host,presented_frames=frames,elapsed=new['elapsed']))

wav=a.out/'victory.wav'
subprocess.run(['ffmpeg','-v','error','-y','-i',str(a.out/'capture.avi'),'-vn','-ac','1',
                '-acodec','pcm_s16le',str(wav)],check=True)
with wave.open(str(wav)) as w:
    rate=w.getframerate();sound=np.frombuffer(w.readframes(w.getnframes()),'<i2').astype(float)/32768
width=round(rate*.05)
blocks=[float(np.std(sound[i:i+width])) for i in range(0,len(sound)-width+1,width)]
quiet=longest=0
for rms in blocks:
    quiet=quiet+1 if rms<.0005 else 0;longest=max(longest,quiet)
report=dict(standard=args.standard,car_sha256=hashlib.sha256(cart.read_bytes()).hexdigest(),
            unmodified_cartridge=True,natural_demo_win=True,samples=rows,stalls=stalls,
            pcm_seen=any(r['pcm_active'] or r['pcm_pending'] for r in rows),
            audio_seconds=round(len(sound)/rate,3),audio_rms=round(float(np.std(sound)),5),
            longest_silent_seconds=round(longest*.05,3))
(a.out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
print({k:v for k,v in report.items() if k!='samples'},flush=True)
if args.before:
    assert report['pcm_seen'] and stalls,'Old freeze was not reproduced'
else:
    assert not report['pcm_seen'] and not stalls,report
    # The first two buffers install the victory text; each may take four TV
    # frames. Later sampling windows must advance at the normal two-frame
    # presentation rate (the stalls check above), with no stopped animation.
    assert all(r['interval']<=4 and not r['fault'] and not r['missed'] and r['music_active'] for r in rows)
    assert report['audio_seconds']>1.5 and report['audio_rms']>.005
    assert report['longest_silent_seconds']<.25,report
