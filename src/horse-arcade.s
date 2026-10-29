; KONAMI-1 Horse update order: goal, objects/contacts, rebound, vertical,
; riding input/takeoff, horizontal. Raw Y/velocity are signed 8.8 arcade units.
.proc fidelity_horse_init
 lda #0
 sta world+1
 sta f_counter
 sta h_opening
 sta f_horse_h
 sta f_horse_v
 sta f_horse_v+1
 sta jumping
 sta spring_pending
 sta h_goal_phase
 sta h_goal_x
 sta h_speed
 sta r_clock_fraction
 sta r_clock_fraction+1
 sta r_clock_fraction+2
 ldx #15
@clear:
 sta h_state,x
 sta h_width,x
 sta h_screen,x
 sta h_delay,x
 sta h_build,x
 sta h_src_height,x
 sta h_draw_scroll,x
 sta h_deck,x
 dex
 bpl @clear
 lda #$9C
 sta f_horse_h+1
 lda #255
 sta f_scroll
 sta f_scroll+1
 lda #47
 sta world
 lda #64
 sta f_fraction
 lda #1
 sta h_state
 lda #8
 sta h_delay
 lda #2
 sta timer_div
 lda #$60
 sta bonus
 lda #$53
 sta bonus+1
 lda #<3690
 sta stage_end
 lda #>3690
 sta stage_end+1
 jmp apparatus_clock_reset
.endproc

.proc fidelity_horse_input
 lda z_joy
 and #4
 bne @slow
 lda z_joy
 and #8
 beq @normal
 lda #3
 bne @save
@slow: lda #1
 bne @save
@normal: lda #2
@save: sta h_speed
 rts
.endproc

.proc fidelity_horse_step
 lda f_scroll
 eor #255
 sta h_source_low
 jsr horse_goal
 lda h_goal_phase
 cmp #4
 bne :+
 jmp finish_act
:
 lda mode
 cmp #2
 bne @done
 lda #0
 sta h_contact
 lda f_horse_h+1
 clc
 adc #20
 sta h_body
 ldx #0
@object:
 jsr horse_object
 lda mode
 cmp #2
 bne @done
 inx
 cpx #8
 bne @object
 lda h_contact
 beq @vertical
 lda #$E8
 sec
 sbc f_horse_v
 sta f_horse_v
 lda #$FF
 sbc f_horse_v+1
 sta f_horse_v+1
@vertical:
 lda jumping
 beq @riding
 jsr fidelity_horse_gravity
 jmp @move
@riding:
 jsr fidelity_horse_input
 lda z_fire
 beq @move
 jsr fidelity_horse_launch
@move:
 jsr fidelity_horse_move
 lda #156
 sec
 sbc f_horse_h+1
 sta jump_pixels
 lda f_horse_v+1
 eor #255
 sta velocity
@done: rts
.endproc

.proc fidelity_horse_launch
 lda #1
 sta jumping
 sta sound_fx
 lda #0
 sta sound_age
 sta f_horse_v
 lda #$FD
 sta f_horse_v+1
 rts
.endproc
.proc fidelity_horse_gravity
 lda f_horse_v
 clc
 adc #$18
 sta f_horse_v
 lda f_horse_v+1
 adc #0
 sta f_horse_v+1
 lda f_horse_h
 clc
 adc f_horse_v
 sta f_horse_h
 lda f_horse_h+1
 adc f_horse_v+1
 sta f_horse_h+1
 cmp #156
 bne @done
 lda #0
 sta jumping
 sta spring_pending
@done: rts
.endproc

.proc fidelity_horse_move
 lda f_scroll
 clc
 adc h_speed
 sta f_scroll
 bcc :+
 inc f_scroll+1
 lda f_scroll+1
 cmp #17
 bne :+
 inc h_goal_phase
 ldx #7
@stop:
 lda h_state,x
 cmp #1
 bne @next
 dec h_state,x
@next: dex
 bpl @stop
:
 ldx #7
@objects:
 lda h_screen,x
 sec
 sbc h_speed
 sta h_screen,x
 lda h_delay,x
 sec
 sbc h_speed
 sta h_delay,x
 dex
 bpl @objects
 lda h_goal_x
 sec
 sbc h_speed
 sta h_goal_x
 ldy h_speed
 lda h_speed_fraction,y
 clc
 adc f_fraction
 sta f_fraction
 lda h_speed_whole,y
 adc world
 sta world
 bcc :+
 inc world+1
