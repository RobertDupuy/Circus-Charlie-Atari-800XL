.export water_hazards
; MAME 0.285: collision, generator, actor motion, hero motion, timer.
; Physics remains in original integer coordinates; scale only for drawing.
.proc water_step
 jsr water_collision_entry
 lda mode
 cmp #2
 bne @done
 jsr water_actors
 inc f_phase
 lda f_direction
 beq @vertical
 cmp #4
 beq @left
 lda f_scroll+1
 cmp #7
 bcc :+
 lda f_scroll
 bne @right_edge
:
 inc f_scroll
 inc f_scroll
 bne @vertical
 inc f_scroll+1
 bne @vertical
@right_edge:
 lda w_hero_x
 cmp #192
 bcs @vertical
 inc w_hero_x
 inc w_hero_x
 bne @vertical
@left:
 lda f_scroll
 ora f_scroll+1
 beq @vertical
 lda f_scroll+1
 cmp #7
 bcc @scroll_left
 lda f_scroll
 beq @scroll_left
 lda w_hero_x
 cmp #80
 beq @scroll_left
 dec w_hero_x
 dec w_hero_x
 bne @vertical
@scroll_left:
 lda f_scroll
 bne :+
 dec f_scroll+1
:
 dec f_scroll
 dec f_scroll
@vertical:
 jsr water_vertical
 jsr water_publish
 jsr water_bag_spawn
@done:
 rts
.endproc

.proc water_vertical
 lda w_hero_phase
 cmp #1
 beq @up
 lda w_hero_y
 clc
 adc w_hero_v+1
 sta w_hero_y
 lda w_hero_v
 clc
 adc #$30
 sta w_hero_v
 lda w_hero_v+1
 adc #0
 sta w_hero_v+1
 cmp w_hero_limit+1
 bne @done
 lda w_hero_v
 cmp w_hero_limit
 bne @done
 lda w_hero_y
 clc
 adc w_hero_limit+1
 sta w_hero_y
 jmp water_land
@up:
 lda w_hero_y
 sec
 sbc w_hero_v+1
 sta w_hero_y
 lda bounce_count
 beq @decelerate
 lda w_hero_v+1
 beq @turn
@decelerate:
 lda w_hero_v
 sec
 sbc #$30
 sta w_hero_v
 lda w_hero_v+1
 sbc #0
 sta w_hero_v+1
 ora w_hero_v
 bne @prize
@turn:
 lda #0
 sta w_hero_v
 inc w_hero_phase
 lda bounce_count
 cmp #4
 bne @prize
 inc w_hero_y
 inc w_hero_y
 lda #8
 sta w_hero_state
 jmp water_hurt
@prize:
 jmp water_hazards
@done:
 rts
.endproc

.proc water_land
 lda f_direction
 cmp #8
 bne :+
 lda #$20
 ldy #0
 jsr add_points
:
 lda z_joy
 and #12
 cmp #12
 bne :+
 lda #0
:
 sta f_direction
 lda #0
 sta f_phase
 lda #1
 sta w_hero_phase
 lda f_direction
 bne @moving
 ldx bounce_count
 lda w_launch_lo,x
 sta w_hero_v
 sta w_hero_limit
 lda w_launch_hi,x
 sta w_hero_v+1
 sta w_hero_limit+1
 inc bounce_count
 jmp @goal
@moving:
 lda #0
 sta bounce_count
 lda #$20
 sta w_hero_v
 sta w_hero_limit
 lda #4
 sta w_hero_v+1
 sta w_hero_limit+1
 ; Right short arc at original scroll $xx48..57; left at $xxF8..07.
 lda #0
 sec
 sbc f_scroll
 ldx f_direction
 cpx #4
 beq @left
 cmp #$48
 bcc @goal
 cmp #$58
 bcs @goal
 bcc @short
@left:
 cmp #$F8
 bcs @short
 cmp #8
 bcs @goal
@short:
 lda #$C0
 sta w_hero_v
 sta w_hero_limit
 lda #3
 sta w_hero_v+1
 sta w_hero_limit+1
@goal:
 lda f_scroll+1
 cmp #7
 bcc @done
 lda f_scroll
 beq @done
 lda w_hero_x
 cmp #160
 bcc @done
 cmp #202
 bcs @miss
 clc
 adc #4
 sta w_hero_x
 lda #170
 sta w_hero_y
 lda #4
 sta w_hero_state
 jsr water_publish
 jmp water_finish
@miss:
 jmp water_hurt
@done:
 rts
.endproc
.segment "XL"
w_launch_lo: .byte $50,$10,$30,$10
w_launch_hi: .byte 4,5,6,8

