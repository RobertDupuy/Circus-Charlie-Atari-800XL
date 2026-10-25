.setcpu "6502"
.macpack longbranch
.include "memory.inc"
.export start,game_tick,render_frame,mode,act,world,height,velocity,jumping,host_frames,presented,missed,fault,ready,front,back,input,fire_latch,scene_clock,stage_end,finish_count,clear_count,max_interval,paused,need_stage
.segment "CODE"
.include "hardware.s"
.include "render.s"
.include "logic.s"
.include "tables.s"
.segment "COMPLETE"
.include "water.s"
.include "rewards.s"
.include "complete.s"
.segment "SYSTEM"
.include "system.s"

.segment "XL"
.include "audio.s"
.include "arcade.s"

.include "pcm.s"
.segment "MECHANICS"
.include "mechanics.s"
.include "lion-arcade.s"

.segment "GFX"
.include "graphics.s"

.segment "FIDELITY"
.include "fidelity.s"

.segment "APPARATUS"
.include "arcade-apparatus.s"

.segment "TRAMPOLINE"
.include "trampoline.s"

.include "title.s"

.segment "MASK"
.repeat 256,I
 .byte ((I & $C0)=0)*$C0 + ((I & $30)=0)*$30 + ((I & $0C)=0)*$0C + ((I & $03)=0)*$03
.endrepeat
