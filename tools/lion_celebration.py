"""Reuse the existing raised-foot Charlie and planted lion, without new art.

Keep every approved asset file intact. Only the two Act 1 celebration directory
entries and their new payloads change in the built cartridge. Bank 27's former
audio padding at $8500..$87FF is reserved for these two composites.
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BANK = 27
START, END = 0x500, 0x800

def picture(rom, pose):
    bank, lo, hi, count = rom[7*16384+pose*128:7*16384+pose*128+4]
    offset = bank*16384 + lo + (hi-128)*256
    dense = pose in (0, 5)
    width, height, shift = (24, 56, 3) if dense else (16, 48, 7)
    image = [[0]*width for _ in range(height)]
    cells = []
    if dense:
        header, cols, rows = rom[offset:offset+3]
        for y in range(rows):
            for x in range(cols):
                code = rom[offset+3+y*cols+x]
                if code & 63:
                    p = offset+header+((code & 63)-1)*8
                    cells.append((x, y, code, rom[p:p+8]))
    else:
        for i in range(count):
            p = offset+i*10
            code, y = rom[p:p+2]
            cells.append((code & 31, y, code, rom[p+2:p+10]))
    for x, y, code, glyph in cells:
        for dy, row in enumerate(glyph):
            for dx, bit in enumerate((6, 4, 2, 0)):
                colour = (row >> bit) & 3
                image[y*8+dy][x*4+dx] = 4 if colour == 3 and code & 128 else colour
    return image[shift:shift+(48 if dense else 38)]

def composite(rom, phase):
    lion = picture(rom, 0)[28:48]
    charlie = picture(rom, 100+phase)
    # Charlie's planted shoe is at Y=134; the unchanged lion begins at Y=135.
    image = [[0]*24 for _ in range(64)]
    for y, row in enumerate(charlie): image[y+1][4:20] = row
    for y, row in enumerate(lion): image[y+39] = row[:]
    header = bytearray([51, 6, 8]+[0]*48)
    pixels = bytearray()
    for y in range(8):
        for x in range(6):
            tile = [row[x*4:x*4+4] for row in image[y*8:y*8+8]]
            values = sum(tile, [])
            if not any(values): continue
            alt = 128 if values.count(4) > values.count(3) else 0
            code = len(pixels)//8+1
            header[3+y*6+x] = code | alt | (64 if all(values) else 0)
            for row in tile:
                mapped = [2 if c == (3 if alt else 4) else 3 if c == 4 else c for c in row]
                pixels.append(sum(c << bit for c, bit in zip(mapped, (6, 4, 2, 0))))
    return header+pixels, len(pixels)//8

def install(rom):
    approved = (ROOT/'assets/asset-banks.bin').read_bytes()
    for pose, expected in ((0,(8,0,128,30)),(5,(9,93,167,35))):
        assert tuple(approved[7*16384+pose*128:7*16384+pose*128+4]) == expected
        assert approved[6*16384+0x2e00+pose*12+6:6*16384+0x2e00+pose*12+9] == bytes((1,1,1))
        assert not any(approved[6*16384+0x3000+pose*144:6*16384+0x3000+(pose+1)*144])
    for pose in range(119):
        if pose in (0,5): continue
        for shift in range(32):
            bank, lo, hi, count = approved[7*16384+pose*128+shift*4:7*16384+pose*128+shift*4+4]
            address = lo+(hi-128)*256
            assert not count or not ((bank == 8 and 0 <= address < 285) or (bank == 9 and 0x275d <= address < 0x28a2))
    # Decode both from the approved input before replacing either directory.
    poses = [composite(approved, phase) for phase in (0, 1)]
    position = START
    report = []
    for pose, (data, cells) in zip((0, 5), poses):
        assert position+len(data) <= END, 'Celebration overlaps chooser artwork'
        rom[BANK*16384+position:BANK*16384+position+len(data)] = data
        address = 0x8000+position
        entry = bytes((BANK, address & 255, address >> 8, cells))
        rom[7*16384+pose*128:7*16384+(pose+1)*128] = entry*32
        report.append(dict(pose=pose,source_charlie_pose=100+len(report),bytes=len(data),cells=cells,bank=BANK,address=address))
        position += len(data)
    assert position == 0x79e, 'Update the explicit audio reservation if art storage changes'
    (ROOT/'build/lion-celebration-art.json').write_text(json.dumps(dict(poses=report,approved_asset_files_unchanged=True,lion_pixels_unchanged=True,foot_y=134,lion_y=135),indent=2)+'\n')
    return rom
