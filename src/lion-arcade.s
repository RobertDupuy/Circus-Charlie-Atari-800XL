; Act 1, recovered from Circus Charlie KONAMI-1 $727A..$7DE4.
; Horizontal space is scaled 3/4; elapsed frame timing and vertical arc are retained.
; Original: right $FE80, left $0130, ring drift $0080; jump -$0380,+$001C.
.segment "XL"
.proc lion_arcade_init
 lda #48
 sta world
 lda #0
 sta world+1
 sta first_hazard
 lda #<1362
 sta stage_end
 lda #>1362
 sta stage_end+1
 lda #12
 sta lion_gap+1
 lda #2
 sta lion_bias
 lda #16
 sta lion_lastgap
 lda rank
 asl
 asl
 asl
 sta z_step
 lda #5
 ldx rank
 beq :+
 lda #8
:
 sta lion_potcount
 ldx #0
@pots:
 txa
 clc
 adc z_step
 tay
 lda lion_pots_lo,y
 sta lion_potlo,x
 lda lion_pots_hi,y
 sta lion_pothi,x
 inx
 cpx #8
 bne @pots
 rts
.endproc

.segment "MECHANICS"
.proc lion_arcade_step
 lda grace
 bne :+
 jsr lion_arcade_collision
:
 lda mode
 cmp #2
 jne @done
 lda jump_pixels
 sta previous_height
 lda jumping
 beq @ground
 lda lion_phase
 cmp #61
 bcc :+
 lda z_fire
 beq :+
 lda #1
 sta lion_buffer
 lda z_joy
 sta lion_buffer_direction
:
 inc lion_phase
 lda #32
 sec
 sbc lion_phase
 sta velocity
 ldx lion_phase
 lda lion_jump,x
 sta jump_pixels
 cpx #63
 bcc @move
 lda #0
 sta jumping
 sta lion_phase
 jsr complete_lion_land
@ground:
 lda z_joy
 and #12
 sta lion_direction
 lda lion_buffer
 beq @fire
 lda lion_buffer_direction
 and #12
 sta lion_direction
 lda #0
 sta lion_buffer
 jmp @launch
@fire:
 lda z_fire
 beq @move
@launch:
 lda #1
 sta jumping
 sta sound_fx
 lda #0
 sta lion_phase
 sta sound_age
@move:
 jsr lion_arcade_move
 jsr lion_arcade_rings
 lda jumping
 beq @done
 lda lion_phase
 cmp #32
 bcc @done
 lda jump_pixels
 cmp #12
 bcs @done
 lda world
 cmp stage_end
 lda world+1
 sbc stage_end+1
 bcc @done
 lda #11
 sta jump_pixels
 lda #0
 sta jumping
 lda #1
 sta lion_goal
 jmp finish_act
@done:
 rts
.endproc

.proc lion_arcade_move
 lda #0
 sta lion_velocity_lo
 sta lion_velocity_hi
 lda lion_direction
 cmp #8
 beq @right
 cmp #4
 bne @apply
 lda #$1C
 sta lion_velocity_lo
 lda #$FF
 sta lion_velocity_hi
 bne @apply
@right:
 lda #$20
 sta lion_velocity_lo
 lda #1
 sta lion_velocity_hi
@apply:
 lda lion_frac
 clc
 adc lion_velocity_lo
 sta lion_frac
 lda world
 adc lion_velocity_hi
 sta world
 lda lion_velocity_hi
 bpl :+
 lda #255
 bne @high
:
 lda #0
@high:
 adc world+1
 sta world+1
 bmi @minimum
 bne @limit
 lda world
 cmp #48
 bcs @limit
@minimum:
 lda #48
 sta world
 lda #0
 sta world+1
 sta lion_frac
@limit:
 lda world
 cmp #<1374
 lda world+1
 sbc #>1374
 bcc @relative
 lda #<1374
 sta world
 lda #>1374
 sta world+1
@relative:
 lda lion_velocity_lo
 clc
 adc #$60
 sta lion_relative_lo
 lda lion_velocity_hi
 adc #0
 sta lion_relative_hi
 rts
.endproc

.proc lion_arcade_rings
 ldx #3
@ring:
 lda lion_active,x
 beq @next
 lda lion_ringfrac,x
 sec
 sbc #$60
 sta lion_ringfrac,x
 lda hazard_xlo,x
 sbc #0
 sta hazard_xlo,x
 lda hazard_xhi,x
 sbc #0
 sta hazard_xhi,x
 ; Retire once more than 64 pixels behind the hero.
 lda world
 sec
 sbc hazard_xlo,x
 sta z_tmp
 lda world+1
 sbc hazard_xhi,x
 bmi @next
 bne @retire
 lda z_tmp
 cmp #80
 bcc @next
@retire:
 lda #0
 sta lion_active,x
