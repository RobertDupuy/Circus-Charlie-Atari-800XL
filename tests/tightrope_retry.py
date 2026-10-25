"""Playable retries at both ends of the rope, on both checkpoint pages.

Every death is caused by normal input and active collisions. Early deaths
exercise the shared tightrope/ball checkpoint arithmetic; late deaths omit
the final jump. Successful routes then prove recovery through the real finish.
"""
from cpu import Machine, ROOT
import json


def tick(m, joy=0, fire=0):
    m.set('input', joy)
    m.set('fire_latch', fire)
    m.call('game_tick')
    if not (m.word('anim_clock') & 1):
        m.set('back', m.get('back') ^ 1)
        m.call('render_frame')
    assert not m.get('fault')


def begin(m):
    while m.get('mode') == 1:
        tick(m)
    assert m.get('mode') == 2


def retry(m):
    assert m.get('mode') == 3
    dead_at = m.word('world')
    while m.get('mode') == 3:
        tick(m)
    continued = m.get('mode') == 6
    if continued:
        tick(m, fire=1)
        assert m.get('lives') == 3
    assert m.get('mode') == 1 and m.get('need_stage')
    m.call('load_stage')
    origin = 48 if m.get('act') == 1 else 60
    position = m.word('world')
    assert origin <= position < m.word('stage_end'), ('outside course', dead_at, position)
    assert 0 <= dead_at - position < 280, ('retry must not jump ahead', dead_at, position)
    begin(m)
    return continued


def play(m, route):
    for joy, fire in route:
        tick(m, joy, fire)
        assert m.get('mode') in (2, 4), 'Recovery route died'
    assert m.get('mode') == 4, 'Recovery must reach the finish'


def miss_finish(m, route):
    last_jump = max(i for i, (_, fire) in enumerate(route) if fire)
    for joy, fire in route[:last_jump]:
        tick(m, joy, fire)
        assert m.get('mode') == 2
    assert not m.get('jumping')
    for _ in range(500):
        tick(m, 8)
        if m.get('mode') != 2:
            break
    assert m.get('mode') == 3 and m.word('world') >= m.word('stage_end') - 100


early = []
late = []
for player in range(2):
    for rank in range(6):
        for act in (1, 3):
            route = json.loads((ROOT / f'assets/routes/mechanics-route-{act}-{rank}.json').read_text())
            m = Machine()
            m.stage(act, rank)
            m.set('player', player)
            other = 0xda00 + 256 * (player ^ 1)
            untouched = bytes(m.m[other:other + 256])
            continued = 0
            for _ in range(4):
                for ticks in range(600):
                    tick(m)
                    if m.get('mode') == 3:
                        break
                assert ticks > 60, 'Immediate death after restarting'
                continued += retry(m)
                assert m.word('world') == (48 if act == 1 else 60)
                assert bytes(m.m[other:other + 256]) == untouched
            assert continued == 1 and m.get('checkpoint_restores') == 4
            play(m, route)
            early.append(dict(player=player + 1, rank=rank + 1, act=act + 1,
                              deaths=4, continues=continued, recovered_and_cleared=True))

        m = Machine()
        m.stage(1, rank)
        m.set('player', player)
        original = json.loads((ROOT / f'assets/routes/mechanics-route-1-{rank}.json').read_text())
        recovery = json.loads((ROOT / f'assets/routes/tightrope-retry-{rank}.json').read_text())
        continued = 0
        for death in range(3):
            miss_finish(m, original if death == 0 else recovery)
            continued += retry(m)
            assert m.word('world') == 1200
        assert continued == 1 and m.get('checkpoint_restores') == 3
        play(m, recovery)
        late.append(dict(player=player + 1, rank=rank + 1, deaths=3,
                         continues=continued, recovered_and_cleared=True))

report = dict(early=early, late=late, natural_deaths=132, continues=36,
              completed_recovery_routes=36, independent_checkpoint_pages=True)
(ROOT / 'build/tightrope-retry.json').write_text(json.dumps(report, indent=2))
print(json.dumps(report, indent=2))
