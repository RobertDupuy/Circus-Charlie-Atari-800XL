; Arcade reference: rope ends before a deck 19 scanlines above it.
; This bank-0 helper is entered from RAM and uses a prepared cell renderer.
.segment "WATER"
.proc tightrope_finish_draw
 ; The title occupies these ROM font slots. Install the goal's few patterns
 ; into both RAM fonts once; the old atlas safely falls back for these codes.
 lda bg_count+1
 cmp #TIGHTROPE_GOAL_COUNT
 bcs @ready
 ldx #TIGHTROPE_GOAL_BYTES-1
@font:
 lda tightrope_goal_tiles,x
 sta $45C0,x
 sta $51C0,x
 dex
 bpl @font
 lda #TIGHTROPE_GOAL_COUNT
 sta bg_count+1
 clc
 adc gfx_reserve+1
 sta free_glyph+1
@ready:
 lda #<1452
 sta z_pos
 lda #>1452
 sta z_pos+1
 jsr screen_position
 lda sprite_xhi
 jne @done
 lda sprite_x
 cmp #160
 jcs @done
 clc
 adc #3
 and #252
 sta sprite_x
 ; End the rope at its real walk-off edge, before drawing Charlie/monkeys.
 pha
 lda #77
 sta sprite_y
 lda #27
 sta gfx_rect_h
 lda #160
 sec
 sbc sprite_x
 sta gfx_rect_w
 jsr gfx_mark_rect
 pla
 pha
 clc
 adc #3
 lsr
 lsr
 tay
 lda #<480
 sta z_cell
 lda z_map+1
 clc
 adc #1
 sta z_cell+1
 lda #0
 cpy #40
 beq @erased
@erase:
 sta (z_cell),y
 iny
 cpy #40
 bne @erase
@erased:
 pla
 ; One independent white player supplies the full-height lattice support.
 clc
 adc #24
 cmp #160
 bcs @deck
 sta pm_x+3
 lda #79
 sta pm_y+3
 lda #12
 sta pm_id+3
 lda #$0E
 sta pm_color+3
@deck:
 lda sprite_x
 lsr
 lsr
 sta z_col
 jmp tightrope_goal_blit
@done:
 rts
.endproc
.include "tightrope-finish-data.inc"

.segment "AUX"
.proc complete_begin_entry
 lda #$20
 sta $D500
 jmp complete_begin
.endproc
.proc tightrope_clear_pose
 lda #$20
 sta $D500
 jmp arcade_clear_pose
.endproc

.segment "WATER"
.proc arcade_clear_pose
 lda act
 cmp #1
 beq @rope
 cmp #3
 beq @balls
 cmp #4
 beq @horse
 cmp #2
 beq @tramp
@ordinary:
 lda #CHAR_WALK1
 rts
@rope:
 lda #39
 bne @height
@balls:
 lda #103
 bne @height
@tramp:
 lda water
 bne @ordinary
 ; The trampoline course finishes on the pedestal at Y=128.
 lda #90
 bne @height
@horse:
 lda #87
@height:
 sta sprite_y
 lda sprite_x
 and #252
 sta sprite_x
 lda clear_elapsed
 lsr
 lsr
 lsr
 lsr
 and #1
 clc
 adc #100
 rts
.endproc
.include "ground-finish.s"