.segment "COMPLETE"
.proc water_hazards
 lda bounce_count
 cmp #3
 bne @done
 lda w_hero_y
 cmp #80
 bcc @done
 cmp #104
 bcs @done
 ldx tramp_index
 lda passed,x
 bne @done
 inc passed,x
 inc water_bags
 inc w_prizes
 jsr complete_tramp_prize
@done:
 rts
.endproc

.proc water_init
 lda #0
 sta f_scroll
 sta f_scroll+1
 sta w_prizes
 ldx #24
@bags:
 lda w_bag_unavailable,x
 sta passed,x
 dex
 bpl @bags
 lda #0
reset:
 sta f_direction
 sta bounce_count
 sta f_phase
 sta w_spawned
 sta grace
 sta timer_div
 sta r_clock_fraction
 sta r_clock_fraction+1
 sta r_clock_fraction+2
 ldx #3
@clear:
 sta w_active,x
 dex
 bpl @clear
 sta bonus
 lda #$40
 sta bonus+1
 lda #80
 sta w_hero_x
 lda #180
 sta w_hero_y
 lda #$20
 sta w_hero_v
 sta w_hero_limit
 lda #4
 sta w_hero_v+1
 sta w_hero_limit+1
 lda #1
 sta w_hero_phase
 sta w_hero_state
 sta jumping
 lda #<1464
 sta stage_end
 lda #>1464
 sta stage_end+1
 jsr apparatus_clock_reset
 jmp water_publish
.endproc

.proc water_resume
 ; Source $86B5: retreat one scroll page, or two past page $FA.
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
 pha
 jsr water_init
 pla
 sta f_scroll+1
 jsr water_publish
 lda f_scroll+1
 cmp #3
 bcc @done
 lda #$35
 ldx f_scroll+1
 cpx #5
 bcc :+
 lda #$30
:
 sta bonus+1
@done:
 inc checkpoint_restores
 jmp update_camera
.endproc

.proc water_actors
 lda f_direction
 cmp #8
 bne @move
 lda f_scroll
 ldy #0
 cmp #$3C
 beq @trigger
 iny
 cmp #$8C
 beq @trigger
 iny
 cmp #$E8
 bne @move
@trigger:
 sty w_pair
 lda f_scroll+1
 asl
 clc
 adc f_scroll+1
 clc
 adc w_pair
 sta w_cursor
 ldy rank
 ; Each prize threshold advances the original six-row difficulty schedule.
 ldx #0
@difficulty:
 lda w_prizes
 cmp w_thresholds,x
 bcc @schedule
 iny
 inx
 cpx #9
 bcc @difficulty
@schedule:
 cpy #6
 bcc :+
 ldy #5
:
 lda w_schedule_lo,y
 sta z_ptr
 lda w_schedule_hi,y
 sta z_ptr+1
 ldy w_cursor
 lda (z_ptr),y
 sta w_kind
 beq @move
 and #3
 cmp #3
 bne @single
 lda #2
 sta w_kind
 jsr water_spawn
 lda #1
 sta w_kind
@single:
 jsr water_spawn
@move:
 ldx #0
slot:
 lda w_active,x
 jeq @next
 jsr water_actor_x
 lda w_active,x
 jeq @next
@vertical:
 lda w_phase,x
 and #1
 beq @accelerate
 lda w_vel_hi,x
 beq @turn
 lda w_phase,x
 cmp #1
 bne @down_odd
 lda w_y,x
 sec
 sbc w_vel_hi,x
 jmp @odd_y
@down_odd:
 lda w_y,x
 clc
 adc w_vel_hi,x
@odd_y:
 sta w_y,x
 lda w_vel_lo,x
 sec
 sbc #$30
 sta w_vel_lo,x
 lda w_vel_hi,x
 sbc #0
 sta w_vel_hi,x
 lda w_vel_hi,x
 ora w_vel_lo,x
 beq @turn
 jmp @next
@turn:
 lda #0
 sta w_vel_lo,x
 inc w_phase,x
 jmp @next
@accelerate:
 lda w_phase,x
 cmp #2
 bne @up_even
 lda w_y,x
 clc
 adc w_vel_hi,x
 jmp @even_y
@up_even:
 lda w_y,x
 sec
 sbc w_vel_hi,x
@even_y:
 sta w_y,x
 lda w_vel_lo,x
 clc
 adc #$30
 sta w_vel_lo,x
 lda w_vel_hi,x
 adc #0
 sta w_vel_hi,x
 cmp #4
 bne @next
 lda w_vel_lo,x
 cmp w_limit,x
 bne @next
 lda w_phase,x
 cmp #2
 bne @up_boundary
 lda w_y,x
 clc
 adc #4
 jmp @boundary_y
@up_boundary:
 lda w_y,x
 sec
 sbc #4
