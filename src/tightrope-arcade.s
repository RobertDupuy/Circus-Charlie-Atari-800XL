; Native source-space model. Scale coordinates only when publishing graphics.
.proc k_init
 lda #0
 sta f_scroll
 sta f_scroll+1
reset:
 sta f_direction
 sta f_phase
 sta f_counter
 sta k_subx
 sta k_left_clock
 sta k_skip
 sta k_brown
 sta k_pink
 sta k_awards
 sta k_idle
 sta k_idle+1
 sta k_fire_pending
 sta jumping
 sta grace
 sta jump_pixels
 sta timer_div
 sta r_clock_fraction
 sta r_clock_fraction+1
 sta r_clock_fraction+2
 ldx #6
@clear:
 sta f_active,x
 sta k_state_m,x
 sta k_frac,x
 sta k_mx,x
 sta k_my,x
 sta k_phase,x
 sta monkey_jump,x
 dex
 bpl @clear
 lda #3
 sta k_frame
 lda #1
 sta k_first
 sta k_state
 lda #64
 sta k_x
 lda #$07
 sta bonus
 lda #$64
 sta bonus+1
 lda #<1465
 sta stage_end
 lda #>1465
 sta stage_end+1
 lda rank
 asl
 asl
 asl
 clc
 adc rank
 sta z_tmp
 lda f_scroll+1
 cmp #5
 bne :+
 clc
 adc #1
:
 clc
 adc z_tmp
 tax
 lda k_pages_lo,x
 sta f_sequence
 lda k_pages_hi,x
 sta f_sequence+1
 jsr apparatus_clock_reset
 jmp k_publish
.endproc
.proc k_resume
 lda f_scroll+1
 ldx f_scroll
 bne @round
 cmp #0
 beq @round
 sec
 sbc #1
@round:
 cmp #6
 bcc :+
 sec
 sbc #1
:
 sta f_scroll+1
 lda #0
 sta f_scroll
 jsr k_init::reset
 lda #0
 sta bonus
 lda #$40
 ldx f_scroll+1
 cpx #3
 bcc :+
 lda #$35
 cpx #5
 bcc :+
 lda #$30
:
 sta bonus+1
 inc checkpoint_restores
 jmp update_camera
.endproc
.proc k_step
 inc k_frame
 lda k_first
 beq @play
 lda #0
 sta k_first
 ; The first live update reads the controls, while retaining the
 ; original initialization-only actor/spawn update on this frame.
 jmp @idle_ready
@play:
 jsr k_collision
 lda mode
 cmp #2
 jne @done
 jsr k_leaps
 jsr k_spawn
 jsr k_actors
 lda jumping
 ora f_direction
 bne @idle_reset
 inc k_idle
 bne :+
 inc k_idle+1
:
 lda k_idle+1
 beq @idle_ready
 lda k_idle
 cmp #128
 bcc @idle_ready
 lda #2
 sta k_state
 jmp k_lose
@idle_reset:
 lda #0
 sta k_idle
 sta k_idle+1
@idle_ready:
 ; At the first grounded update, original $86F3-$8703 cancels a queued
 ; press that is still held. A released tap survives for this takeoff.
 lda jumping
 bne @check_fire
 lda k_fire_pending
 beq @check_fire
 lda fire_held
 beq @input_ready
 lda #0
 sta k_fire_pending
 jmp @input_ready
@check_fire:
 ; Original $870E-$871A queues a fresh press only while descending at
 ; source Y >= $68 (height <= 32). Retain it until the first grounded
 ; update, then consume once. Early/ascending presses do not queue.
 lda z_fire
 beq @input_ready
 lda jumping
 beq @queue_fire
 lda f_phase
 cmp #29
 bcc @input_ready
 lda jump_pixels
 cmp #33
 bcs @input_ready
@queue_fire:
 lda #1
 sta k_fire_pending
@input_ready:
 lda jumping
 bne @motion
 lda z_joy
 and #12
 cmp #12
 bne :+
 lda #0
:
 sta f_direction
 lda k_fire_pending
 beq @motion
 lda #1
 sta jumping
 sta sound_fx
 lda #0
 sta k_fire_pending
 sta f_phase
 sta sound_age
 jsr k_takeoff
