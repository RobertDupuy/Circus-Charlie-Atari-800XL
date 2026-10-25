"""Tightrope deaths, continue, joystick recovery and footer raster in Atari800.

The only setup edit selects Act 2 via the game's native demo entry and turns
demo input off during its introduction. The release code is unchanged;
subsequent collisions/retries use ordinary controls and read-only observations.
"""
from emulator import Atari, R
import argparse
import hashlib
import json
import re
import subprocess
import time
import numpy as np

parser = argparse.ArgumentParser()
parser.add_argument('standard', choices=['ntsc', 'pal'])
parser.add_argument('--name')
args = parser.parse_args()
capture_started = time.time()
a = Atari(args.standard, args.name or 'tightrope-retry-' + args.standard, sound=True)
samples = []
continues = 0


def sample():
    a.monitor(['m 0600 06cf', 'm 0970 099f', 'm dc00 dc0f'])
    mem = {}
    for line in (a.out / (args.standard + '.log')).read_text().splitlines():
        match = re.match(r'^([0-9A-F]{4}): ((?:[0-9A-F]{2} ){15}[0-9A-F]{2})', line)
        if match:
            for i, value in enumerate(bytes.fromhex(match[2])):
                mem[int(match[1], 16) + i] = value
    word = lambda p: mem[p] + 256 * mem[p + 1]
    row = dict(mode=mem[0x600], act=mem[0x601], lives=mem[0x603], host=word(0x604),
               presented=word(0x606), missed=word(0x608), interval=mem[0x68c],
               fault=mem[0x61d], world=word(0x620), end=word(0x648),
               restores=mem[0xdc07], scroll=word(0x978), pal=mem[0x610],
               loading=mem[0x61a], demo=mem[0x6ab])
    samples.append(row)
    return row


try:
    a.monitor(['c 0638 01', 'c 0618 01'])
    time.sleep(.25)
    a.monitor(['c 06ab 00'])
    a.record()
    started = time.monotonic()
    escape_host = None
    previous = None
    while time.monotonic() - started < 65:
        if escape_host is not None:
            a.key('Right', False)
            a.key('Right', True)
        time.sleep(.4)
        row = sample()
        phase = (row['mode'], row['lives'], row['restores'])
        if phase != previous:
            a.shot('state-%02d.png' % len(samples))
            print(row, flush=True)
            previous = phase
        if row['mode'] == 6:
            a.tap('Control_R')
            continues += 1
        if row['restores'] >= 4 and row['mode'] == 2:
            if escape_host is None:
                escape_host = row['host']
            if ((row['host'] - escape_host) & 65535) >= 45 and row['world'] > 72:
                a.shot('after-retry.png')
                break
    a.key('Right', False)
    a.record()
finally:
    a.close()

assert (a.out / 'capture.avi').stat().st_mtime >= capture_started, 'Stale video capture'

video = a.out / 'capture.avi'
stream = json.loads(subprocess.check_output([
    'ffprobe', '-v', 'error', '-select_streams', 'v:0', '-show_entries',
    'stream=width,height', '-of', 'json', str(video)]))['streams'][0]
w, h = stream['width'], stream['height']
raw = subprocess.check_output(['ffmpeg', '-v', 'error', '-i', str(video),
                               '-f', 'rawvideo', '-pix_fmt', 'rgb24', '-'])
frames = np.frombuffer(raw, np.uint8).reshape(-1, h, w, 3)
offset = (h - 224) // 2
# Static lower crowd margin, green apron and the footer boundary.
# Actors and scrolling crowd details are above this rectangle. Loading is
# deliberately blank; require a visible HUD and a mostly green apron.
# Do not discard an otherwise complete frame because a player latch has
# leaked pink pixels into this strip; that is a display failure to detect.
apron = frames[:, 192 + offset, 8:328].astype(int)
green = ((apron[:, :, 1] > apron[:, :, 0] + 30) &
         (apron[:, :, 1] > apron[:, :, 2] + 25)).sum(axis=1) > 160
hud = frames[:, 6 + offset:22 + offset, 8:328].max(axis=(1, 2, 3)) > 100
visible = frames[green & hud]
strip = visible[:, 180 + offset:200 + offset, 8:328]
# Footer words legitimately change between ready, play, death and continue.
# Their first scanline must contain only the monochrome footer palette.
footer = visible[:, 200 + offset:202 + offset, 8:328]
footer_bad = np.any((footer[:, :, :, 0] != footer[:, :, :, 1]) |
                    (footer[:, :, :, 1] != footer[:, :, :, 2]), axis=(1, 2))
assert len(strip) > 500, 'Insufficient complete tightrope frames'
varying = np.any(strip != strip[0], axis=(0, 2, 3))
report = dict(standard=args.standard,
              car_sha256=hashlib.sha256((R / 'build/Circus-Charlie-SIC512.car').read_bytes()).hexdigest(),
              setup_fixture='Act 2 selection only; demo input disabled before play',
              continues=continues, samples=samples, captured_frames=len(frames),
              checked_frames=len(strip), checked_native_rows=[180 + offset, 199 + offset],
              footer_boundary_rows=[200 + offset, 201 + offset],
              footer_palette_fault_frames=int(footer_bad.sum()),
              varying_native_rows=(np.flatnonzero(varying) + 180 + offset).tolist())
(a.out / 'result.json').write_text(json.dumps(report, indent=2))
print(json.dumps({k: v for k, v in report.items() if k != 'samples'}, indent=2))
assert all(r['act'] == 1 and not r['demo'] for r in samples)
assert all(r['pal'] == int(args.standard == 'pal') for r in samples)
assert all(48 <= r['world'] < r['end'] for r in samples if not r['loading'])
assert max(r['restores'] for r in samples) >= 4 and continues >= 1
assert samples[-1]['mode'] == 2 and samples[-1]['world'] > 72, 'Joystick cannot escape retry'
assert all(not r['missed'] and not r['fault'] and r['interval'] <= 2
           for r in samples if r['mode'] == 2), 'Gameplay deadline or renderer failure'
assert not varying.any(), 'Tightrope bottom scanlines flash or contain player streaks'
assert not footer_bad.any(), 'Tightrope footer boundary contains a stray colour'