@boundary_y:
 sta w_y,x
 dec w_bounces,x
 lda w_bounces,x
 bpl :+
 lda #2
 sta w_bounces,x
:
 lda #$80
 ldy w_bounces,x
 bne :+
 lda #$20
:
 sta w_vel_lo,x
 sta w_limit,x
 inc w_phase,x
 lda w_phase,x
 cmp #5
 bcc @next
 lda #1
 sta w_phase,x
@next:
 inx
 cpx #4
 jne water_actors::slot
 rts
.endproc


.proc water_actor_x
 lda #2
 sta z_tmp
 lda f_scroll
 ora f_scroll+1
 beq @move
 lda f_direction
 beq @move
 cmp #4
 beq @done
 asl z_tmp
@move:
 lda w_raw_x,x
 sec
 sbc z_tmp
 sta w_raw_x,x
 cmp #241
 bcc @done
 cmp #244
 bcs @done
 lda w_special,x
 beq @remove
 lda #0
 sta w_special,x
 rts
@remove:
 lda #0
 sta w_active,x
@done:
 rts
.endproc

.proc water_spawn
 ldx #0
@empty:
 lda w_active,x
 beq @slot
 inx
 cpx #4
 bne @empty
 rts
@slot:
 inc w_spawned
 lda #1
 sta w_active,x
 lda #0
 sta w_special,x
 lda #241
 sta w_raw_x,x
 lda w_pair
 sta w_bounces,x
 lda #$80
 ldy w_pair
 bne :+
 lda #$20
:
 sta w_limit,x
 sta w_vel_lo,x
 lda #4
 sta w_vel_hi,x
 lda #200
 sta w_y,x
 lda w_kind
 and #3
 asl
 sec
 sbc #1
 sta w_phase,x
 lda w_kind
 bpl @done
 lda #1
 sta w_special,x
 lda #4
 sta w_phase,x
 lda #0
 sta w_vel_lo,x
 sta w_vel_hi,x
 lda #245
 ldy w_pair
 bne :+
 lda #237
:
 sta w_y,x
 lda #25
 cpy #0
 bne :+
 lda #17
:
 sta w_raw_x,x
@done:
 rts
.endproc

.segment "CONTACT"
.proc water_collision
 ldx #0
@slot:
 lda w_active,x
 beq @next
 ; Original 8-bit sprite centers and strict 11 / 8 / 17 cutoffs.
 lda w_raw_x,x
 clc
 adc #16
 sta z_tmp
 lda w_hero_x
 clc
 adc #16
 sec
 sbc z_tmp
 bcs :+
 eor #255
 clc
 adc #1
:
 cmp #11
 bcs @next
 sta z_tmp
 lda w_hero_y
 sec
 sbc w_y,x
 bcs :+
 eor #255
 clc
 adc #1
:
 cmp #8
 bcs @next
 clc
 adc z_tmp
 cmp #17
 bcs @next
 ; Preserve the arcade broad phase, then reject blank silhouette gaps.
 jsr water_visible_contact
 bcc @next
 inc water_hits
 lda #7
 sta w_hero_state
 jmp hurt
@next:
 inx
 cpx #4
 bne @slot
 rts
.endproc

.proc water_visible_contact
 ; Every negative Y offset in the original hit window visibly touches.
 lda w_y,x
 sec
 sbc w_hero_y
 bmi @touch
 sta z_body
 lda w_raw_x,x
 sec
 sbc w_hero_x
 clc
 adc #10
 sta z_left
 lda f_scroll
 clc
 adc w_hero_x
 and #3
 asl
 asl
 asl
 asl
 asl
 clc
 adc z_left
 sta z_ptr
 lda w_phase,x
 sec
 sbc #1
 lsr
 clc
 adc #>water_contact_limits
 sta z_ptr+1
 ; Select the low/high half-page for each phase pair.
 lda w_phase,x
 and #1
 bne :+
 lda z_ptr
 ora #$80
 sta z_ptr
:
 ldy #0
 lda (z_ptr),y
 cmp z_body
 rts
@touch:
 sec
 rts
.endproc

.align 256
water_contact_limits:
.include "dolphin-contact.inc"

.segment "XL"
.proc water_scale
 ; z_pos * 3/4, retaining source-space precision in the simulation.
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
.segment "COMPLETE"
.proc water_publish
 lda f_scroll
 clc
 adc w_hero_x
 sta z_pos
 lda f_scroll+1
 adc #0
 sta z_pos+1
 jsr water_scale
 lda z_pos
 sta world
 lda z_pos+1
 sta world+1
 lda #180
 sec
 sbc w_hero_y
 sta jump_pixels
 lda #1
 ldx w_hero_phase
 cpx #1
 beq :+
 lda #255
