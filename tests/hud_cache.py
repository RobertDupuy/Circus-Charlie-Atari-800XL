"""Compare cached numeric HUD updates with a complete numeric redraw."""
from cpu import Machine,ROOT
import json

cases=0
for scene in range(7):
    m=Machine();m.stage(scene)
    for back in (0,1):
        m.set('back',back);m.call('render_frame')
        changes=[('bonus',0x7990),('bonus',0x7980),('bonus',0x0090),('bonus',0),
                 ('score',0x0100),('highscore',0x0200),('lives',4),('round',2),
                 ('player',1),('bonus',0x8000),('bonus',0x7990)]
        for field,value in changes:
            if field in ('bonus','score','highscore'):m.wordset(field,value)
            else:m.set(field,value)
            m.c.at_save_slot(0);m.call('draw_hud');cached=bytes(m.m[0x6a00:0x6b40])
            m.c.at_restore_slot(0);m.m[0xdca0+back*16]=0;m.call('draw_hud')
            assert bytes(m.m[0x6a00:0x6b40])==cached,(scene,back,field,value)
            cases+=1
report={'cached_updates_match_full_numeric_redraw':True,'cases':cases}
(ROOT/'build/hud-cache.json').write_text(json.dumps(report,indent=2));print(report)