@motion:
 jsr k_move
 lda jumping
 beq @publish
 inc f_phase
 ldx f_phase
 lda arcade_jump,x
 sta jump_pixels
 lda #29
 sec
 sbc f_phase
 sta velocity
 cpx #53
 bne @land
 jsr k_at_end
 bcc @land
 lda k_x
 cmp #160
 bcc @land
 cmp #202
 bcs @land
 lda #19
 sta jump_pixels
 lda #0
 sta jumping
 sta k_fire_pending
 lda #4
 sta k_state
 jsr k_publish
 jmp k_finish
@land:
 ldx f_phase
 cpx #57
 bcc @publish
 lda #0
 sta jumping
 sta jump_pixels
 jsr k_reward
@publish:
 jsr k_publish
@done:
 rts
.endproc
.proc k_at_end
 lda f_scroll+1
 cmp #7
 bcc @done
 lda f_scroll
 cmp #1
@done:
 rts
.endproc
.proc k_move
 lda f_direction
 beq @done
 cmp #4
 beq @left
 jsr k_at_end
 bcs @right_edge
 lda jumping
 bne @scroll_right
 lda k_x
 cmp #64
 bcs @scroll_right
 inc k_subx
 lda k_subx
 and #1
 bne @scroll_right
 inc k_x
@scroll_right:
 inc f_scroll
 bne @done
 inc f_scroll+1
 rts
@right_edge:
 lda k_x
 cmp #192
 bcs @done
 inc k_x
 rts
@left:
 lda f_scroll
 ora f_scroll+1
 beq @done
 jsr k_at_end
 bcc @left_walk
 lda k_x
 cmp #64
 bcc @left_walk
 dec k_x
 rts
@left_walk:
 lda jumping
 bne @scroll_left
 lda k_x
 cmp #32
 bcc @scroll_left
 inc k_subx
 lda k_subx
 and #1
 bne @scroll_left
 dec k_x
@scroll_left:
 inc k_left_clock
 lda k_left_clock
 and #1
 bne @done
 lda f_scroll
 bne :+
 dec f_scroll+1
:
 dec f_scroll
@done:
 rts
.endproc
.proc k_collision
 ldx #0
@loop:
 lda f_active,x
 beq @next
 lda k_mx,x
 clc
 adc #13
 sta z_tmp
 lda k_x
 clc
 adc #19
 sec
 sbc z_tmp
 bcs :+
 eor #255
 clc
 adc #1
:
 cmp #13
 bcs @next
 sta z_tmp
 lda #136
 sec
 sbc jump_pixels
 sec
 sbc k_my,x
 bcs :+
 eor #255
 clc
 adc #1
:
 cmp #16
 bcs @next
 clc
 adc z_tmp
 cmp #20
 bcs @next
 lda #7
 sta k_state
 jmp k_lose
@next:
 inx
 cpx #7
 bne @loop
 rts
.endproc
.proc k_leaps
 ldx #4
@pink:
 lda f_active,x
 beq @next
 lda k_state_m,x
 bne @next
 lda k_mx,x
 cmp #48
 bcc @next
 cmp #208
 bcs @next
 ldy #0
@brown:
 lda f_active,y
 beq @bnext
 lda k_state_m,y
 bne @bnext
 lda k_mx,x
 sec
 sbc k_mx,y
 cmp #24
 bcs @bnext
 tya
 sta k_under,x
 lda #9
 sta k_state_m,y
 lda #8
 sta k_state_m,x
 lda #0
 sta k_phase,x
 inc leap_events
 jmp @next
@bnext:
 iny
 cpy #4
 bne @brown
@next:
 inx
 cpx #7
 bne @pink
 rts
.endproc
.proc k_spawn
 lda f_direction
 cmp #4
 jeq @done
 lda f_counter
 sta z_tmp
 lda f_direction
 bne @inc
 lda k_frame
 and #3
 beq @check
@inc:
 inc f_counter
@check:
 lda f_sequence
 sta z_ptr
 lda f_sequence+1
 sta z_ptr+1
 ldy #0
 lda (z_ptr),y
 cmp z_tmp
 jne @done
 iny
 lda (z_ptr),y
 sta z_kind
 cmp #2
 jcs @done
 ldx #0
 cmp #0
 beq @pool
 ldx #4