:
 rts
.endproc
h_speed_fraction: .byte 0,192,128,64
h_speed_whole: .byte 0,0,1,2

.proc horse_object
 lda h_state,x
 jeq @done
 cmp #1
 jeq horse_spawn
 cmp #2
 beq @build
 jsr horse_contact
 lda mode
 cmp #2
 bne @done
 lda h_source_low
 sec
 sbc h_draw_scroll,x
 cmp #9
 bcs @done
 lda h_draw_scroll,x
 sec
 sbc #8
 sta h_draw_scroll,x
 dec h_build,x
 bne @done
 lda #0
 sta h_state,x
 lda #2
 sta h_opening
 rts
@build:
 lda h_draw_scroll,x
 sec
 sbc h_source_low
 cmp #8
 bcc @done
 lda h_draw_scroll,x
 sec
 sbc #8
 sta h_draw_scroll,x
 dec h_build,x
 bne @done
 lda h_width,x
 asl
 asl
 sta z_tmp
 lda h_draw_scroll,x
 and #7
 clc
 adc #$F3
 sec
 sbc h_draw_scroll,x
 clc
 adc h_source_low
 sec
 sbc z_tmp
 sta h_screen,x
 lda h_src_height,x
 clc
 adc #1
 asl
 asl
 asl
 sta h_deck,x
 lda h_draw_scroll,x
 clc
 adc #56
 sta h_draw_scroll,x
 lda #7
 sta h_build,x
 inc h_state,x
@done: rts
.endproc

.proc horse_spawn
 lda h_delay,x
 cmp #3
 jcs @done
 lda rank
 clc
 adc #1
 asl
 asl
 asl
 asl
 clc
 adc f_counter
 cmp #104
 bcc :+
 and #7
 ora #96
:
 tay
 lda h_width_table,y
 sta h_width,x
 lda h_height_table,y
 sta horse_y,x
 lda h_opening
 cmp #1
 bne @normal
 txa
 clc
 adc #1
 and #7
 sta z_tmp
 sty z_hazard
 ldy z_tmp
 lda horse_y,y
 sta horse_y,x
 ldy z_hazard
 lda #7
 sta h_width,x
@normal:
 lda horse_y,x
 clc
 adc #16
 lsr
 lsr
 lsr
 sta h_src_height,x
 lda h_source_low
 sta h_draw_scroll,x
 lda #7
 sta h_build,x
 inc h_state,x
 ; Stable world coordinates used by the Atari renderer only.
 lda f_scroll
 clc
 adc #7
 and #$F8
 sta z_pos
 lda f_scroll+1
 adc #0
 sta z_pos+1
 lda h_width,x
 asl
 asl
 sta z_tmp
 lda z_pos
 clc
 adc #<299
 sta z_pos
 lda z_pos+1
 adc #>299
 sta z_pos+1
 lda z_pos
 sec
 sbc z_tmp
 sta z_pos
 lda z_pos+1
 sbc #0
 sta z_pos+1
 lda z_pos
 sta z_tempword
 lda z_pos+1
 sta z_tempword+1
 asl z_pos
 rol z_pos+1
 lda z_pos
 clc
 adc z_tempword
 sta z_pos
 lda z_pos+1
 adc z_tempword+1
 sta z_pos+1
 lsr z_pos+1
 ror z_pos
 lsr z_pos+1
 ror z_pos
 lda z_pos
 sta hazard_xlo,x
 lda z_pos+1
 sta hazard_xhi,x
 lda h_gap_table,y
 ldy h_opening
 bne :+
 inc h_opening
 lda #52
:
 sta z_tmp
 txa
 sec
 sbc #1
 and #7
 tay
 lda h_state,y
 clc
 adc #1
 sta h_state,y
 lda z_tmp
 sta h_delay,y
 inc f_counter
@done: rts
.endproc

.proc horse_contact
 lda h_width,x
 asl
 asl
 clc
 adc #2
 sta z_left
 lda h_screen,x
 sec
 sbc #64
 sta z_pos
 lda jumping
 beq @body
 lda z_pos
 clc
 adc z_left
 asl z_left
 cmp z_left
 bcs @edge
 lda h_deck,x
 sec
 sbc h_body
 sec
 sbc #13
 cmp #4
 bcs @edge
 lda f_horse_v+1
 bmi @diagonal
 inc h_contact
 txa
 pha
 jsr fidelity_spring_points
 pla
 tax
 jsr fidelity_horse_input
 lda #1
 sta sound_fx
 lda #0
 sta sound_age
 rts