@next:
 dex
 bpl @ring
 ; The final approach stops the ring stream, as at arcade $77B8.
 lda world
 cmp #<1200
 lda world+1
 sbc #>1200
 jcs @done
 lda lion_gap
 sec
 sbc lion_relative_lo
 sta lion_gap
 lda lion_gap+1
 sbc lion_relative_hi
 sta lion_gap+1
 lda lion_relative_hi
 jmi @done
 jcs @done
 lda rank
 clc
 adc #1
 asl
 asl
 asl
 asl
 clc
 adc lion_wave
 cmp #104
 bcc :+
 and #7
 ora #96
:
 tay
 lda lion_gaps,y
 sta z_tmp
 tya
 clc
 adc lion_bias
 and #3
 bne @normal
 lda lion_lastgap
 cmp #96
 bcs @money
 inc lion_bias
@normal:
 lda #0
 sta z_kind
 ldx #0
@slot:
 lda lion_active,x
 beq @spawn
 inx
 cpx #3
 bcc @slot
 jmp @reload
@money:
 lda #2
 sta z_kind
 ldx #3
 lda #96
 ldy rank
 bne :+
 lda scene_clock
 clc
 adc #38
 ora #128
:
 sta z_tmp
@spawn:
 lda #1
 sta lion_active,x
 lda z_kind
 sta hoop_type,x
 lda #0
 sta passed,x
 ; 255.5 arcade screen pixels minus the 64-pixel hero anchor, scaled 3/4.
 lda lion_frac
 clc
 adc #$A0
 sta lion_ringfrac,x
 lda world
 adc #143
 sta hazard_xlo,x
 lda world+1
 adc #0
 sta hazard_xhi,x
@reload:
 inc lion_wave
 lda z_tmp
 sta lion_lastgap
 ; Exact 3/4 conversion: integer byte / 4 plus byte / 2, in 8.8.
 sta z_tempword+1
 lda #0
 sta z_tempword
 lsr z_tempword+1
 ror z_tempword
 lda z_tempword
 sta lion_gap
 lda z_tempword+1
 sta lion_gap+1
 lsr z_tempword+1
 ror z_tempword
 lda lion_gap
 clc
 adc z_tempword
 sta lion_gap
 lda lion_gap+1
 adc z_tempword+1
 sta lion_gap+1
@done:
 rts
.endproc

.segment "XL"
.proc lion_arcade_collision
 ldx #0
@ring:
 lda lion_active,x
 beq @next
 lda hazard_xlo,x
 sta z_pos
 lda hazard_xhi,x
 sta z_pos+1
 jsr distance_to_player
 lda z_pos+1
 bne @next
 lda z_pos
 cmp #11
 bcs @next
 tay
 lda #26
 ldy hoop_type,x
 beq :+
 lda #42
:
 sec
 sbc jump_pixels
 bcc @award
 ldy z_pos
 clc
 adc lion_collision_distance,y
 cmp #29
 bcc @crash
@award:
 lda hoop_type,x
 beq @normal_award
 lda jump_pixels
 cmp #43
 bcc @next
 bcs @paid
@normal_award:
 lda jumping
 beq @next
@paid:
 lda passed,x
 bne @next
 inc passed,x
 txa
 pha
 lda hoop_type,x
 beq @ordinary
 inc bag_awards
 jsr complete_lion_bag
 jmp @scored
@ordinary:
 ldy #1
@score:
 lda #0
 jsr add_points
@scored:
 pla
 tax
@next:
 inx
 cpx #4
 bne @ring
 ldx #0
@pot:
 lda lion_potlo,x
 sta z_pos
 lda lion_pothi,x
 sta z_pos+1
 jsr distance_to_player
 lda z_pos+1
 bne @potnext
 lda z_pos
 cmp #18
 bcs @potnext
 lda jump_pixels
 cmp #11
 bcc @crash
 lda lion_potpaid,x
 bne @potnext
 inc lion_potpaid,x
 txa
 pha
 lda #0
 ldy #5
 jsr add_points
 pla
 tax
@potnext:
 inx
 cpx lion_potcount
 bne @pot
 rts
@crash:
 jmp hurt
.endproc

.proc lion_arcade_draw
 lda #0
 sta z_hazard
 sta z_obj
@hoop:
 ldx z_hazard
 lda lion_active,x
 jeq @next
 jsr get_hazard
 ; Ring positions denote their centre; prepared graphics start at its left.
 lda z_pos
 sec
 sbc #8
 sta z_pos
 bcs :+
 dec z_pos+1
:
 jsr screen_position
 lda #16
 jsr gfx_visible_width
 jcs @next
 ldx z_hazard
 lda #0
 ldy hoop_type,x
 beq :+
 lda #16
:
 sta gfx_cached_kind
 jsr gfx_cached_select
 ldx z_obj
 lda sprite_x
 sta pm_x,x
 lda #72
 sta pm_y,x
 lda anim_clock
 lsr
 lsr
 and #3
 ldy z_hazard
 pha
 lda hoop_type,y
 beq :+
 pla
 ora #4
 pha
:
 pla
 sta pm_id,x
 lda #$38
 sta pm_color,x
 inc z_obj
 ldx z_hazard
 lda hoop_type,x
 beq @next
 lda passed,x
 bne @next
 lda sprite_x
 clc
 adc #3
 sta sprite_x
 lda sprite_xhi
 adc #0
 sta sprite_xhi
 lda #96
 sta sprite_y
 jsr lion_arcade_bag_draw
