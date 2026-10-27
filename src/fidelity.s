; Native 6502 translations of the arcade's takeoff and object rules.
; Horizontal coordinates retain the Act 1 3/4 scale, with 8 fractional bits.
; All frame integrators run at the simulation rate, independent of rendering.
.proc fidelity_init
 lda #0
 ; Resume rebuilds the page from the course origin. Keeping the restored
 ; high byte here would add the old position to the page offset twice.
 sta world+1
 ldx #$13
@clear:
 sta f_direction,x
 dex
 bpl @clear
 ldx #15
@objects:
 sta f_object_fraction,x
 sta f_active,x
 sta f_object_speed,x
 sta f_serial,x
 sta monkey_jump,x
 sta passed,x
 lda #$FF
 sta ball_lo,x
 sta hazard_xlo,x
 lda #$7F
 sta ball_hi,x
 sta hazard_xhi,x
 lda #0
 dex
 bpl @objects
 lda rank
 sta f_rank
 tax
 lda monkey_schedule_lo,x
 sta f_sequence
 lda monkey_schedule_hi,x
 sta f_sequence+1
 lda #<1465
 sta stage_end
 lda #>1465
 sta stage_end+1
 lda act
 cmp #2
 beq @trampoline
 cmp #3
 beq @ball
 lda #48
 sta world
 rts
@trampoline:
 jmp tramp_init_entry
@ball:
 lda #60
 sta world
 sta ball_lo
 lda #0
 sta ball_hi
 lda #1
 sta f_active
 rts
.endproc

.proc fidelity_step
 lda world
 sta f_previous
 lda world+1
 sta f_previous+1
 lda jumping
 bne @motion
 lda z_joy
 and #12
 cmp #12
 bne :+
 lda #0
:
 sta f_direction
 lda z_fire
 beq @motion
 lda #1
 sta jumping
 sta sound_fx
 lda #0
 sta f_phase
 sta sound_age
 sta monkey_seen
 lda act
 cmp #3
 bne @motion
 ldx current_ball
 lda f_direction
 sta f_object_speed,x
@motion:
 jsr fidelity_move
 lda act
 cmp #1
 bne @balls
 jsr fidelity_monkeys
 jmp @arc
@balls:
 jsr fidelity_balls
@arc:
 lda jumping
 beq @ground
 inc f_phase
 ldx f_phase
 lda arcade_jump,x
 sta jump_pixels
 lda #29
 sec
 sbc f_phase
 sta velocity
 cpx #ARCADE_JUMP_END
 bcc @collision
 lda #0
 sta jumping
 sta jump_pixels
 sta velocity
 lda act
 cmp #3
 jeq fidelity_ball_land
 jsr fidelity_reward
@ground:
 ; Waiting on the rope is safe until an actual monkey reaches Charlie or
 ; the visible course countdown expires. Never kill him for neutral input.
 lda act
 cmp #1
 beq @collision
 lda f_direction
 bne @active
 inc f_idle
 lda f_idle
 cmp #192
 jcs hurt
 jmp @collision
@active:
 lda #0
 sta f_idle
@collision:
 lda act
 cmp #1
 bne @ball_finish
 ; Arcade walking continues underneath the raised deck and stops at X=192.
 ; Touching the goal's side is not itself a death. Monkeys remain dangerous.
 lda world
 cmp #<1489
 lda world+1
 sbc #>1489
 bcc :+
 lda #<1489
 sta world
 lda #>1489
 sta world+1
:
 lda jumping
 beq @hazards
 lda velocity
 bpl @hazards
 lda jump_pixels
 cmp #20
 bcs @hazards
 cmp #16
 bcc @hazards ; A late approach underneath the lip must not snap upward.
 lda world
 cmp #<1459 ; A shoe may overlap the near lip by six scaled pixels.
 lda world+1
 sbc #>1459
 bcc @hazards
 lda #0
 sta jumping
 lda #19
 sta jump_pixels
 ; Settle the landing so both shoes stand on the raised deck.
 lda world
 cmp #<1473
 bcs :+
 lda #<1473
 sta world
:
 jmp finish_act
