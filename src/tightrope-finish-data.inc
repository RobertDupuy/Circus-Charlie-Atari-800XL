; Generated raised Tightrope deck tiles and clipped cell records.
TIGHTROPE_GOAL_COUNT=61
tightrope_goal_tiles:
 .byte 0,0,0,0,0,5,21,63,0,0,0,0,0,85,85,255,0,0,0,0,0,64,0,0,3,3,12,12,255,0,0,0,0,0,0,0,0,5,21,255
TIGHTROPE_GOAL_BYTES=40
.proc tightrope_goal_blit
 lda #<360
 sta z_cell
 ldy z_col
 tya
 clc
 adc #3
 tay
 cpy #40
 bcs @row9
 lda #56
 sta (z_cell),y
 iny
 cpy #40
 bcs @row9
 lda #57
 sta (z_cell),y
 iny
 cpy #40
 bcs @row9
 sta (z_cell),y
 iny
 cpy #40
 bcs @row9
 sta (z_cell),y
 iny
 cpy #40
 bcs @row9
 sta (z_cell),y
 iny
 cpy #40
 bcs @row9
 sta (z_cell),y
 iny
 cpy #40
 bcs @row9
 sta (z_cell),y
 iny
 cpy #40
 bcs @row9
 sta (z_cell),y
 iny
 cpy #40
 bcs @row9
 sta (z_cell),y
 iny
 cpy #40
 bcs @row9
 lda #58
 sta (z_cell),y
 iny
@row9:
 lda #<400
 sta z_cell
 ldy z_col
 tya
 clc
 adc #11
 tay
 cpy #40
 bcs @row10
 lda #59
 sta (z_cell),y
 iny
@row10:
 lda #<440
 sta z_cell
 ldy z_col
 cpy #40
 bcs @row11
 lda #60
 sta (z_cell),y
 iny
 cpy #40
 bcs @row11
 lda #57
 sta (z_cell),y
 iny
 cpy #40
 bcs @row11
 sta (z_cell),y
 iny
 cpy #40
 bcs @row11
 sta (z_cell),y
 iny
 cpy #40
 bcs @row11
 sta (z_cell),y
 iny
 cpy #40
 bcs @row11
 sta (z_cell),y
 iny
 cpy #40
 bcs @row11
 sta (z_cell),y
 iny
 cpy #40
 bcs @row11
 sta (z_cell),y
 iny
 cpy #40
 bcs @row11
 sta (z_cell),y
 iny
 cpy #40
 bcs @row11
 sta (z_cell),y
 iny
 cpy #40
 bcs @row11
 sta (z_cell),y
 iny
 cpy #40
 bcs @row11
 sta (z_cell),y
 iny
 cpy #40
 bcs @row11
 sta (z_cell),y
 iny
 cpy #40
 bcs @row11
 sta (z_cell),y
 iny
@row11:
 rts
.endproc