@edge:
 lda h_width,x
 asl
 asl
 clc
 adc #5
 sta z_left
 lda z_pos
 clc
 adc z_left
 asl z_left
 cmp z_left
 bcs @done
 lda h_deck,x
 sec
 sbc h_body
 sec
 sbc #17
 cmp #4
 bcc @done
@body:
 lda h_width,x
 asl
 asl
 clc
 adc #2
 sta z_left
 lda z_pos
 clc
 adc z_left
 asl z_left
 cmp z_left
 bcs @done
 lda h_deck,x
 sec
 sbc h_body
 clc
 adc #18
 cmp #36
 bcs @done
@diagonal:
 lda h_width,x
 asl
 asl
 clc
 adc #9
 sta z_left
 lda #64
 clc
 adc h_body
 sec
 sbc h_screen,x
 sec
 sbc h_deck,x
 clc
 adc z_left
 asl z_left
 cmp z_left
 bcs @done
 jmp horse_hurt_return
@done: rts
.endproc

.proc horse_goal
 lda h_goal_phase
 jeq @done
 cmp #3
 beq @contact
 cmp #1
 bne @build
 lda f_scroll+1
 cmp #18
 jne @done
 lda h_source_low
 clc
 adc #32
 cmp #3
 jcs @done
 lda #8
 sta h_goal_build
 lda h_source_low
 sta h_goal_scroll
 inc h_goal_phase
 rts
@build:
 lda h_goal_scroll
 sec
 sbc h_source_low
 cmp #8
 bcc @done
 lda h_goal_scroll
 sec
 sbc #8
 sta h_goal_scroll
 dec h_goal_build
 bne @done
 and #7
 clc
 adc #216
 sec
 sbc h_goal_scroll
 clc
 adc h_source_low
 sta h_goal_x
 inc h_goal_phase
 rts
@contact:
 lda f_horse_h+1
 clc
 adc #20
 sta z_body
 lda h_goal_x
 sec
 sbc #36
 cmp #56
 bcs @fall
 lda z_body
 cmp #161
 bcc @fall
 lda #141
 sta f_horse_h+1
 lda #27
 sta jump_pixels
 lda #1
 sta horse_finish
 inc h_goal_phase
 rts
@fall:
 lda z_body
 cmp #196
 bcs @hurt
 cmp #161
 bcc @done
 lda h_goal_x
 sec
 sbc #22
 cmp #84
 bcs @done
@hurt: jmp horse_hurt_return
@done: rts
.endproc

.include "horse-tables.inc"

; Arcade retry: remove generated-but-unpassed objects, rewind one source
; page, then let initialization consume the first page boundary normally.
.proc fidelity_horse_resume
 lda f_counter
 ldx #7
@objects:
 ldy h_state,x
 cpy #2
 bcc :+
 sec
 sbc #1
:
 dex
 bpl @objects
 pha
 lda h_opening
 and #254
 pha
 lda f_scroll+1
 beq @page
 sec
 sbc #1
 cmp #18
 bcc @page
 lda #17
@page:
 pha
 jsr fidelity_horse_init
 pla
 sta resume_steps
 sec
 sbc #1
 sta f_scroll+1
 pla
 sta h_opening
 pla
 sta f_counter
 lda #$48
 ldx resume_steps
 cpx #4
 bcc :+
 lda #$40
 cpx #8
 bcc :+
 lda #$30
:
 sta bonus+1
 lda #0
 sta bonus
 sta jump_pixels
 sta velocity
 sta scene_clock
 sta scene_clock+1
 sta grace
 ldx resume_steps
 beq @ready
@world:
 lda world
 clc
 adc #192
 sta world
 bcc :+
 inc world+1
:
 dex
 bne @world
@ready:
 inc checkpoint_restores
 jmp update_camera
.endproc

.segment "XL"
; Checkpoint saving selects the system ROM. Restore this act's ROM before
; returning to its object loop, including natural misses at the goal.
.proc horse_hurt_return
 jsr hurt
 lda #$3D
 sta $D500
 rts
.endproc
.segment "APPARATUS"