@ball_finish:
 lda world
 cmp stage_end
 lda world+1
 sbc stage_end+1
 bcc @hazards
 lda jumping
 beq @edge
 lda velocity
 bpl @hazards
 lda jump_pixels
 cmp #6
 bcs @hazards
 lda #0
 sta jumping
 lda #0
 sta jump_pixels
 jmp finish_act
@edge:
 ; Walking off the apparatus is a fall, never an automatic clear.
 jmp hurt
@hazards:
 lda grace
 bne @done
 lda act
 cmp #1
 jeq fidelity_monkey_collision
 lda jumping
 bne @done
 ldx #4
@touch:
 cpx current_ball
 beq @next
 lda f_active,x
 beq @next
 ; Compare the two rendered ball centres. Charlie can be offset from his
 ; support for several ticks after landing; that offset is not ball contact.
 ldy current_ball
 lda ball_lo,y
 sec
 sbc ball_lo,x
 sta z_pos
 lda ball_hi,y
 sbc ball_hi,x
 sta z_pos+1
 bpl :+
 lda z_pos
 eor #255
 clc
 adc #1
 sta z_pos
 lda z_pos+1
 eor #255
 adc #0
 sta z_pos+1
:
 lda z_pos+1
 bne @next
 lda z_pos
 ; The prepared silhouette spans 14 colour pixels, including both edges.
 cmp #15
 jcc hurt
@next:
 dex
 bpl @touch
@done:
 rts
.endproc

.proc fidelity_move
 lda #0
 sta f_velocity
 sta f_velocity+1
 sta f_moved
 lda f_direction
 cmp #8
 beq @right
 cmp #4
 bne @apply
 lda world+1
 bne @left
 lda world
 cmp #61
 bcc @apply
@left:
 lda #$40
 ldx act
 cpx #1
 bne :+
 lda #$A0
:
 sta f_velocity
 lda #255
 sta f_velocity+1
 lda act
 cmp #1
 bne @decrement
 lda scene_clock
 and #1
 bne @apply
@decrement:
 lda f_scroll
 bne :+
 dec f_scroll+1
:
 dec f_scroll
 jmp @apply
@right:
 lda #$C0
 sta f_velocity
 inc f_scroll
 bne :+
 inc f_scroll+1
:
 lda #1
 sta f_moved
@apply:
 lda f_fraction
 clc
 adc f_velocity
 sta f_fraction
 lda world
 adc f_velocity+1
 sta world
 lda f_velocity+1
 bpl :+
 lda #255
 bne @high
:
 lda #0
@high:
 adc world+1
 sta world+1
 rts
.endproc

.proc fidelity_monkeys
 ldx #6
@move:
 lda f_active,x
 jeq @next
 lda #144
 sta z_tmp
 lda #0
 sta z_tmp2
 lda monkey_type,x
 jeq @brown
 lda #32
 sta z_tmp
 inc z_tmp2
 lda f_direction
 cmp #4
 bne @leap
 lda #192
 sta z_tmp
 dec z_tmp2
@leap:
 lda f_object_speed,x
 beq @seek
 inc f_object_speed,x
 ldy f_object_speed,x
 lda arcade_monkey_jump,y
 sta monkey_jump,x
 cpy #ARCADE_MONKEY_END
 bcc @air_speed
 lda #0
 sta f_object_speed,x
 sta monkey_jump,x
@air_speed:
 lda #192
 sta z_tmp
 lda #0
 sta z_tmp2
 lda f_direction
 cmp #8
 bne @subtract
 lda #48
 sta z_tmp
 bne @subtract
@seek:
 lda hazard_xlo,x
 sec
 sbc world
 sta z_pos
 lda hazard_xhi,x
 sbc world+1
 bne @subtract
 lda z_pos
 cmp #120
 bcs @subtract
 ldy #3
@brown_near:
 lda f_active,y
 beq @other
 lda hazard_xlo,x
 sec
 sbc hazard_xlo,y
 sta z_pos
 lda hazard_xhi,x
 sbc hazard_xhi,y
 bne @other
 lda z_pos
 cmp #18
 bcs @other
 lda #1
 sta f_object_speed,x
 tya
 sta monkey_under,x
 inc leap_events
 bne @subtract