@pool:
 lda f_active,x
 beq @slot
 inx
 cpx #7
 jeq @done
 cpx #4
 bne @pool
 lda z_kind
 bne @pool
 rts
@slot:
 ldy #0
@clearance:
 cpy #4
 bcs @safe
 lda k_mx,y
 cmp #200
 bcc @safe
 cmp #242
 bcc @done
@safe:
 iny
 cpy #7
 bne @clearance
 lda f_direction
 cmp #8
 bne @skip
 jsr k_at_end
 bcc @spawn
@skip:
 lda k_skip
 cmp #2
 beq @spawn
 inc k_skip
 jmp @advance
@spawn:
 lda #0
 sta k_skip
 sta k_frac,x
 sta k_state_m,x
 sta k_phase,x
 sta monkey_jump,x
 lda #1
 sta f_active,x
 lda z_kind
 sta monkey_type,x
 lda #241
 sta k_mx,x
 lda #136
 sta k_my,x
@advance:
 lda f_sequence
 clc
 adc #2
 sta f_sequence
 sta z_ptr
 lda f_sequence+1
 adc #0
 sta f_sequence+1
 sta z_ptr+1
 ldy #0
 lda (z_ptr),y
 cmp #255
 bne @done
 iny
 lda (z_ptr),y
 sta f_sequence
 iny
 lda (z_ptr),y
 sta f_sequence+1
@done:
 rts
.endproc
.proc k_actors
 ldx #0
@loop:
 lda f_active,x
 jeq @next
 lda k_state_m,x
 cmp #2
 jeq @remove
 cmp #8
 beq @leap
 cmp #9
 beq @passive
 cmp #1
 beq @wait
 jsr k_walk
 jmp @retire
@wait:
 dec k_wait,x
 bne @passive
 lda #0
 sta k_state_m,x
@passive:
 jsr k_passive
 jmp @retire
@leap:
 inc k_phase,x
 ldy k_phase,x
 lda arcade_monkey_jump,y
 sta monkey_jump,x
 lda #136
 sec
 sbc monkey_jump,x
 sta k_my,x
 cpy #38
 bcc @leap_move
 lda #0
 sta k_state_m,x
 sta k_phase,x
 ldy k_under,x
 lda k_state_m,y
 cmp #1
 beq @leap_move
 lda #0
 sta k_state_m,y
@leap_move:
 jsr k_at_end
 bcs @dec
 lda f_direction
 beq @dec
 cmp #4
 beq :+
 dec k_mx,x
:
 lda k_frac,x
 clc
 adc #$C0
 bcc @dec
 sta k_frac,x
 jmp @retire
@dec:
 dec k_mx,x
@retire:
 lda k_mx,x
 cmp #242
 bcc @next
 cmp #245
 bcs @next
 lda #2
 sta k_state_m,x
 jmp @next
@remove:
 lda #0
 sta f_active,x
 sta k_state_m,x
 sta k_mx,x
 sta k_frac,x
 sta k_my,x
@next:
 inx
 cpx #7
 jne @loop
 rts
.endproc
.proc k_passive
 jsr k_at_end
 bcs @done
 lda f_direction
 beq @done
 cmp #4
 beq @left
 lda k_frac,x
 clc
 adc #$C0
 sta k_frac,x
 bcc @done
 dec k_mx,x
 rts
@left:
 lda k_frac,x
 clc
 adc #$40
 sta k_frac,x
 bcc @done
 inc k_mx,x
@done:
 rts
.endproc
.proc k_walk
 jsr k_at_end
 lda #0
 rol
 sta z_tmp2
 lda monkey_type,x
 beq @brown
 lda z_tmp2
 beq @pink_normal
 lda f_direction
 beq @dec
@pink_normal:
 lda k_frac,x
 clc
 adc #$80
 sta k_frac,x
 bne :+
 dec k_mx,x
:
 lda f_direction
 cmp #4
 beq @done
 dec k_mx,x
 lda z_tmp2
 bne @done
 lda f_direction
 beq @done
