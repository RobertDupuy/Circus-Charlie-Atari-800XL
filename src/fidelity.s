; Native 6502 translations of the arcade's takeoff and object rules.
; Horizontal coordinates retain the Act 1 3/4 scale, with 8 fractional bits.
; All frame integrators run at the simulation rate, independent of rendering.
.proc fidelity_init
 lda act
 cmp #1
 jeq k_init
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
 lda act
 cmp #2
 beq @trampoline
 cmp #3
 beq @ball
 lda #48
 sta world
 rts
@trampoline:
 ; Original $FBD5: 5830 before play; $BD48 counts once each live update.
 lda #$30
 sta bonus
 lda #$58
 sta bonus+1
 jmp tramp_init_entry
@ball:
 jmp b_init
.endproc

.proc fidelity_step
 lda act
 cmp #1
 jeq k_step
 jmp b_step
.endproc
.proc b_contact
@hazards:
 lda grace
 bne @done
 lda f_active
 cmp #1
 bne @done
 lda f_object_speed
 cmp #3
 bcs @done
 ldx #1
@touch:
 lda f_active,x
 cmp #1
 bne @next
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
 bcs @next
 lda jumping
 jeq fidelity_hurt
 ldy f_object_speed
 lda b_impact_state,y
 sta f_object_speed,x
 lda #6
 cpy #1
 bne :+
 lda #7
:
 sta f_object_speed
 lda #2
 sta f_active
 rts
@next:
 inx
 cpx #5
 bne @touch
@done:
 rts
.endproc

b_impact_state: .byte 5,7,6

.include "balls-arcade.s"
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
 lda act
 cmp #1
 jeq k_resume
 lda f_scroll+1
 pha
 jsr fidelity_init
 pla
 sta f_scroll+1
 lda #0
 sta scene_clock
 sta scene_clock+1
@ready:
 jsr b_publish
@done:
 inc checkpoint_restores
 jmp update_camera
.endproc




; Old entry points remain callable by compatibility test fixtures only.
.proc fidelity_rope_record
 rts
.endproc
.proc fidelity_rope_move
 rts
.endproc


; Spring value uses the arcade's width/height base and powers of two for
; the incoming speed plus consecutive contacts before returning to the horse.
.segment "APPARATUS"
.proc horse_arcade_points
 lda h_speed
 clc
 adc spring_pending
 sta z_tmp2
 inc spring_pending
 ldy h_width,x
 lda horse_width_points-1,y
 sta z_tempword
 lda h_src_height,x
 sec
 sbc #18
 tay
 sed
 clc
 lda z_tempword
 adc horse_height_low,y
 sta z_tempword
 lda horse_height_high,y
 adc #0
 sta z_tempword+1
@double:
 dec z_tmp2
 beq @award
 clc
 lda z_tempword
 adc z_tempword
 sta z_tempword
 lda z_tempword+1
 adc z_tempword+1
 sta z_tempword+1
 jmp @double
@award:
 cld
 lda z_tempword
 ldy z_tempword+1
 jmp add_points
.endproc
horse_width_points: .byte $60,$50,$40,$30,$20,$10,$00
horse_height_low: .byte $00,$00,$80
horse_height_high: .byte $02,$01,$00

.segment "FIDELITY"
.include "tightrope-arcade.s"
