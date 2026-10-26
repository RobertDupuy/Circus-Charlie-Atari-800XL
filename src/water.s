.export water_hazards
; Bank 28: water uses arcade trampoline arcs and four live dolphin slots.
.proc water_step
 lda #0
 sta z_dx
 lda f_direction
 beq @height
 cmp #4
 beq @left
 lda f_fraction
 clc
 adc #128
 sta f_fraction
 lda world
 adc #1
 sta world
 lda world+1
 adc #0
 sta world+1
 jmp @height
@left:
 lda f_fraction
 sec
 sbc #128
 sta f_fraction
 lda world
 sbc #1
 sta world
 lda world+1
 sbc #0
 sta world+1
 bpl @height
 lda #60
 sta world
 lda #0
 sta world+1
@height:
 inc f_phase
 ldx f_tramp_arc
 lda water_arc_lo,x
 sta z_ptr
 lda water_arc_hi,x
 sta z_ptr+1
 ldy f_phase
 lda (z_ptr),y
 sta jump_pixels
 lda water_arc_length,x
 cmp f_phase
 beq @land
 lsr
 cmp f_phase
 lda #1
 bcs :+
 lda #255
:
 sta velocity
 jmp water_hazards
@land:
 jmp water_land
.endproc

.proc water_land
 lda world
 cmp stage_end
 lda world+1
 sbc stage_end+1
 bcc @apparatus
 lda stage_end
 clc
 adc #32
 sta z_pos
 lda stage_end+1
 adc #0
 sta z_pos+1
 lda world
 cmp z_pos
 lda world+1
 sbc z_pos+1
 jcs hurt
 jmp finish_act
@apparatus:
 ldx #0
@platform:
 lda w_pedestal_lo,x
 clc
 adc #8
 sta z_pos
 lda w_pedestal_hi,x
 adc #0
 sta z_pos+1
 jsr distance_to_player
 lda z_pos+1
 bne @next
 lda z_pos
 cmp #13
 bcc @bounce
@next:
 inx
 cpx #25
 bne @platform
 jmp hurt
@bounce:
 stx tramp_index
 lda z_joy
 and #12
 cmp #12
 bne :+
 lda #0
:
 sta f_direction
 cmp #0
 beq @stationary
 lda #0
 sta bounce_count
 sta f_tramp_arc
 txa
@mod:
 cmp #3
 bcc @short
 sbc #3
 bcs @mod
@short:
 cmp #2
 bne @reset
 lda #1
 sta f_tramp_arc
 bne @reset
@stationary:
 inc bounce_count
 lda bounce_count
 cmp #4
 jcs hurt
 clc
 adc #1
 sta f_tramp_arc
@reset:
 lda #0
 sta f_phase
 sta jump_pixels
 sta sound_age
 lda #1
 sta sound_fx
water_hazards = *

 lda bounce_count
 cmp #3
 bne @flame
 lda jump_pixels
 cmp #80
 bcc @flame
 ldx tramp_index
 lda passed,x
 bne @flame
 inc passed,x
 inc water_bags
 jsr complete_tramp_prize
@flame:
 jmp water_actors
.endproc
water_hazards = water_land::water_hazards

.proc water_init
 lda #1
 sta jumping
 lda #60
 sta world
 lda #0
 sta world+1
 sta f_fraction
 sta f_phase
 sta f_tramp_arc
 sta f_direction
 sta bounce_count
 sta tramp_index
 sta w_cursor
 sta w_spawned
 ldx #3
@clear:
 sta w_active,x
 dex
 bpl @clear
 lda #<1656
 sta stage_end
 lda #>1656
 sta stage_end+1
 rts
.endproc

.proc water_resume
 lda tramp_index
 pha
 jsr water_init
 pla
 tax
 stx tramp_index
 lda w_pedestal_lo,x
 clc
 adc #8
 sta world
 lda w_pedestal_hi,x
 adc #0
 sta world+1
 ldx #0
@skip:
 lda world
 cmp w_triggers_lo,x
 lda world+1
 sbc w_triggers_hi,x
 bcc @done
 inx
 cpx #24
 bcc @skip
@done:
 stx w_cursor
 lda #90
 sta grace
 inc checkpoint_restores
 jmp update_camera
.endproc

.proc water_actors
 lda f_direction
 cmp #8
 bne @move
 ldx w_cursor
 cpx #24
 bcs @move
 lda world
 cmp w_triggers_lo,x
 lda world+1
 sbc w_triggers_hi,x
 bcc @move
 ldy rank
 lda w_schedule_lo,y
 sta z_ptr
 lda w_schedule_hi,y
 sta z_ptr+1
 txa
 tay
 lda (z_ptr),y
 sta w_kind
 beq @spawn_done
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
@spawn_done:
 inc w_cursor
@move:
 ldx #0
@slot:
 lda w_active,x
 jeq @next
 ; Dolphins move two original pixels left per simulation frame.
 lda w_xfrac,x
 sec
 sbc #128
 sta w_xfrac,x
 lda w_xlo,x
 sbc #1
 sta w_xlo,x
 sta z_pos
 lda w_xhi,x
 sbc #0
 sta w_xhi,x
 sta z_pos+1
 jsr screen_position
 lda sprite_xhi
 bpl @vertical
 lda sprite_x
 cmp #232
 bcs @vertical
 lda #0
 sta w_active,x
 jmp @next
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
 jne @slot
 jmp water_collision
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
 sta w_xfrac,x
 sta w_special,x
 ldy w_cursor
 lda w_positions_lo,y
 sta w_xlo,x
 lda w_positions_hi,y
 sta w_xhi,x
 tya
@mod:
 cmp #3
 bcc @index
 sbc #3
 bcs @mod
@index:
 sta w_bounces,x
 lda #$80
 ldy w_bounces,x
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
 lda #45
 ldy w_bounces,x
 bne :+
 lda #37
:
 clc
 adc w_y,x
 sta w_y,x
 lda #30
 cpy #0
 bne :+
 lda #24
:
 clc
 adc w_xlo,x
 sta w_xlo,x
 bcc @done
 inc w_xhi,x
@done:
 rts
.endproc

.proc water_collision
 lda grace
 bne @done
 ldx #0
@slot:
 lda w_active,x
 beq @next
 lda w_xlo,x
 sta z_pos
 lda w_xhi,x
 sta z_pos+1
 jsr distance_to_player
 lda z_pos+1
 bne @next
 lda z_pos
 cmp #9
 bcs @next
 sta z_tmp
 lda #180
 sec
 sbc jump_pixels
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
 cmp #15
 bcs @next
 inc water_hits
 jmp hurt
@next:
 inx
 cpx #4
 bne @slot
@done:
 rts
.endproc

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
 cmp #25
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