:
 sta velocity
 ; Current pedestal index for prizes and drawing only.
 ldx #21
@pedestal:
 lda world
 cmp w_pedestal_lo,x
 lda world+1
 sbc w_pedestal_hi,x
 bcs @index
 dex
 bpl @pedestal
 ldx #0
@index:
 stx tramp_index
 ldx #0
@actor:
 lda w_raw_x,x
 tay
 clc
 adc f_scroll
 sta z_pos
 lda f_scroll+1
 adc #0
 cpy #241
 bcc :+
 sec
 sbc #1
:
 sta z_pos+1
 jsr water_scale
 lda z_pos
 sta w_xlo,x
 lda z_pos+1
 sta w_xhi,x
 inx
 cpx #4
 bne @actor
 rts
.endproc
.segment "XL"
w_bag_unavailable: .byte 1,1,1,1,2,1,2,1,1,2,1,1,1,2,1,2,1,1,2,1,1,2,1,1,1
.segment "CODE"
w_thresholds: .byte 8,10,12,14,16,19,22,25,28

.segment "COMPLETE"
.proc water_bag_spawn
 lda f_direction
 cmp #8
 bne @done
 ldx #6
@find:
 lda f_scroll
 cmp w_bag_scroll_lo,x
 bne @next
 lda f_scroll+1
 cmp w_bag_scroll_hi,x
 bne @next
 ldy w_bag_platform,x
 lda #0
 sta passed,y
@next:
 dex
 bpl @find
@done:
 rts
.endproc
w_bag_scroll_lo: .byte 192,104,104,192,104,192,104
w_bag_scroll_hi: .byte 0,1,2,3,4,5,6
w_bag_platform: .byte 4,6,9,13,15,18,21
.segment "COMPLETE"
.proc water_draw
 ; Only visit pedestals that can intersect the 160-pixel viewport.
 lda camera+1
 asl
 asl
 sta z_tmp
 lda camera
 .repeat 6
 lsr
 .endrepeat
 ora z_tmp
 beq :+
 sec
 sbc #1
:
 sta w_index
@platform:
 ldx w_index
 lda w_pedestal_lo,x
 sta z_pos
 lda w_pedestal_hi,x
 sta z_pos+1
 jsr screen_position
 lda sprite_xhi
 bmi :+
 bne @actors
 lda sprite_x
 cmp #160
 bcs @actors
:
 lda #24
 jsr gfx_visible_width
 bcs @pnext
 lda #31
 sta gfx_cached_kind
 jsr complete_cached
@pnext:
 inc w_index
 lda w_index
 cmp #22
 bcc @platform
@actors:
 lda #0
 sta w_index
 sta z_obj
@dolphin:
 ldx w_index
 lda w_active,x
 beq @dnext
 lda w_y,x
 cmp #224
 bcs @dnext
 sec
 sbc #64
 sta z_dy
 lda w_xlo,x
 sec
 sbc #8
 sta z_pos
 lda w_xhi,x
 sbc #0
 sta z_pos+1
 jsr screen_position
 lda sprite_xhi
 bne @dnext
 lda sprite_x
 cmp #160
 bcs @dnext
 ldx z_obj
 sta pm_x,x
 lda z_dy
 sta pm_y,x
 lda #$AE
 sta pm_color,x
 ldy w_index
 lda w_phase,y
 clc
 adc #16
 sta pm_id,x
 jsr gfx_water_dolphin
 inc z_obj
@dnext:
 inc w_index
 lda w_index
 cmp #4
 bcc @dolphin
 lda z_obj
 cmp water_pm_peak
 bcc :+
 sta water_pm_peak
:
 ldx tramp_index
 lda passed,x
 bne @finish
 lda w_pedestal_lo,x
 clc
 adc #4
 sta z_pos
 lda w_pedestal_hi,x
 adc #0
 sta z_pos+1
 jsr screen_position
 lda sprite_xhi
 bne @finish
 lda sprite_x
 cmp #160
 bcs @finish
 lda #48
 sta sprite_y
 lda #WATER_BAG
 sta sprite_pose
 jsr tramp_bag
@finish:
 lda stage_end
 sta z_pos
 lda stage_end+1
 sta z_pos+1
 jsr screen_position
 lda #32
 jsr gfx_visible_width
 bcs @done
 lda #10
 sta gfx_cached_kind
 jmp complete_cached
@done:
 rts
.endproc

.include "water-tables.inc"

.segment "XL"
.proc water_hurt
 jsr hurt
 lda #$3C
 sta $D500
 rts
.endproc
.segment "CODE"
.proc water_finish
 ; Arcade freezes the counter on the successful landing update.
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
 lda #$3C
 sta $D500
 rts
.endproc
.segment "COMPLETE"
