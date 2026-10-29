; Two striped arcade-style podiums. Prepared glyphs are copied into each
; visible font's private pool; repeated body rows share the same seven codes.
; Called from RAM before balls, or after the pony, with bank 0 mapped.
.proc ground_finish_draw
.if ::ARCADE_CHOOSER
 ; The final Balls camera fixes the goal at column 30. Its prepared stores
 ; leave time for the ball rims to be composited in front on NTSC.
 lda act
 cmp #3
 bne :+
 lda camera
 cmp #<1345
 bne :+
 lda camera+1
 cmp #>1345
 bne :+
 lda #$3B
 jmp ground_finish_goal_entry
:
.endif
 lda stage_end
 ldx act
 cpx #4
 bne :+
 sec
 sbc #26
:
 sta z_pos
 lda stage_end+1
 cpx #4
 bne :+
 sbc #0
:
 sta z_pos+1
 jsr screen_position
 lda #48
 jsr gfx_visible_width
 jcs @done
 lda sprite_x
 and #252
 sta sprite_x
 lda #136
 ldx act
 cpx #4
 bne :+
 lda #120
:
 sta sprite_y
 lda #168
 sec
 sbc sprite_y
 sta gfx_rect_h
 lda #48
 sta gfx_rect_w
 lda act
 cmp #3
 beq :+ ; prepare_balls already restores this entire four-row strip.
 jsr gfx_mark_rect
:
 lda sprite_x
 lsr
 lsr
 ldx sprite_xhi
 beq :+
 ora #192
:
 sta z_left
 lda sprite_y
 lsr
 lsr
 lsr
 sta z_row
 sta z_prepared
 lda #255
 sta z_s1
@row:
 ldx z_row
 lda row_band,x
 cmp z_s1
 beq @mapped
 sta z_s1
 tax
 lda act
 cmp #3
 bne @private
 lda bg_count+2
 clc
 adc #20
 sta z_s0
 jmp @mapped
@private:
 lda free_glyph,x
 sta z_s0
 clc
 adc #7
 cmp #129
 bcc :+
 inc fault
 rts
:
 sta free_glyph,x
 lda z_s0
 tay
 lda glyph_lo,y
 sta z_glyph
 lda glyph_hi,y
 ora band_font,x
 sta z_glyph+1
 ldy #55
@copy:
 lda ground_goal_tiles,y
 sta (z_glyph),y
 dey
 bpl @copy
@mapped:
 ldx z_row
 lda row_lo,x
 sta z_cell
 lda row_hi,x
 clc
 adc z_map+1
 sta z_cell+1
 lda #12
 cpx z_prepared
 bne :+
 lda #0
:
 cpx #20
 bne :+
 lda #24
:
 sta z_counter
 clc
 adc #12
 sta z_savedx
 ldx z_counter
 ldy z_left
@cell:
 lda ground_goal_cells,x
 clc
 adc z_s0
 cpy #40
 bcs @next
 sta (z_cell),y
@next:
 iny
 inx
 cpx z_savedx
 bne @cell
 inc z_row
 lda z_row
 cmp #21
 jne @row
@done:
 rts
.endproc
ground_goal_cells:
 .byte 0,1,1,1,1,1,1,1,1,1,1,2
 .byte 131,132,131,132,131,132,131,132,131,132,131,132
 .byte 133,134,133,134,133,134,133,134,133,134,133,134
ground_goal_tiles:
 .byte 0,0,0,0,0,$0F,$0F,$AA
 .byte 0,0,0,0,0,$FF,$FF,$AA
 .byte 0,0,0,0,0,$F0,$F0,$AA
 .byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
 .byte $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
 .byte $FF,$FF,$FF,$FF,$FF,$AA,0,0
 .byte $AA,$AA,$AA,$AA,$AA,$AA,0,0

.if ::ARCADE_CHOOSER
.segment "CHOOSER"
.proc ground_finish_goal_cached
 lda #<(17*40+30)
 sta z_cell
 lda z_map+1
 clc
 adc #>(17*40+30)
 sta z_cell+1
 lda bg_count+2
 clc
 adc #20
 ; Both buffer bases keep every sum below 256; stores preserve carry.
 .repeat 6,K
  .if K=0
   ldy #0
   sta (z_cell),y
  .elseif K=1
   adc #1
   .repeat 9,I
    ldy #I+1
    sta (z_cell),y
   .endrepeat
  .elseif K<4
    .if K=2
    adc #130
   .else
    adc #1
   .endif
   .repeat 2,R
    .repeat 5,I
     ldy #40+R*40+I*2+K-2
     sta (z_cell),y
    .endrepeat
   .endrepeat
  .else
   adc #1
   .repeat 5,I
    ldy #120+I*2+K-4
    sta (z_cell),y
   .endrepeat
  .endif
 .endrepeat
 rts
.endproc
.segment "WATER"
.endif