@next:
 inc z_hazard
 lda z_hazard
 cmp #4
 jne @hoop
 lda z_obj
 cmp mech_pm_peak
 bcc :+
 sta mech_pm_peak
:
 lda #0
 sta z_hazard
@pot:
 ldx z_hazard
 lda lion_potlo,x
 sec
 sbc #8
 sta z_pos
 lda lion_pothi,x
 sbc #0
 sta z_pos+1
 jsr screen_position
 lda #16
 jsr gfx_visible_width
 bcs @potnext
 lda anim_clock
 lsr
 lsr
 and #1
 clc
 adc #3
 sta gfx_cached_kind
 jsr gfx_cached_select
@potnext:
 inc z_hazard
 lda z_hazard
 cmp lion_potcount
 bne @pot
 jmp lion_arcade_signs
.endproc

.segment "XL"
; Draw only the near semicircle over the actor. Background/rim glyphs are
; immutable; each hero cell has a unique glyph in its reserved range, so this
; needs neither another character allocation nor another dirty rectangle.
.proc lion_hoop_foreground
 lda #0
 sta z_hazard
@ring:
 ldx z_hazard
 ; The background pass already staged each visible hoop's left edge and
 ; eight-way flame pose. Reuse those exact placements instead of projecting
 ; all four world positions and selecting their poses a second time.
 lda pm_id,x
 cmp #8
 jcs @next_ring
 asl
 asl
 sta z_tmp
 ; Near half is eight pixels wide; Charlie/lion is 24 pixels wide.
 lda pm_x,x
 sec
 sbc gfx_hero_x
 clc
 adc #7
 cmp #31
 jcs @next_ring
 lda pm_x,x
 and #3
 ora z_tmp
 tax
 lda #$34
 sta $D500
 lda $B600,x
 sta z_rom
 lda $B620,x
 sta z_rom+1
 lda $B640,x
 sta $D500
 ldx z_hazard
 lda pm_x,x
 lsr
 lsr
 sta z_map
 jsr @call
 lda #0
 sta z_map
 ldx back
 lda screen_high,x
 sta z_map+1
@next_ring:
 inc z_hazard
 lda z_hazard
 cmp #4
 jne @ring
 rts
@call:
 jmp (z_rom)
.endproc
.segment "XL"

.proc lion_arcade_signs
 lda #0
 sta z_hazard
@marker:
 ldx z_hazard
 lda lion_sign_lo,x
 sta z_pos
 lda lion_sign_hi,x
 sta z_pos+1
 jsr screen_position
 lda #16
 jsr gfx_visible_width
 bcs @next
 lda sprite_x
 and #$FC
 sta sprite_x
 lda z_hazard
 clc
 adc #18
 sta gfx_cached_kind
 jsr gfx_cached_select
@next:
 inc z_hazard
 lda z_hazard
 cmp #7
 bne @marker
 rts
.endproc

.proc lion_arcade_finish_draw
 lda stage_end
 sec
 sbc #16
 sta z_pos
 lda stage_end+1
 sbc #0
 sta z_pos+1
 jsr screen_position
 lda #32
 jsr gfx_visible_width
 bcs @done
 lda sprite_x
 and #$FC
 sta sprite_x
 lda #17
 sta gfx_cached_kind
 jmp gfx_cached_select
@done:
 rts
.endproc

.segment "XL"
.proc lion_arcade_bag_draw
 ; Parent hoop already records the entire dirty rectangle. The bag has fixed
 ; glyph slots after Charlie's reservation, with clipped native ROM stores.
 txa
 pha
 tya
 pha
 lda #$34
 sta $D500
 lda sprite_x
 and #3
 asl
 ora back
 asl
 tay
 lda $8580,y
 sta z_rom
 lda $8581,y
 sta z_rom+1
 lda sprite_x
 lsr
 lsr
 ldx sprite_xhi
 beq :+
 ora #$C0
:
 tax
 jsr @call
 pla
 tay
 pla
 tax
 rts
@call:
 jmp (z_rom)
.endproc

.include "lion-arcade-tables.inc"

.segment "GFX"
.proc lion_restore_ring_rect
 lda act
 bne @no
 lda z_src+1
 cmp #$35
 bne @no
 lda z_src
 sec
 sbc #$68
 bcc @no
 cmp #40
 bcs @no
 tax
 lda gfx_rect_w
 cmp #4
 bcc @no
 cmp #6
 bcs @no
 and #1
 asl
 ora back
 asl
 sta z_tmp
 lda gfx_rect_h
 cmp #7
 beq @go
 cmp #9
 bne @no
 lda z_tmp
 ora #8
 sta z_tmp
@go:
 lda #$34
 sta $D500
 ldy z_tmp
 lda $8590,y
 sta z_rom
 lda $8591,y
 sta z_rom+1
 jsr @call
 sec
 rts
@call:
 jmp (z_rom)
@no:
 clc
 rts
.endproc