@other:
 dey
 bpl @brown_near
 jmp @subtract
@brown:
 lda f_direction
 cmp #8
 bne @subtract
 lda #48
 sta z_tmp
@subtract:
 lda f_object_fraction,x
 sec
 sbc z_tmp
 sta f_object_fraction,x
 lda hazard_xlo,x
 sbc z_tmp2
 sta hazard_xlo,x
 lda hazard_xhi,x
 sbc #0
 sta hazard_xhi,x
 ; Retire off the left edge; the fixed seven-slot pool bounds all work.
 lda world
 sec
 sbc hazard_xlo,x
 sta z_pos
 lda world+1
 sbc hazard_xhi,x
 bmi @next
 bne @retire
 lda z_pos
 cmp #64
 bcc @next
@retire:
 lda #0
 sta f_active,x
 lda #$7F
 sta hazard_xhi,x
@next:
 dex
 jpl @move
 ; Normal arcade schedule, including its close brown/pink groups.
 lda f_scroll+1
 cmp #7
 bcs @done
 lda f_direction
 cmp #4
 beq @done
 lda f_counter
 sta z_tmp
 lda f_direction
 bne @increment
 lda scene_clock
 and #3
 beq @schedule
@increment:
 ; A small first-course breathing space; later schedules remain exact.
 lda rank
 bne :+
 lda scene_clock
 and #15
 beq @schedule
:
 inc f_counter
@schedule:
 lda f_sequence
 sta z_ptr
 lda f_sequence+1
 sta z_ptr+1
 ldy #0
 lda (z_ptr),y
 cmp z_tmp
 bne @done
 iny
 lda (z_ptr),y
 sta z_kind
 ldx #0
 beq @pool
@pink_pool:
 ldx #4
@pool:
 lda z_kind
 beq @slot
 cpx #0
 beq @pink_pool
@slot:
 lda f_active,x
 beq @spawn
 inx
 cpx #7
 bcs @done
 cpx #4
 bne @slot
 lda z_kind
 bne @slot
@done:
 rts
@spawn:
 lda #1
 sta f_active,x
 lda #0
 sta passed,x
 sta f_object_speed,x
 sta monkey_jump,x
 sta f_object_fraction,x
 lda z_kind
 sta monkey_type,x
 lda world
 clc
 adc #133
 sta hazard_xlo,x
 lda world+1
 adc #0
 sta hazard_xhi,x
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
 rts
.endproc

.proc fidelity_monkey_collision
 ldx #6
@check:
 lda f_active,x
 beq @next
 lda hazard_xlo,x
 sta z_pos
 lda hazard_xhi,x
 sta z_pos+1
 jsr distance_to_player
 lda z_pos+1
 bne @next
 lda z_pos
 cmp #10
 bcs @next
 lda jump_pixels
 sec
 sbc monkey_jump,x
 bpl :+
 eor #255
 clc
 adc #1
:
 cmp #16
 bcs @pass
 clc
 adc z_pos
 cmp #18
 jcc hurt
@pass:
 lda passed,x
 bne @next
 lda #1
 sta passed,x
 lda monkey_type,x
 clc
 adc #1
 ora monkey_seen
 sta monkey_seen
@next:
 dex
 bpl @check
 rts
.endproc

.proc fidelity_balls
 ldx #4
@move:
 lda f_active,x
 jeq @next
 cpx current_ball
 bne @free
 lda jumping
 bne @free
 ; A newly caught ball converges on Charlie at one arcade pixel/frame.
 ; Preserve the landing offset instead of snapping it under his feet.
 lda ball_lo,x
 sec
 sbc f_previous
 sta z_pos
 lda ball_hi,x
 sbc f_previous+1
 sta z_pos+1
 lda z_pos
 clc
 adc world
 sta ball_lo,x
 lda z_pos+1
 adc world+1
 sta ball_hi,x
 lda z_pos+1
 bmi @approach_right
 ora z_pos
 jeq @next
 lda #192
 sta z_tmp
 jmp @drift
