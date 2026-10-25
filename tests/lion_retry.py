"""Natural Act 1 collisions, retries and continues on the assembled 6502.

Unlike a perfect input replay, these routes deliberately run into fire. Both
checkpoint pages and all six ranks must retain their moving hoops and pots.
"""
from cpu import Machine, ROOT
import json


def tick(m, joy=0, fire=0):
    m.set('input', joy)
    m.set('fire_latch', fire)
    cycles = m.call('game_tick')
    m.set('back', m.get('back') ^ 1)
    return cycles + m.call('render_frame')


def begin(m):
    while m.get('mode') == 1:
        tick(m)
    assert m.get('mode') == 2


def collide(m):
    for _ in range(3000):
        tick(m, 8)
        if m.get('mode') != 2:
            break
    assert m.get('mode') == 3, 'Running into a hoop/pot must lose a life'
    # This slice includes the gap clock, live hoops, pot positions, paid flags
    # and pot count; takeoff/landing scratch is intentionally reset on retry.
    return bytes(m.m[0xd903:0xd939])


def after_death(m):
    while m.get('mode') == 3:
        tick(m)
    continued = m.get('mode') == 6
    if continued:
        tick(m, fire=1)
        assert m.get('lives') == 3
    assert m.get('need_stage') and m.get('mode') == 1
    m.call('load_stage')
    return continued


cases = []
for player in range(2):
    for rank in range(6):
        m = Machine()
        m.stage(0, rank)
        m.set('player', player)
        other = 0xda00 + 256 * (player ^ 1)
        untouched = bytes(m.m[other:other + 256])
        continued = 0
        costs = []
        for death in range(4):
            state = collide(m)
            continued += after_death(m)
            assert bytes(m.m[0xd903:0xd939]) == state, (player, rank, death, 'lost lion state')
            assert m.get('lion_potcount') == (5 if rank == 0 else 8)
            assert bytes(m.m[other:other + 256]) == untouched, 'Other player checkpoint overwritten'
            begin(m)
            # Exercise the restored renderer, not just the checkpoint bytes.
            for _ in range(20):
                costs.append(tick(m))
                assert m.get('mode') == 2
            assert not m.get('fault')
        assert continued == 1 and m.get('checkpoint_restores') == 4
        # A zero restored pot count formerly wrapped the loops through 256
        # objects and took >50,000 CPU cycles per tick+picture (before DMA).
        assert max(costs) < 30000, (player, rank, max(costs))
        cases.append(dict(player=player + 1, rank=rank + 1, deaths=4,
                          continues=continued, max_retry_cycles=max(costs)))

# Real two-player switching must recover each player's last collision state.
m = Machine()
m.set('players', 2)
m.set('fire_latch', 1)
m.call('game_tick')
m.call('load_stage')
saved = {}
turns = []
for _ in range(4):
    begin(m)
    player = m.get('player')
    turns.append(player + 1)
    saved[player] = collide(m)
    assert not after_death(m)
    assert m.get('player') == (player ^ 1)
    if m.get('player') in saved:
        assert bytes(m.m[0xd903:0xd939]) == saved[m.get('player')]
    assert m.get('lion_potcount') == 5 and not m.get('fault')
assert turns == [1, 2, 1, 2]

report = dict(cases=cases, alternating_turns=turns,
              natural_collisions=52, continues=12, independent_checkpoints=True)
(ROOT / 'build/lion-retry.json').write_text(json.dumps(report, indent=2))
print(json.dumps(report, indent=2))
