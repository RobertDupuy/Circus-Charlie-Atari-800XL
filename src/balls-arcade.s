; Source-space actor update order from arcade $9976..$A0AA.
; Slot zero is the support; handoffs swap the complete actor with a free slot.
.proc b_init
 lda #0
 sta f_scroll
 sta f_scroll+1
 sta current_ball
 sta timer_div
 sta r_clock_fraction
 sta r_clock_fraction+1
 sta r_clock_fraction+2
 sta b_idle_spawn
 sta f_ball_count
 sta f_idle
 ldx #4
@clear:
 sta f_active,x
 sta f_object_speed,x
 sta f_object_fraction,x
 sta b_align,x
 dex
 bpl @clear
 lda #80
 sta b_hero_x
 sta b_x
 lda #1
 sta f_active
 sta b_first
 lda #5
 sta f_object_speed
 lda #$10
 sta bonus
 lda #$64
 sta bonus+1
 lda #<1465
 sta stage_end
 lda #>1465
 sta stage_end+1
 jsr apparatus_clock_reset
 jmp b_publish
.endproc

.proc b_step
 lda b_first
 beq :+
 dec b_first
 jsr b_spawn
 inc f_idle
 lda #1
 sta f_object_speed
 jmp b_publish
:
 jsr b_contact
 lda mode
 cmp #2
 jne @done
 jsr b_spawn
 ldx #1
@free:
 lda f_active,x
 beq @next
 lda f_object_speed,x
 cmp #2
 beq @retire
 bcs @fast
 lda f_direction
 cmp #4
 beq @left
 lda f_object_speed,x
 beq @right
 lda #0
 sta f_object_speed,x
 sta f_object_fraction,x
 beq @next
@right:
 lda f_object_fraction,x
 eor #128
 sta f_object_fraction,x
 bne :+
 dec b_x,x
:
 lda f_direction
 beq @retire_test
 jsr b_at_end
 bcs @retire_test
 dec b_x,x
 jmp @retire_test
@left:
 lda f_object_speed,x
 bne :+
 inc f_object_speed,x
 bne @next
:
 lda f_object_fraction,x
 eor #128
 sta f_object_fraction,x
 bne @retire_test
 inc b_x,x
@retire_test:
 lda b_x,x
 cmp #242
 beq @mark
 cmp #243
 bne @next
@mark:
 lda #2
 sta f_object_speed,x
 bne @next
@retire:
 lda #0
 sta f_active,x
 beq @next
@fast:
 jsr b_fast
@next:
 inx
 cpx #5
 bne @free
 lda jumping
 bne @motion
 lda f_direction
 sta f_previous
 lda z_joy
 and #12
 cmp #12
 bne :+
 lda #0
:
 sta f_direction
 lda z_fire
 beq @idle
 lda #1
 sta jumping
 sta sound_fx
 lda #0
 sta f_phase
 sta sound_age
@idle:
 lda f_direction
 ora jumping
 bne @active
 lda f_previous
 bne @active
 inc f_idle
 lda f_idle
 cmp #192
 jeq fidelity_hurt
 bne @motion
@active:
 lda #0
 sta f_idle
@motion:
 lda f_direction
 cmp #8
 beq @right_move
 cmp #4
 bne @arc
 lda f_scroll
 ora f_scroll+1
 beq @arc
 jsr b_at_end
 bcc @scroll_left
 lda b_hero_x
 cmp #80
 beq @scroll_left
 dec b_hero_x
 jmp @arc
@scroll_left:
 lda f_scroll
 bne :+
 dec f_scroll+1
:
 dec f_scroll
 jmp @arc
@right_move:
 jsr b_at_end
 bcc @scroll_right
 lda b_hero_x
 cmp #224
 bcs @arc
 inc b_hero_x
 bne @arc
@scroll_right:
 inc f_scroll
 bne @arc
 inc f_scroll+1
@arc:
 lda jumping
 beq @support
 inc f_phase
 ldx f_phase
 lda arcade_jump,x
 sta jump_pixels
 lda #29
 sec
 sbc f_phase
 sta velocity
 cpx #57
 bcc @support
 lda #0
 sta jumping
 sta jump_pixels
 sta velocity
 jsr fidelity_ball_land
