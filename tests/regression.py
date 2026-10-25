from cpu import Machine,ROOT
import struct,json
m=Machine();m.stage(0)
# A missed hoop costs a life and enters the retry path.
m.wordset('world',149);m.m[0x940]=149;m.m[0x950]=0;m.m[0xd90c]=1;m.set('input',8);m.call('game_tick')
assert m.get('mode')==3 and m.get('lives')==2
for _ in range(150):m.call('game_tick')
assert m.get('need_stage')==1
m.call('load_stage');assert m.get('mode')==1 and m.word('world')==128
for _ in range(90):m.call('game_tick')
assert m.get('mode')==2
# Pause holds gameplay state; unpausing resumes it.
m.set('pause_latch',1);m.call('game_tick');w=m.word('world');t=m.word('scene_clock')
for _ in range(30):m.call('game_tick')
assert m.word('world')==w and m.word('scene_clock')==t
m.set('pause_latch',1);m.call('game_tick');assert m.word('world')==w+1
# Timeout and exhausted lives lead to game over; fire starts a fresh game.
m.set('lives',1);m.wordset('bonus',0x0010);m.set('timer_div',5);m.call('game_tick')
assert m.get('lives')==0 and m.get('mode')==3
for _ in range(150):m.call('game_tick')
assert m.get('mode')==6
for _ in range(300):m.call('game_tick')
assert m.get('mode')==5
m.set('fire_latch',1);m.call('game_tick')
assert m.get('mode')==1 and m.get('lives')==3 and m.get('need_stage')==1
# Leftward rolling also detects contact with the previous ball.
m.stage(3);m.set('current_ball',1);m.wordset('world',81);m.set('input',4);m.call('game_tick');m.call('game_tick')
assert m.get('mode')==3
# Decimal scoring and act-clear bonus carry correctly.
m.stage(0);m.wordset('score',0);m.set('score',0);m.m[0x634]=0
m.wordset('bonus',0x1234);m.set('stage_hurt',0);m.call('finish_act')
assert bytes(m.m[0x632:0x635])==bytes([0x34,0x32,0])
# Every bank has the same reset entry, with all vectors outside asset payloads.
c=(ROOT/'build/Circus-Charlie-SIC512.car').read_bytes();rom=c[16:]
assert len(rom)==512*1024 and struct.unpack('>I',c[4:8])[0]==56
assert sum(rom)&0xffffffff==struct.unpack('>I',c[8:12])[0]
assert all(rom[b*16384+16128:(b+1)*16384]==rom[16128:16384] for b in range(32))
assert rom[16378:16380]==b'\x00\xbf'
results={'missed_hoop_and_retry':True,'pause_and_resume':True,'timeout_gameover_restart':True,'BCD_score_and_clear_bonus':True,'both_ball_neighbors':True,'SIC_type_size_checksum':True,'reset_vectors_all_32_banks':True}
(ROOT/'build/regression.json').write_text(json.dumps(results,indent=2));print(json.dumps(results,indent=2))
