"""Victory animation must never enter the blocking PCM playback path.

Exercise the real control/stream players through a complete celebration,
including coin rewards and both standards. Unlike a renderer-only fixture,
this invokes the foreground audio entry between updates.
"""
from cpu import Machine, ROOT
import json

reports=[]
for pal in (0,1):
    for scene in range(7):
        m=Machine();m.stage(scene);m.set('pal',pal);m.call('audio_init')
        m.call('finish_act');samples=[];quiet=longest=0;peak_pcm=0
        accumulator=0;tv=0
        while m.get('mode')==4:
            m.wordset('host_frames',tv)
            m.call('audio_control')
            assert not m.m[0x6db],('blocking applause was queued',scene,pal,tv)
            peak_pcm=max(peak_pcm,m.call('pcm_play'))
            assert peak_pcm<40 and not m.m[0x6dc]
            for _ in range(2):
                m.call('audio_tick')
                audible=any(m.m[p]&15 for p in (0xd201,0xd203,0xd205,0xd207))
                quiet=0 if audible else quiet+1;longest=max(longest,quiet)
            samples.append(m.get('clear_elapsed'))
            accumulator+=60
            while accumulator>=(50 if pal else 60) and m.get('mode')==4:
                accumulator-=50 if pal else 60
                m.call('game_tick')
            if m.get('mode')==4:
                m.set('back',tv&1);m.call('render_frame')
                assert not m.get('fault')
            tv+=1
            assert tv<230
        assert all(1<=b-a<=2 for a,b in zip(samples,samples[1:])),(scene,pal,samples)
        assert longest<=4,('victory music stopped',scene,pal,longest)
        assert m.m[0xd804],('victory stream was discarded',scene,pal)
        reports.append(dict(scene=scene,standard='pal' if pal else 'ntsc',
                            celebration_tv_frames=tv,longest_silent_audio_updates=longest,
                            peak_foreground_audio_cycles=peak_pcm,continuous_animation=True))
(ROOT/'build/celebration-audio.json').write_text(json.dumps(reports,indent=2)+'\n')
print(reports)
