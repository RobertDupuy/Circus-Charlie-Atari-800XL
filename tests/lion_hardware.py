"""Act 1 death/retry/continue and background stability in Atari800.

The release cartridge is unmodified. Only ordinary keyboard controls are sent;
the monitor reads counters. FFmpeg decodes the lossless emulator recording so
every TV frame, including the previously flashing scanlines, is checked.
"""
from emulator import Atari, R
from pathlib import Path
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
parser.add_argument('--cart', type=Path)
args = parser.parse_args()
cart = args.cart or R / 'build/Circus-Charlie-SIC512.car'
capture_started = time.time()
a = Atari(args.standard, args.name or 'lion-retry-' + args.standard,
          sound=True, cart=cart)
samples = []
continues = 0


def sample():
    a.monitor(['m 0600 06cf', 'm d900 d93f', 'm dc00 dc0f'])
    mem = {}
    for line in (a.out / (args.standard + '.log')).read_text().splitlines():
        match = re.match(r'^([0-9A-F]{4}): ((?:[0-9A-F]{2} ){15}[0-9A-F]{2})', line)
        if match:
            for i, value in enumerate(bytes.fromhex(match[2])):
                mem[int(match[1], 16) + i] = value
    word = lambda p: mem[p] + 256 * mem[p + 1]
    row = dict(mode=mem[0x600], lives=mem[0x603], host=word(0x604),
               presented=word(0x606), missed=word(0x608), fault=mem[0x61d],
               interval=mem[0x68c], world=word(0x620), potcount=mem[0xd938],
               restores=mem[0xdc07], player=mem[0x6b5], pal=mem[0x610],
               loading=mem[0x61a])
    samples.append(row)
    return row


try:
    a.record()
    a.tap('F4')
    started = time.monotonic()
    final_host = None
    previous = None
    while time.monotonic() - started < 70:
        # Entering the monitor releases SDL's held keys. Reapply the stick
        # after every read, so this is a walking collision, not a demo route.
        a.key('Right', False)
        a.key('Right', True)
        time.sleep(.45)
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
            if final_host is None:
                final_host = row['host']
            if ((row['host'] - final_host) & 65535) >= 60:
                a.shot('after-retry.png')
                break
    a.key('Right', False)
    a.record()
finally:
    a.close()

assert (a.out / 'capture.avi').stat().st_mtime >= capture_started, 'Stale video capture'

# Compare the background across the whole field, ignoring the moving actors'
# non-green pixels. Checking two fixed columns alone confuses passing hoops
# with raster faults. Stage loading deliberately blanks the display.
probe = subprocess.check_output(['ffprobe', '-v', 'error', '-select_streams', 'v:0',
                                '-show_entries', 'stream=width,height', '-of', 'json',
                                str(a.out / 'capture.avi')])
stream = json.loads(probe)['streams'][0]
w, h = stream['width'], stream['height']
raw = subprocess.check_output(['ffmpeg', '-v', 'error', '-i', str(a.out / 'capture.avi'),
                               '-f', 'rawvideo', '-pix_fmt', 'rgb24', '-'])
frames = np.frombuffer(raw, np.uint8).reshape(-1, h, w, 3)
# Locate the ground independently of the emulator's PAL/NTSC crop. Require
# the full field and visible HUD, so a partly blanked load frame is excluded.
profiles = []
banner = []
tops = []
mixed_rows = set()
for frame in frames:
    pixels = frame[:, 8:328].astype(int)
    green = ((pixels[:, :, 1] > pixels[:, :, 0] + 30) &
             (pixels[:, :, 1] > pixels[:, :, 2] + 25) & (pixels[:, :, 1] > 50))
    wide = green.sum(axis=1) > 160
    starts = [y for y in range(85, 120) if wide[y:y + 15].all() and not wide[y - 1]]
    if len(starts) != 1:
        continue  # Title and intentionally blank stage-loading frames.
    top = starts[0]
    if not wide[top:top + 88].all() or frame[6:22, 8:328].max() < 100:
        continue
    field = frame[top:top + 88, 8:328]
    mask = green[top:top + 88]
    profile = np.array([row[visible][0] for row, visible in zip(field, mask)])
    mixed = ((field != profile[:, None, :]).any(axis=2) & mask).any(axis=1)
    mixed_rows.update(np.flatnonzero(mixed).tolist())
    profiles.append(profile)
    # The thin horizontal highlight is static; adjacent scenery pixels
    # legitimately change as the camera scrolls and hoops cross the edge.
    banner.append(frame[top - 3:top - 2, 10:18].copy())
    tops.append(top)
assert profiles, 'No Act 1 frames captured'
profiles = np.array(profiles)
varying = np.any(profiles != profiles[0], axis=(0, 2))
banner_varying = np.any(np.array(banner) != banner[0], axis=(0, 2, 3))
palette = np.unique(profiles.reshape(-1, 3), axis=0)
report = dict(standard=args.standard, car_sha256=hashlib.sha256(cart.read_bytes()).hexdigest(),
              natural_input=True, continues=continues, samples=samples,
              captured_frames=len(frames), field_frames=len(profiles),
              varying_background_rows=np.flatnonzero(varying).tolist(),
              mixed_background_rows=sorted(mixed_rows), ground_top_rows=sorted(set(tops)),
              varying_banner_rows=np.flatnonzero(banner_varying).tolist(),
              green_shades=palette.tolist())
(a.out / 'result.json').write_text(json.dumps(report, indent=2))
print(json.dumps({k: v for k, v in report.items() if k != 'samples'}, indent=2))
assert max(r['restores'] for r in samples) >= 4 and continues >= 1, 'Retry/continue route incomplete'
assert max(r['world'] for r in samples) > 160, 'Joystick did not move Charlie'
assert all(r['pal'] == int(args.standard == 'pal') for r in samples), 'Wrong TV mode'
assert all(r['potcount'] == 5 and not r['fault'] for r in samples if r['mode'] == 2), 'Lost or corrupted lion state'
assert all(not r['missed'] for r in samples if r['mode'] == 2), 'Missed gameplay deadlines'
assert all(r['interval'] <= 2 for r in samples if r['mode'] == 2), 'Slow presentation after retry'
assert not varying.any(), 'Background scanlines change between TV frames'
assert not mixed_rows and len(set(tops)) == 1, 'Background boundary shifts across/along a line'
assert not banner_varying.any(), 'Banner palette flickers at its character boundary'
assert len(palette) == 3, 'Expected the three green field shades'
