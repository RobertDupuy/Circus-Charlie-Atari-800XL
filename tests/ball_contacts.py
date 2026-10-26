"""Ball contact must agree with the two visible silhouettes, including retries.

Boundary fixtures vary Charlie's offset from his support. Pixel fixtures cover
clipping, palette phases, touching/overlapping rims and front-buffer retention.
"""
from cpu import Machine, ROOT
import json, sys
import numpy as np

sys.path.insert(0, str(ROOT/'tools'))
import assets, bold_art

ims, names, *_ = assets.poses()
ims, names = bold_art.actors(ims, names)
ball = ims[14] != 0
assert np.where(ball)[1].min() == 3 and np.where(ball)[1].max() == 16

def centres(m):
    return [m.m[m.labels['ball_lo']+i]+256*m.m[m.labels['ball_hi']+i] for i in range(5)]

def tick(m, joy=0, fire=0):
    m.wordset('host_frames', (m.word('host_frames')+1)&65535)
    m.set('input', joy);m.set('fire_latch', fire);m.call('game_tick')

boundaries = 0
for centre in (60, 250, 255, 260, 512, 1000):
    for offset in (-6, 0, 6):
        for separation in range(-25, 26):
            m = Machine();m.stage(3)
            m.wordset('world', centre-offset)
            m.wordset('f_scroll', 0x800)
            for i, position in enumerate((centre, centre+separation)):
                m.m[m.labels['ball_lo']+i] = position&255
                m.m[m.labels['ball_hi']+i] = position>>8
                m.m[m.labels['f_active']+i] = 1
                m.m[m.labels['f_object_fraction']+i] = 255
            tick(m)
            a, b, *_ = centres(m)
            assert (m.get('mode') == 3) == (abs(a-b) <= 14), (centre, offset, separation, a, b)
            boundaries += 1

# Hold right without jumping: actual collision, death, retry and game over.
losses = []
for rank in range(6):
    m = Machine();m.stage(3, rank)
    for attempt in range(3):
        for t in range(2000):
            tick(m, 8)
            if m.get('mode') == 3:
                c = centres(m);support = m.get('current_ball')
                distance = min(abs(c[support]-c[i]) for i in range(5)
                               if i != support and m.m[m.labels['f_active']+i])
                assert distance <= 14, (rank, attempt, c, support)
                losses.append(dict(rank=rank, attempt=attempt, ticks=t+1, centre_distance=distance))
                break
        else:
            raise AssertionError('No natural ball contact')
        while m.get('mode') == 3:
            tick(m);m.set('back', m.get('back')^1);m.call('render_frame')
            assert not m.get('fault')
        if attempt < 2:
            m.call('load_stage')
            while m.get('mode') == 1:tick(m)
    assert m.get('mode') == 6

def strip(m, back, font):
    out = np.zeros((30,160), np.uint8)
    for py in range(30):
        row, scan = divmod(py+136, 8)
        for col in range(40):
            code = m.m[0x3800+1024*back+row*40+col]
            bits = m.m[font+(code&127)*8+scan]
            out[py,col*4:col*4+4] = [(bits>>s)&3 for s in (6,4,2,0)]
    return out != 0

def draw(m, back, phase, positions):
    m.set('back', back);m.set('anim_clock', phase*4)
    m.m[m.labels['z_map']+1] = 0x38+4*back
    m.call('prepare_balls')
    for x in positions:
        m.wordset('sprite_x', x&65535);m.call('draw_ball')
    assert not m.get('fault')
    return m.m[m.labels['band_font']+2]*256

pixels = 0
for phase in range(4):
    for x in (-17,-7,-3,0,1,2,3,64,65,66,67,145,155,159):
        for distance in (0,7,13,14,15,20,28):
            m = Machine();m.stage(3)
            expected = np.zeros((30,160), bool)
            for px in (x, x+distance):
                left=max(0,px);right=min(160,px+20)
                if left<right:expected[:,left:right] |= ball[:,left-px:right-px]
            for back in range(2):
                font = draw(m,back,phase,(x,x+distance))
                actual = strip(m,back,font)
                assert np.array_equal(actual,expected), ('ball silhouette',phase,x,distance,back)
                # Same phase font, different back screen: only its own private
                # merged glyph range may change while the front is displayed.
                draw(m,back^1,phase,(90,104))
                assert np.array_equal(strip(m,back,font),actual), ('front font changed',phase,x,distance,back)
                pixels += 1

report = dict(boundary_cases=boundaries, natural_losses=losses,
              pixel_reference_cases=pixels, visible_diameter=14, front_buffer_stable=True)
(ROOT/'build/ball-contacts.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))