@approach_right:
 lda #0
 sta f_object_fraction,x
 lda ball_lo,x
 clc
 adc #1
 sta ball_lo,x
 bcc @next
 inc ball_hi,x
 jmp @next
@free:
 lda #96
 sta z_tmp
 lda f_object_speed,x
 beq @drift
 cmp #4
 beq @backward
 lda #192
 sta z_tmp
@drift:
 lda f_object_fraction,x
 sec
 sbc z_tmp
 sta f_object_fraction,x
 lda ball_lo,x
 sbc #0
 sta ball_lo,x
 lda ball_hi,x
 sbc #0
 sta ball_hi,x
 jmp @retire_test
@backward:
 lda f_object_fraction,x
 clc
 adc #192
 sta f_object_fraction,x
 lda ball_lo,x
 adc #0
 sta ball_lo,x
 bcc @retire_test
 inc ball_hi,x
@retire_test:
 lda world
 sec
 sbc ball_lo,x
 sta z_pos
 lda world+1
 sbc ball_hi,x
 bmi @next
 bne @retire
 lda z_pos
 cmp #80
 bcc @next
@retire:
 lda #0
 sta f_active,x
 lda #$7F
 sta ball_hi,x
@next:
 dex
 jpl @move
 lda f_scroll+1
 cmp #7
 bcs @done
 lda f_moved
 beq @done
 ; Five exact negative-scroll spawn bytes per arcade page.
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
 ldx f_rank
 lda ball_rank_offset,x
 clc
 adc z_tmp2
 tay
 ldx #5
@find:
 lda ball_schedule,y
 beq @done
 cmp z_tmp
 beq @spawn
 iny
 dex
 bne @find
@done:
 rts
@spawn:
 ; Match arcade's no-overlap exclusion at the entry edge.
 ldx #4
@space:
 lda f_active,x
 beq @space_next
 lda ball_lo,x
 sec
 sbc world
 sta z_pos
 lda ball_hi,x
 sbc world+1
 bne @space_next
 lda z_pos
 cmp #94
 bcs @done
@space_next:
 dex
 bpl @space
 ldx #4
@slot:
 lda f_active,x
 beq @new
 dex
 bpl @slot
 rts
@new:
 lda #1
 sta f_active,x
 lda #0
 sta f_object_speed,x
 sta f_object_fraction,x
 lda world
 clc
 adc #121
 sta ball_lo,x
 lda world+1
 adc #0
 sta ball_hi,x
 inc f_spawned
 lda f_spawned
 sta f_serial,x
 rts
.endproc
ball_rank_offset: .byte 0,45,90,135,180,180

.proc fidelity_ball_land
 lda world
 cmp stage_end
 lda world+1
 sbc stage_end+1
 bcc @balls
 jmp finish_act
@balls:
 ldx #4
@find:
 lda f_active,x
 jeq @next
 lda #6
 ldy f_direction
 cpy #4
 bne :+
 lda #253
:
 sta z_tmp
 lda ball_lo,x
 sec
 sbc z_tmp
 sta z_pos
 lda z_tmp
 bpl :+
 lda #255
 bne @offset
:
 lda #0
@offset:
 sta z_tmp
 lda ball_hi,x
 sbc z_tmp
 sta z_pos+1
 jsr distance_to_player
 lda z_pos+1
 bne @next
 lda z_pos
 cmp #13
 bcs @next
 stx mech_index
 cpx current_ball
 beq @land
 lda f_serial,x
 sec
 sbc f_last_serial
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
@land:
 stx current_ball
 lda f_serial,x
 sta f_last_serial
 lda #0
 sta f_object_speed,x
 sta f_idle
 inc f_ball_count
 lda f_ball_count
 cmp #8
 beq @harder
 cmp #16
 bne @land_done
@harder:
 lda f_rank
 cmp #4
 bcs @land_done
 inc f_rank
@land_done:
 rts
@next:
 dex
 jpl @find
 jmp hurt
.endproc
.include "fidelity-tables.inc"

.proc fidelity_clear_text
 lda #<clear_glyphs
 sta z_src
 lda #>clear_glyphs
 sta z_src+1
 lda #0
 sta z_index
 lda free_glyph
 cmp #111
 bcc :+
 rts
