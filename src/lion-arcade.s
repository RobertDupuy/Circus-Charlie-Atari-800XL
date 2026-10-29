; Act 1, recovered from Circus Charlie KONAMI-1 $727A..$7DE4.
; Horizontal space is scaled 3/4; elapsed frame timing and vertical arc are retained.
; Original: right $FE80, left $0130, ring drift $0080; jump -$0380,+$001C.
.segment "XL"
.proc lion_arcade_init
 lda #48
 sta world
 lda #0
 sta world+1
 sta lion_bias
 sta bonus
 sta f_scroll
 sta f_scroll+1
 sta f_previous
 lda #<1362
 sta stage_end
 lda #>1362
 sta stage_end+1
 lda #12
 sta lion_gap+1
 lda #16
 sta lion_lastgap
 lda #$58
 sta bonus+1
 jsr apparatus_clock_reset
 ldx rank
 lda lion_potoffsets,x
 sta z_step
 lda lion_potcounts,x
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
 lda lion_pots_frac,y
 sta lion_potfrac,x
 inx
 cpx lion_potcount
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
 ; Arcade $739B..$73B1 tests the prospective height before horizontal
 ; movement. Its scroll predicate is strictly past the platform edge.
 cmp #12
 bcs @not_finished
 lda lion_frac
 cmp #1
 lda world
 sbc stage_end
 lda world+1
 sbc stage_end+1
 bcc @not_finished
 lda #11
 sta jump_pixels
 lda #0
 sta jumping
 lda #1
 sta lion_goal
 jmp finish_act
@not_finished:
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
 jsr hidden_entry
 lda #1
 sta jumping
 sta sound_fx
 lda #0
 sta lion_phase
 sta sound_age
@move:
 jsr lion_arcade_move
 jsr lion_arcade_rings
@done:
 rts
.endproc

.proc lion_arcade_rings
 ; The original advances its spawn clock before moving/retiring actors.
 lda world
 cmp #<1200
 lda world+1
 sbc #>1200
 bcs clock_done
 lda lion_gap
 sec
 sbc lion_relative_lo
 sta lion_gap
 lda lion_gap+1
 sbc lion_relative_hi
 sta lion_gap+1
clock_done:
 php
 lda #$3A
 sta $D500
 jsr lion_rear_hoop
 ldx #0
ring:
 lda lion_active,x
 beq next
 lda lion_ringfrac,x
 sec
drift_lo:
 sbc #$60
 sta lion_ringfrac,x
 lda hazard_xlo,x
drift_hi:
 sbc #0
 sta hazard_xlo,x
 lda hazard_xhi,x
 sbc #0
 sta hazard_xhi,x
 jsr lion_right_exit
 ; Arcade retires a hoop when its screen coordinate crosses zero.
 lda world
 sec
 sbc hazard_xlo,x
 sta z_tmp2
 lda world+1
 sbc hazard_xhi,x
 bmi next
 bne retire
 lda z_tmp2
 cmp #49
 bcs retire
 cmp #48
 bne next
 lda lion_frac
 cmp lion_ringfrac,x
 beq next
 bcc next
retire:
 jsr lion_retire_hoop
next:
 inx
 cpx #4
 bne ring
 plp
 lda lion_relative_hi
 jmi done
 jcs done
 lda rank
 clc
 adc #1 ; Normal DIP starts at slice 1; each Lion clear advances one slice.
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
 bne normal
 lda lion_lastgap
 cmp #96
 bcs money
 inc lion_bias
normal:
 lda #0
 sta z_kind
 ldx #0
slot:
 lda lion_active,x
 ora f_direction,x ; Arcade allocates before this frame's retirements.
 beq spawn
 inx
 cpx #3
 bcc slot
 jmp reload
money:
 lda #2
 sta z_kind
 ldx #3
 lda #96
 ldy rank
 bne :+ ; Original $7876: only the first course uses the free-running clock.
 lda scene_clock
 clc
 adc #244
 ora #128
:
 sta z_tmp
spawn:
 lda #1
 sta lion_active,x
 lda z_kind
 sta hoop_type,x
 lda #0
 sta passed,x
 ; 255.5 arcade screen pixels minus the 64-pixel hero anchor, scaled 3/4.
 lda lion_frac
 sec
 sbc lion_relative_lo
 sta z_tmp2
 lda #0
 sbc lion_relative_hi
 sta z_value
 lda z_tmp2
 clc
 adc #$A0
 sta lion_ringfrac,x
 lda z_value
 adc #143
 clc
 adc world
 sta hazard_xlo,x
 lda world+1
 adc #0
 sta hazard_xhi,x
 lda #3
 jsr hidden_entry
reload:
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
done:
 lda #242
 sta $D500
 jsr hidden_motion
 lda #0
 sta $D500
 rts