@support:
 ldx #0
 lda f_active
 jeq @publish
 lda f_object_speed
 cmp #5
 bne :+
 lda #1
 sta f_object_speed
 jne @publish
:
 cmp #3
 jcs @fast_support
 jsr b_at_end
 bcs @end_align
 lda b_align
 beq @center
 cmp #1
 bne @approach_right
 dec b_x
 jmp @aligned
@approach_right:
 inc b_x
@aligned:
 lda b_x
 cmp b_hero_x
 bne @direction
 lda #0
 sta b_align
 beq @direction
@center:
 lda b_hero_x
 sta b_x
 jmp @direction
@end_align:
 lda b_align
 beq @center
 cmp #1
 beq @end_ahead
 lda f_direction
 cmp #4
 beq @end_wait
 inc b_x
 lda b_x
 cmp b_hero_x
 beq @aligned
 jmp @approach_right
@end_ahead:
 lda f_direction
 cmp #8
 beq @end_wait
 dec b_x
 lda b_x
 cmp b_hero_x
 beq @aligned
 dec b_x
 jmp @aligned
@end_wait:
 lda b_x
 cmp b_hero_x
 beq @aligned
 jmp @direction
@direction:
 lda f_direction
 lsr
 lsr
 ldy jumping
 beq @state
 cmp #0
 beq @publish
 clc
 adc #2
@state:
 sta f_object_speed
 jmp @publish
@fast_support:
 jsr b_fast
@publish:
 lda f_clear_hold
 bne @finish
 jmp b_publish
@finish:
 jsr b_publish
 jmp k_finish
@done:
 rts
.endproc

.proc b_fast
 lda f_object_speed,x
 cmp #5
 beq done
 jcs b_rebound_motion
 cmp #3
 bne left
 inc b_x,x
 inc b_x,x
right_check:
 lda b_x,x
 cmp #240
 bcc done
 bcs retire
left:
 dec b_x,x
 dec b_x,x
left_check:
 lda b_x,x
 cmp #240
 bcc done
 cmp #242
 bcs done
retire:
 lda #0
 sta f_active,x
done:
 rts
.endproc

.proc b_spawn
 lda f_direction
 beq @idle
 cmp #4
 jeq @done
 jsr b_at_end
 jcs @done
 lda f_scroll
 eor #255
 clc
 adc #1
 sta z_tmp
 lda f_scroll+1
 ldx f_scroll
 beq :+
 clc
 adc #1
:
 sta z_tmp2
 asl
 asl
 clc
 adc z_tmp2
 sta z_tmp2
 lda f_ball_count
 cmp #20
 bcc @rank
 sec
 sbc #20
 lsr
 lsr
 clc
 adc #1
@rank:
 ; Below twenty catches, no progression increment.
 ldx f_ball_count
 cpx #20
 bcs :+
 lda #0
:
 clc
 adc rank
 cmp #5
 bcc :+
 lda #5
:
 tax
 lda ball_rank_offset,x
 clc
 adc #<ball_schedule
 sta z_rom
 lda #>ball_schedule
 adc #0
 sta z_rom+1
 ldy z_tmp2
 ldx #5
@find:
 lda (z_rom),y
 beq @done
 cmp z_tmp
 beq @space
 ; Original tables are descending lists. Stop at the first value below
 ; the current scroll byte; later bytes may belong to an adjacent list.
 bcc @done
 iny
 dex
 bne @find
@done:
 rts
@idle:
 ; The arcade's stack return exits the slot walk after one neutral visit.
 inc b_idle_spawn
 bne @done
@space:
 ldx #1
@check:
 lda f_active,x
 beq @check_next
 lda b_x,x
 cmp #20
 bcc @check_next
 lda #241
 sec
 sbc b_x,x
 bcs :+
 eor #255
 adc #1
:
 cmp #37
 bcc @done
@check_next:
 inx
 cpx #5
 bne @check
 ldx #1
@slot:
 lda f_active,x
 beq @new
 inx
 cpx #5
 bne @slot
 rts