:
 sta z_new
 lda act
 bne @cell
 ldx back
 lda z_new
 cmp clear_text_cache,x
 beq @done ; Nothing in the lion celebration touches this top row/font.
 sta clear_text_cache,x
@cell:
 lda z_new
 asl
 asl
 asl
 sta z_glyph
 lda z_new
 lsr
 lsr
 lsr
 lsr
 lsr
 ora z_fonts
 sta z_glyph+1
 ldy #7
@pixels:
 lda (z_src),y
 sta (z_glyph),y
 dey
 bpl @pixels
@map:
 lda #<(1*40+7)
 clc
 adc z_index
 tay
 lda z_new
 ora #128
 sta (z_map),y
 lda act
 beq @advance ; Keep Act 1's static text until the next stage load.
 tya
 ldy z_num
 sta (z_dirtylo),y
 lda #0
 sta (z_dirtyhi),y
 inc z_num
@advance:
 lda z_src
 clc
 adc #8
 sta z_src
 bcc :+
 inc z_src+1
:
 inc z_new
 inc z_index
 lda z_index
 cmp #8
 bne :+
 lda z_src
 clc
 adc #64
 sta z_src
 bcc @gap
 inc z_src+1
@gap:
 lda #16
 sta z_index
:
 lda z_index
 cmp #26
 bne @cell
 lda z_new
 sta free_glyph
@done:
 rts
.endproc
.include "fidelity-text.inc"

.proc fidelity_resume
 lda world
 sec
 sbc #60
 sta resume_world
 lda world+1
 sbc #0
 ; The shared checkpoint saver rounds down to 64 pixels. An early death
 ; can therefore restore zero, before this course's 60-pixel page origin.
 ; Saturate the subtraction instead of wrapping to a far-off course page.
 bcs :+
 lda #0
 sta resume_world
:
 sta resume_world+1
 jsr fidelity_init
 lda #0
 sta grace
 sta scene_clock
 sta scene_clock+1
 sta current_ball
@page:
 lda resume_world
 cmp #192
 lda resume_world+1
 sbc #0
 bcc @ready
 lda resume_world
 sec
 sbc #192
 sta resume_world
 lda resume_world+1
 sbc #0
 sta resume_world+1
 inc f_scroll+1
 lda world
 clc
 adc #192
 sta world
 bcc @page
 inc world+1
 jmp @page
@ready:
 lda world
 sta ball_lo
 lda world+1
 sta ball_hi
 lda act
 cmp #1
 bne @done
 lda f_rank
 asl
 asl
 asl
 clc
 adc f_rank
 adc f_scroll+1
 tax
 lda monkey_page_lo,x
 sta f_sequence
 lda monkey_page_hi,x
 sta f_sequence+1
@done:
 inc checkpoint_restores
 jmp update_camera
