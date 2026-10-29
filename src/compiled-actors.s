; Immutable source pixels compiled into banked masked-cell writers. Gameplay
; and glyph allocation are unchanged; edge/loss poses retain the generic path.
.segment "FUSED"
.proc compiled_dense_entry
 lda #176
 sta $D500
 jmp compiled_dense_dispatch
.endproc
.proc compiled_tramp_entry
 txa
 pha
 tya
 pha
 lda #176
 sta $D500
 jmp compiled_tramp_dispatch
.endproc
.proc compiled_generic_hero
 lda z_bank
 sta $D500
 jmp gfx_draw_hero
.endproc
.proc compiled_actor_call
 sta $D500
 jmp (z_tempword)
.endproc

.segment "ACTORDISPATCH"
.proc compiled_dense_dispatch
 lda sprite_pose
 sec
 sbc #1
 cmp #4
 bcs @generic
 lda sprite_xhi
 bne @generic
 lda sprite_x
 cmp #129
 bcs @generic
 lda sprite_y
 cmp #139
 bcs @generic
 lda #16
 sta gfx_rect_w
 lda #38
 sta gfx_rect_h
 jsr gfx_mark_rect
 lda #0
 sta gfx_mask_count
 lda sprite_pose
 sec
 sbc #1
 jmp compiled_select
@generic:
 jmp compiled_generic_hero
.endproc
.proc compiled_tramp_dispatch
 ldx sprite_pose
 lda $8F00,x
 jmp compiled_select
.endproc
.proc compiled_select
 lsr
 php
 clc
 adc #$90
 sta z_ptr+1
 lda sprite_y
 and #7
 asl
 asl
 sta z_tmp
 lda sprite_x
 and #3
 .repeat 5
 asl
 .endrepeat
 ora z_tmp
 plp
 bcc :+
 ora #128
:
 sta z_ptr
 ldy #0
 lda (z_ptr),y
 sta z_tempword
 iny
 lda (z_ptr),y
 sta z_tempword+1
 iny
 lda (z_ptr),y
 pha
 lda sprite_y
 lsr
 lsr
 lsr
 sta z_row
 lda sprite_x
 lsr
 lsr
 ldx sprite_xhi
 beq :+
 ora #$C0
:
 sta z_col
 lda #255
 sta z_band
 pla
 jmp compiled_actor_call
.endproc

; Identical helper code lives at $B800 in each generated program bank.
.segment "ACTORHELP"
.proc compiled_actor_row
 clc
 adc z_row
 cmp #22
 bcs @outside
 tay
 lda row_band,y
 cmp z_band
 beq @same_band
 sta z_band
 tax
 lda bg_count,x
 sta gfx_hero_base
@same_band:
 lda row_lo,y
 sta z_cell
 lda row_hi,y
 ora z_map+1
 sta z_cell+1
 clc
 rts
@outside:
 sec
 rts
.endproc
.proc compiled_dense_cell
 stx gfx_sprite_alt
 clc
 adc z_col
 tay
 lda (z_cell),y
 sta z_colorflag
 and #127
 sta z_old
 lda gfx_hero_base
 sta z_new
 inc gfx_hero_base
 jmp compiled_actor_pointers
.endproc
.proc compiled_regular_cell
 stx gfx_sprite_alt
 clc
 adc z_col
 cmp #40
 bcs @outside
 sta z_left
 tay
 lda (z_cell),y
 sta z_colorflag
 and #127
 sta z_old
 ldx z_band
 cmp bg_count,x
 bcs @reuse
 lda free_glyph,x
 cmp #128
 bcs @overflow
 sta z_new
 inc free_glyph,x
 ldy z_num
 lda z_cell
 clc
 adc z_left
 sta (z_dirtylo),y
 lda z_cell+1
 adc #0
 and #3
 sta (z_dirtyhi),y
 inc z_num
 ldy z_left
 jmp compiled_actor_pointers
@reuse:
 sta z_new
 jmp compiled_actor_pointers
@overflow:
 inc fault
@outside:
 sec
 rts
.endproc
.proc compiled_actor_pointers
 lda gfx_sprite_alt
 and #128
 ora z_new
 sta (z_cell),y
 ldx z_new
 lda glyph_lo,x
 sta z_glyph
 ldy z_band
 lda glyph_hi,x
 ora band_font,y
 sta z_glyph+1
 bit gfx_sprite_alt
 bvs @blank
 ldx z_old
 beq @blank
 lda glyph_lo,x
 sta z_bg
 lda glyph_hi,x
 ora band_font,y
 sta z_bg+1
 lda z_colorflag
 eor gfx_sprite_alt
 bpl @normal
 lda z_colorflag
 jsr gfx_alt_bg
 bcs @normal
 lda #2
 clc
 rts
@normal:
 lda #1
 clc
 rts
@blank:
 lda #0
 clc
 rts
.endproc