@dec:
 dec k_mx,x
 rts
@brown:
 lda z_tmp2
 bne @brown_end
 lda #$C0
 ldy f_direction
 beq :+
 lda #$40
:
 clc
 adc k_frac,x
 sta k_frac,x
 bcc :+
 dec k_mx,x
:
 lda f_direction
 cmp #8
 beq @dec
 rts
@brown_end:
 lda #$C0
 ldy f_direction
 beq @add
 lda #$80
 cpy #4
 beq @add
 sta k_frac,x
 jmp @dec
@add:
 clc
 adc k_frac,x
 sta k_frac,x
 bcs @dec
@done:
 rts
.endproc
.proc k_takeoff
 lda #0
 sta k_brown
 sta k_pink
 ldx #0
@scan:
 lda f_active,x
 beq @next
 lda k_mx,x
 sec
 sbc k_x
 bcc @next
 sta z_tmp
 cpx #4
 bcs @pink
 lda f_direction
 cmp #4
 beq @next
 ldy #32
 cmp #0
 beq :+
 ldy #80
:
 cpy z_tmp
 bcc @next
 beq @next
 inc k_brown
 lda k_brown
 cmp #1
 bne @next
 txa
 sta k_reward_slot
 jmp @next
@pink:
 ldy #64
 lda f_direction
 beq @range
 ldy #32
 cmp #4
 beq @range
 ldy #128
@range:
 cpy z_tmp
 bcc @next
 beq @next
 inc k_pink
 lda k_brown
 bne @next
 txa
 sta k_reward_slot
@next:
 inx
 cpx #7
 bne @scan
 rts
.endproc
.proc k_reward
 lda k_brown
 ora k_pink
 beq @done
 inc k_awards
 lda k_brown
 beq @pink
 ldy k_pink
 beq @brown
 clc
 adc k_pink
 sta k_brown
 jmp @special
@pink:
 lda k_pink
 cmp #2
 bcs @special
 ldy #3
 lda #0
 jmp k_points
@brown:
 clc
 adc #1
 tay
 lda #0
 jmp k_points
@special:
 sta z_tmp
 ldx k_reward_slot
 lda #1
 sta k_state_m,x
 lda #0
 sta k_frac,x
 lda #32
 sta k_wait,x
 lda z_tmp
 sec
 sbc #1
 asl
 asl
 asl
 asl
 tay
 lda #0
 jmp k_points
@done:
 rts
.endproc
.proc k_publish
 lda f_scroll
 clc
 adc k_x
 sta z_pos
 lda f_scroll+1
 adc #0
 sta z_pos+1
 jsr water_scale
 lda z_pos
 sta world
 lda z_pos+1
 sta world+1
 ldx #0
@actor:
 lda k_mx,x
 clc
 adc f_scroll
 sta z_pos
 lda f_scroll+1
 adc #0
 sta z_pos+1
 lda k_mx,x
 cmp #242
 bcc :+
 dec z_pos+1
:
 jsr water_scale
 ; Charlie is drawn centered on world, while monkeys use a left edge.
 ; Source collision centers are hero X+19 and monkey X+13. At 3/4 scale
 ; their six-source-pixel difference plus half the 12-pixel monkey is
 ; 10.5 screen pixels. Round to 11 so artwork meets before collision.
 lda z_pos
 sec
 sbc #11
 sta hazard_xlo,x
 lda z_pos+1
 sbc #0
 sta hazard_xhi,x
 inx
 cpx #7
 bne @actor
 rts
.endproc
.include "tightrope-schedules.inc"

.proc k_lose
 lda #0
 sta k_fire_pending
 jmp k_hurt
.endproc
.segment "TOPCLIP"
k_points = fidelity_points
.proc k_hurt
 lda jump_pixels
 pha
 jsr hurt
 pla
 sta jump_pixels
 lda #$3E
 sta $D500
 rts
.endproc
.proc k_finish
 sed
 clc
 lda bonus
 adc #1
 sta bonus
 lda bonus+1
 adc #0
 sta bonus+1
 cld
 jsr finish_act
 lda #$3E
 sta $D500
 rts
.endproc
.segment "FIDELITY"