.endproc

; Original $789C rear-entry counter, in source 8.8 units. These existing
; fidelity bytes are included in both players' checkpoints. The inactive
; trampoline contact bank has room without disturbing any audio packets.
.segment "TRAMPCONTACT"
.proc lion_rear_hoop
 lda #0
 ldx #3
clear_retired:
 sta f_direction,x
 dex
 bpl clear_retired
 lda lion_relative_hi
 bmi reverse
 tay
 lda #128
 cpy #0
 beq forward
 lda #0
 ldy #2
forward:
 clc
 adc f_scroll
 sta f_scroll
 tya
 adc f_scroll+1
 sta f_scroll+1
 rts
reverse:
 lda f_scroll
 sec
 sbc #176
 sta z_tempword
 lda f_scroll+1
 sbc #0
 bcc reenter
 sta f_scroll+1
 lda z_tempword
 sta f_scroll
 rts
reenter:
 ; Pre-movement left edge, in native 16.8 units. Existing actors have
 ; not drifted yet. The arcade blocks re-entry if an actor's integer
 ; screen coordinate is 1..64, including the raised money hoop.
 lda lion_frac
 sec
 sbc lion_velocity_lo
 sta z_s0
 lda world
 sbc lion_velocity_hi
 sta z_s1
 lda world+1
 sbc #255
 sta z_s2
 lda z_s1
 sec
 sbc #48
 sta z_s1
 bcs :+
 dec z_s2
:
 ldx #3
scan:
 lda lion_active,x
 beq next
 lda lion_ringfrac,x
 sec
 sbc z_s0
 sta z_tmp
 lda hazard_xlo,x
 sbc z_s1
 sta z_tmp2
 lda hazard_xhi,x
 sbc z_s2
 bne next
 lda z_tmp2
 beq low
 cmp #48
 bcc done
 bne next
 lda z_tmp
 cmp #192
 bcc done
 bcs next
low:
 lda z_tmp
 cmp #192
 bcs done
next:
 dex
 bpl scan
 lda f_previous
 bne money
 ldx #0
slot:
 lda lion_active,x
 beq spawn
 inx
 cpx #3
 bcc slot
 rts
money:
 lda #0
 sta f_previous
 ldx #3
spawn:
 lda #1
 sta lion_active,x
 lda z_s0
 clc
 adc #192
 sta lion_ringfrac,x
 lda z_s1
 adc #0
 sta hazard_xlo,x
 lda z_s2
 adc #0
 sta hazard_xhi,x
 lda #0
 cpx #3
 bne :+
 lda #2
:
 sta hoop_type,x
done:
 rts
.endproc
.proc lion_retire_hoop
 lda #4
 jsr hidden_entry
 inc f_direction,x
 lda #0
 sta lion_active,x
 sta f_scroll+1
 sta f_previous
 cpx #3
 bne :+
 inc f_previous
:
 rts
.endproc
.proc lion_right_retire
 lda #5
 jsr hidden_entry
 inc f_direction,x
 dec lion_wave
 lda #0
 sta lion_active,x
 ; Original clears only the source counter's integer byte. Since the
 ; native value is scaled 3/4, retain its remainder modulo 192, not 256.
 lda lion_gap+1
mod3:
 cmp #3
 bcc scale
 sbc #3
 bcs mod3
scale:
 .repeat 6
 asl
 .endrepeat
 clc
 adc lion_gap
 bcc reduce
 adc #63
 bcc save
reduce:
 cmp #192
 bcc save
 sbc #192
save:
 sta lion_gap
 lda #0
 sta lion_gap+1
 rts
.endproc
.segment "TRAMPOLINE"
.proc lion_right_exit
 lda lion_ringfrac,x
 sec
 sbc lion_frac
 lda hazard_xlo,x
 sbc world
 sta z_tmp
 lda hazard_xhi,x
 sbc world+1
 bmi done
 bne retire
 lda z_tmp
 cmp #144
 bcc done
retire:
 jmp lion_right_retire
done:
 rts
.endproc
.segment "MECHANICS"

.proc lion_arcade_move
 lda #$60
 sta lion_arcade_rings::drift_lo+1
 lda #0
 sta lion_velocity_lo
 sta lion_velocity_hi
 sta lion_arcade_rings::drift_hi+1
 lda lion_direction
 cmp #8
 beq @right
 cmp #4
 bne @apply
 sec
 jsr lion_left_boundary
 bcc @apply
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
 lda #0
 bit lion_velocity_hi
 bpl :+
 lda #255