@new:
 lda #1
 sta f_active,x
 lda #241
 sta b_x,x
 lda #0
 sta f_object_fraction,x
 sta f_object_speed,x
 sta b_align,x
 inc f_spawned
 lda f_spawned
 sta f_serial,x
 rts
.endproc
ball_rank_offset: .byte 0,45,90,135,180,225

.proc fidelity_ball_land
@balls:
 ldx #0
 lda f_direction
 beq @find
 inx
@find:
 lda f_active,x
 cmp #1
 jne @next
 lda b_hero_x
 ldy f_direction
 ; The approved vertical pose plants its feet at the support centre.
 ; Do not reach eight source pixels forward during a stationary jump:
 ; that caught the nearby incoming ball after the smaller balls touched.
 beq :+
 clc
 adc #8
 cpy #4
 bne :+
 sec
 sbc #12
:
 sta z_tmp
 lda b_x,x
 sec
 sbc z_tmp
 bcs :+
 eor #255
 adc #1
:
 cmp #18
 jcs @next
 stx mech_index
 cpx #0
 beq @land
 lda f_serial,x
 sec
 sbc f_serial
 cmp #2
 bcs @skip
 lda #0
 ldy #1
 bne @score
@skip:
 inc skip_awards
 lda #0
 ldy #5
@score:
 jsr fidelity_points
 ldx mech_index
 ; Swap actor identity as well as position: free states differ from support.
 .repeat 6,I
 .if I=0
  lda b_x
  ldy b_x,x
  sta b_x,x
  sty b_x
 .elseif I=1
  lda f_active
  ldy f_active,x
  sta f_active,x
  sty f_active
 .elseif I=2
  lda f_object_speed
  ldy f_object_speed,x
  sta f_object_speed,x
  sty f_object_speed
 .elseif I=3
  lda f_object_fraction
  ldy f_object_fraction,x
  sta f_object_fraction,x
  sty f_object_fraction
 .elseif I=4
  lda b_align
  ldy b_align,x
  sta b_align,x
  sty b_align
 .else
  lda f_serial
  ldy f_serial,x
  sta f_serial,x
  sty f_serial
 .endif
 .endrepeat
@land:
 lda b_x
 sec
 sbc b_hero_x
 beq :+
 bcc :+
 lda #1
:
 sta b_align
 inc f_ball_count
 lda #0
 sta f_idle
 rts
@next:
 inx
 cpx #5
 jne @find
@miss:
 jsr b_at_end
 bcc @fall
 lda b_hero_x
 cmp #160
 bcc @fall
 cmp #202
 bcs @fall
 lda #1
 sta f_clear_hold
 rts
@fall:
 jsr b_publish
 jmp fidelity_hurt
.endproc

.proc b_publish
 lda b_hero_x
 jsr @scale
 lda z_pos
 sta world
 lda z_pos+1
 sta world+1
 ldx #4
@ball:
 lda f_active,x
 bne @visible
 lda #255
 sta ball_lo,x
 lda #127
 sta ball_hi,x
 bne @next
@visible:
 lda b_x,x
 jsr @scale
 lda z_pos
 sta ball_lo,x
 lda z_pos+1
 sta ball_hi,x
@next:
 dex
 bpl @ball
 rts
@scale:
 clc
 adc f_scroll
 sta z_pos
 lda f_scroll+1
 adc #0
 sta z_pos+1
 ; floor(3 * source / 4), preserving the source rounding phase.
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
 rts
.endproc

.segment "GFX"
; Impact states 6/7 eject the old support at one source pixel per tick.
; A struck free ball uses twice that speed. State 5 is the stopped ball.
.proc b_rebound_motion
 cpx #0
 bne @free
 cmp #6
 bne @right
 dec b_x
 jmp b_fast::right_check
@free:
 cmp #6
 jne b_fast::left
 inc b_x,x
@right:
 inc b_x,x
 jmp b_fast::right_check
.endproc
.segment "MECHANICS"
.proc b_at_end
 lda f_scroll+1
 cmp #7
 bne @done
 lda f_scroll
 cmp #1
@done:
 rts
.endproc

.segment "FIDELITY"