.endproc
monkey_page_lo: .byte <(monkey_schedule+0),<(monkey_schedule+0),<(monkey_schedule+10),<(monkey_schedule+18),<(monkey_schedule+26),<(monkey_schedule+36),<(monkey_schedule+44),<(monkey_schedule+52),<(monkey_schedule+60),<(monkey_schedule+66),<(monkey_schedule+66),<(monkey_schedule+74),<(monkey_schedule+82),<(monkey_schedule+90),<(monkey_schedule+98),<(monkey_schedule+106),<(monkey_schedule+114),<(monkey_schedule+122),<(monkey_schedule+130),<(monkey_schedule+130),<(monkey_schedule+138),<(monkey_schedule+148),<(monkey_schedule+156),<(monkey_schedule+164),<(monkey_schedule+174),<(monkey_schedule+182),<(monkey_schedule+190),<(monkey_schedule+198),<(monkey_schedule+198),<(monkey_schedule+206),<(monkey_schedule+214),<(monkey_schedule+222),<(monkey_schedule+230),<(monkey_schedule+238),<(monkey_schedule+246),<(monkey_schedule+254),<(monkey_schedule+262),<(monkey_schedule+262),<(monkey_schedule+270),<(monkey_schedule+278),<(monkey_schedule+286),<(monkey_schedule+292),<(monkey_schedule+300),<(monkey_schedule+310),<(monkey_schedule+316),<(monkey_schedule+324),<(monkey_schedule+324),<(monkey_schedule+334),<(monkey_schedule+342),<(monkey_schedule+350),<(monkey_schedule+358),<(monkey_schedule+366),<(monkey_schedule+374),<(monkey_schedule+384)
monkey_page_hi: .byte >(monkey_schedule+0),>(monkey_schedule+0),>(monkey_schedule+10),>(monkey_schedule+18),>(monkey_schedule+26),>(monkey_schedule+36),>(monkey_schedule+44),>(monkey_schedule+52),>(monkey_schedule+60),>(monkey_schedule+66),>(monkey_schedule+66),>(monkey_schedule+74),>(monkey_schedule+82),>(monkey_schedule+90),>(monkey_schedule+98),>(monkey_schedule+106),>(monkey_schedule+114),>(monkey_schedule+122),>(monkey_schedule+130),>(monkey_schedule+130),>(monkey_schedule+138),>(monkey_schedule+148),>(monkey_schedule+156),>(monkey_schedule+164),>(monkey_schedule+174),>(monkey_schedule+182),>(monkey_schedule+190),>(monkey_schedule+198),>(monkey_schedule+198),>(monkey_schedule+206),>(monkey_schedule+214),>(monkey_schedule+222),>(monkey_schedule+230),>(monkey_schedule+238),>(monkey_schedule+246),>(monkey_schedule+254),>(monkey_schedule+262),>(monkey_schedule+262),>(monkey_schedule+270),>(monkey_schedule+278),>(monkey_schedule+286),>(monkey_schedule+292),>(monkey_schedule+300),>(monkey_schedule+310),>(monkey_schedule+316),>(monkey_schedule+324),>(monkey_schedule+324),>(monkey_schedule+334),>(monkey_schedule+342),>(monkey_schedule+350),>(monkey_schedule+358),>(monkey_schedule+366),>(monkey_schedule+374),>(monkey_schedule+384)



; Horse: original forward speed freezes on takeoff and is sampled again on
; every spring contact. The spring generator runs before camera movement.
.proc fidelity_horse_init
 lda #0
 sta f_fraction
 sta f_counter
 sta h_slot
 sta h_opening
 sta f_horse_h
 sta f_horse_h+1
 lda #255
 sta f_scroll
 sta f_scroll+1
 lda #8
 sta f_idle
 lda #47
 sta world
 lda #64
 sta f_fraction
 lda #<3690
 sta stage_end
 lda #>3690
 sta stage_end+1
 ldx #15
 lda #0
@clear:
 sta h_width,x
 dex
 bpl @clear
 rts
.endproc
.proc fidelity_horse_input
 lda z_joy
 and #12
 sta f_direction
 lda #2
 ldx f_direction
 cpx #8
 bne :+
 lda #3
:
 cpx #4
 bne :+
 lda #1
:
 sta h_speed
 rts
.endproc
.proc fidelity_horse_step
 jsr fidelity_horse_tick
 lda jumping
 bne @move
 jsr fidelity_horse_input
 lda z_fire
 beq @move
 jsr fidelity_horse_launch
 lda #1
 sta jumping
 sta sound_fx
 lda #0
 sta spring_pending
 sta sound_age
@move:
 jsr fidelity_horse_move
 jsr fidelity_horse_gravity
 ; The visible podium starts at 3664 and is 48 pixels wide. The horse
 ; reaches its face; there is no invisible killing gap ahead of it.
 lda world
 sec
 sbc #<3664
 sta z_tmp
 lda world+1
 sbc #>3664
 bmi @collision
 bne @fell
 lda z_tmp
 cmp #48
 bcs @beyond
 lda jump_pixels
 cmp #28
 bcs @collision
 lda jumping
 beq @fell
 lda velocity
 bpl @fell
 lda previous_height
 cmp #27
 bcc @fell
 lda #27
 sta jump_pixels
 lda #0
 sta jumping
 sta velocity
 lda #1
 sta horse_finish
 jmp finish_act