:
 adc world+1
 sta world+1
 lda lion_velocity_hi
 bpl @relative
 sec
 jsr lion_left_boundary
 bcs @relative
 ; On the field that crosses the left boundary the arcade freezes screen
 ; movement after updating its scroll counter. Preserve that fractional edge.
 lda #$44
 sta lion_arcade_rings::drift_lo+1
 lda #1
 sta lion_arcade_rings::drift_hi+1
 lda #0
 sta lion_velocity_lo
 sta lion_velocity_hi
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
.segment "TOPCLIP"
; Caller sets carry: a positive high byte is necessarily right of the edge.
.proc lion_left_boundary
 lda world+1
 bne @done
 lda world
 cmp #48
 bne @done
 lda lion_frac
 cmp #1
@done:
 rts
.endproc
.segment "MECHANICS"




.segment "GFX"
.proc lion_source_distance
 pha
 lda #$3E
 sta $D500
 pla
 jmp lion_source_distance_impl
.endproc
.segment "FIDELITY"
.proc lion_source_distance_impl
 sec
 sbc lion_frac
 sta z_tempword
 lda z_pos
 sbc world
 sta z_tempword+1
 lda z_pos+1
 sbc world+1
 sta z_pos+1
 sta z_flag
 bpl @positive
 lda #0
 sec
 sbc z_tempword
 sta z_tempword
 lda #0
 sbc z_tempword+1
 sta z_tempword+1
 lda #0
 sbc z_pos+1
 sta z_pos+1
 ; Round a negative delta away from zero before taking its absolute value.
 lda z_tempword
 clc
 adc #191
 sta z_tempword
 bcc @positive
 inc z_tempword+1
 bne @positive
 inc z_pos+1
@positive:
 lda z_pos+1
 bne @done
 lda z_tempword+1
 cmp #24
 bcc :+
 inc z_pos+1
 rts
:
 ; floor((integer*256+fraction)/192) = floor((integer*4+
 ; floor(fraction/64))/3). The range guard above bounds this index to 0..95.
 ; Use the exact quotient table to leave more display time near several pots.
 lda z_tempword
 asl
 rol z_tempword+1
 asl
 rol z_tempword+1
 ldy z_tempword+1
 lda lion_distance_thirds,y
 sta z_pos
@done:
 rts
.endproc
lion_distance_thirds:
 .repeat 96,I
  .byte I/3
 .endrepeat
.segment "XL"

.proc lion_arcade_collision
 lda $D500
 pha
 lda #242
 sta $D500
 jsr hidden_lion_collision
 pla
 sta $D500
 rts
.endproc
.segment "HIDDEN"
.proc hidden_lion_collision
 ldx #0
@ring:
 lda lion_active,x
 jeq @next
 lda hazard_xlo,x
 sta z_pos
 lda hazard_xhi,x
 sta z_pos+1
 lda lion_ringfrac,x
 jsr hidden_distance
 lda z_pos+1
 bne @next
 lda z_pos
 cmp #14
 bcs @next
 lda hoop_type,x
 cmp #3
 bcc @ordinary_contact
 bne @next
 lda jump_pixels
 cmp #41 ; Original $7345: hero Y strictly below $A8.
 bcc @next
 inc hoop_type,x
 lda #3
 sta hidden_life
 jsr hidden_extra_life
 jmp @next
@ordinary_contact:
 tay
 lda #26
 ldy hoop_type,x
 beq :+
 lda #42
:
 sec
 sbc jump_pixels
 bcc @award
 clc
 adc z_pos
 cmp #29
 jcc @crash
@award:
 lda hoop_type,x
 beq @normal_award
 lda jump_pixels
 cmp #43
 bcc @next
 bcs @paid
@normal_award:
 lda jumping
 jeq @next
@paid:
 lda passed,x
 bne @next
 inc passed,x
 txa
 pha
 lda hoop_type,x
 beq @ordinary
 inc bag_awards
 jsr hidden_money
 jmp @scored
@ordinary:
 ldy #1
@score:
 lda #0
 jsr hidden_points
@scored:
 pla
 tax
@next:
 inx
 cpx #4
 jne @ring
 ldx #0
@pot:
 lda lion_potlo,x
 sta z_pos
 lda lion_pothi,x
 sta z_pos+1
 lda lion_potfrac,x
 jsr hidden_distance
 lda z_pos+1
 bne @potnext
 lda z_pos
 cmp #23
 bcc @potcontact
 bne @potnext
 bit z_flag
 bpl @potnext
@potcontact:
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
 jsr hidden_points
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
.segment "XL"

.proc lion_arcade_draw
 lda #0
 sta z_hazard
 sta z_obj
@hoop:
 ldx z_hazard
 lda lion_active,x
 jeq @next
 lda hoop_type,x
 cmp #3
 bcc @ordinary
 jne @next
 lda #9
 jsr hidden_entry
 jmp @next
@ordinary:
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
 jne @next
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