@beyond:
 lda jumping
 bne @collision
@fell:
 jmp hurt
@collision:
@springs:
 lda #255
 sta spring_hit
 ldx #15
@next:
 lda h_width,x
 beq @skip
 lda hazard_xlo,x
 sta z_pos
 lda hazard_xhi,x
 sta z_pos+1
 jsr distance_to_player
 lda z_pos+1
 bne @skip
 lda h_width,x
 asl
 clc
 adc h_width,x
 clc
 adc #2
 cmp z_pos
 bcc @skip
 lda #152
 sec
 sbc jump_pixels
 sta z_body
 cmp horse_y,x
 bcc @skip
 sec
 sbc #32
 cmp horse_y,x
 bcs @skip
 lda velocity
 bpl @crash
 lda #152
 sec
 sbc previous_height
 cmp horse_y,x
 ; A descending foot exactly level with the deck is a top contact too.
 ; Rejecting equality kills edge landings after the horizontal step enters
 ; the spring, even though Charlie's visible feet reached its top surface.
 beq @land_on_spring
 bcs @crash
@land_on_spring:
 ; Classify all overlapping contacts against the incoming motion. Bouncing
 ; inside this loop made the next valid deck appear to be an underside hit.
 ldy spring_hit
 bmi @remember
 lda horse_y,x
 cmp horse_y,y
 bcs @skip
@remember:
 stx spring_hit
 jmp @skip
@crash:
 jmp hurt
@skip:
 dex
 jpl @next
 ldx spring_hit
 bmi @done
 lda #152
 sec
 sbc horse_y,x
 sta jump_pixels
 jsr fidelity_horse_bounce
 jsr fidelity_horse_input
 ldx spring_hit
 jsr fidelity_spring_points
 lda #1
 sta jumping
 sta sound_fx
 lda #0
 sta sound_age
@done:
 rts
.endproc
.proc fidelity_horse_move
 lda f_scroll
 clc
 adc h_speed
 sta f_scroll
 bcc :+
 inc f_scroll+1
:
 lda f_idle
 sec
 sbc h_speed
 sta f_idle
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
.proc fidelity_horse_launch
 lda #0
 sta f_horse_v
 sta f_horse_h
 sta f_horse_h+1
 lda #3
 sta f_horse_v+1
 rts
.endproc
.proc fidelity_horse_gravity
 lda jump_pixels
 sta previous_height
 lda jumping
 beq @zero
 lda f_horse_v
 sec
 sbc #$18
 sta f_horse_v
 lda f_horse_v+1
 sbc #0
 sta f_horse_v+1
 sta velocity
 lda f_horse_h
 clc
 adc f_horse_v
 sta f_horse_h
 lda f_horse_h+1
 adc f_horse_v+1
 sta f_horse_h+1
 bmi @land
 sta jump_pixels
 rts
@land:
 lda #0
 sta jumping
 sta velocity
@zero:
 lda #0
 sta jump_pixels
 sta height
 sta height+1
 rts
.endproc
.proc fidelity_horse_bounce
 lda #$18
 sec
 sbc f_horse_v
 sta f_horse_v
 lda #0
 sbc f_horse_v+1
 sta f_horse_v+1
 sta velocity
 lda jump_pixels
 sta f_horse_h+1
 lda #0
 sta f_horse_h
 rts
.endproc
.proc fidelity_horse_tick
 lda h_opening
 cmp #1
 bne @spawn
 lda f_scroll
 sec
 sbc h_first_spawn
 sta z_tmp
 lda f_scroll+1
 sbc h_first_spawn+1
 beq @spawn
 cmp #1
 bne @closed
 lda z_tmp
 cmp #41
 bcc @spawn
@closed:
 inc h_opening
@spawn:
 lda f_idle
 cmp #3
 jcs @done
 lda f_scroll+1
 cmp #17
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
 ldx h_slot
 lda h_opening
 beq @first
 cmp #1
 bne @normal
 lda #7
 sta h_width,x
 lda #144
 sta horse_y,x
 jmp @position
@first:
 inc h_opening
 lda f_scroll
 sta h_first_spawn
 lda f_scroll+1
 sta h_first_spawn+1
@normal:
 lda h_width_table,y
 sta h_width,x
 lda h_height_table,y
 sta horse_y,x
@position:
 lda h_gap_table,y
 sta f_idle
 lda f_counter
 bne :+
 lda #52
 sta f_idle
:
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
 ; Exact 3/4 horizontal conversion, with the displayed pixel floored.
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
 inc f_counter
 inx
 txa
 and #15
 sta h_slot
@done:
 rts
.endproc
; Old entry points remain callable by compatibility test fixtures only.
.proc fidelity_rope_record
 rts
.endproc
.proc fidelity_rope_move
 rts
.endproc

h_width_table: .byte 7,7,7,7,7,7,7,7,7,6,7,6,7,6,7,6,7,6,5,6,7,7,6,5,7,6,7,5,6,6,4,6,6,5,6,4,7,5,6,4,6,4,3,7,4,5,7,4,6,3,5,6,4,4,5,4,5,3,5,4,4,4,6,3,5,4,3,4,3,4,2,4,4,3,4,3,3,4,2,3,3,4,3,2,5,2,3,2,2,2,3,3,2,3,2,3,2,2,2,2,2,2,2,2

h_height_table: .byte 144,144,144,144,144,144,144,144,144,128,144,144,144,128,144,144,144,136,144,136,144,128,136,136,144,144,136,144,128,136,144,136,136,128,136,128,144,144,128,136,136,136,128,144,128,136,144,144,136,128,136,136,128,136,144,136,136,136,128,128,136,128,136,136,144,128,136,136,128,136,128,136,136,144,128,136,128,144,136,136,136,128,136,136,128,136,128,144,128,144,136,144,144,128,128,136,144,128,128,144,128,136,128,144

h_gap_table: .byte 80,248,80,248,80,248,80,248,80,248,80,248,80,248,80,248,80,224,80,232,80,216,80,240,80,208,80,232,80,216,80,224,80,200,80,184,80,224,80,176,80,216,80,224,80,176,80,200,80,176,80,152,80,232,80,200,80,224,80,120,80,128,80,176,80,152,80,120,80,184,80,104,80,96,80,200,80,208,80,152,80,128,80,80,80,184,80,152,80,176,80,72,80,128,80,104,80,108,80,132,80,84,80,132

; Rebuild a horse checkpoint in complete 256-source-pixel (192 Atari-pixel)
; pages. Leave a full approach before the final gap and reset airborne state.
; Replaying the generator only affects stage setup, never active play timing.
.proc fidelity_horse_resume
 lda world
 sec
 sbc #47
 sta resume_world
 lda world+1
 sbc #0
 bcs :+
 lda #0
 sta resume_world
:
 sta resume_world+1
 lda #0
 sta world+1
 jsr fidelity_horse_init
 lda #2
 sta h_speed
 lda #0
 sta f_horse_v
 sta f_horse_v+1
 sta jumping
 sta velocity
 sta jump_pixels
 sta scene_clock
 sta scene_clock+1
 sta grace
 ; One page of approach is retained behind the failed performance.
 lda resume_world
 sec
 sbc #192
 sta resume_world
 lda resume_world+1
 sbc #0
 bcs :+
 lda #0
 sta resume_world
:
 sta resume_world+1
@page:
 lda resume_world
 cmp #192
 lda resume_world+1
 sbc #0
 bcc @ready
 lda resume_world
 sec
 sbc #192
 sta resume_world
 lda resume_world+1
 sbc #0
 sta resume_world+1
 lda #128
 sta resume_steps
@advance:
 jsr fidelity_horse_tick
 jsr fidelity_horse_move
 dec resume_steps
 bne @advance
 jmp @page
@ready:
 ; Discard old objects crossing the fresh start. Newly scheduled apparatus
 ; begins ahead of the horse, giving the player a visible approach to jump.
 lda #0
 ldx #15
@clear:
 sta h_width,x
 dex
 bpl @clear
 lda #8
 sta f_idle
 inc checkpoint_restores
 jmp update_camera
.endproc
