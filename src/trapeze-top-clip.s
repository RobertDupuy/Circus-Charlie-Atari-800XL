; Resident code in the former rope-record workspace. It reads the currently
; selected prepared actor bank without switching away from its own code.
.segment "TOPCLIP"
.proc trapeze_clip_top
 lda act
 cmp #5
 bne @ordinary
 lda mode
 cmp #2
 bne @ordinary
 lda r_depth_page
 beq @ordinary
 lda sprite_y
 cmp #219                 ; Y=-37 still has one visible row of a 38-row actor.
 bcc @hidden
 lda z_row
 ora #$E0                 ; Signed tile row for a partially clipped actor.
 sta z_row
@skiprow:
 ldy #0
@cell:
 lda (z_rom),y
 beq :+
 inc gfx_cell_index
:
 iny
 cpy gfx_dense_w
 bne @cell
 lda z_rom
 clc
 adc gfx_dense_w
 sta z_rom
 bcc :+
 inc z_rom+1
:
 inc gfx_dense_row
 lda z_row
 clc
 adc gfx_dense_row
 bne @skiprow
 ; Record only the visible part so alternating screen buffers erase it.
 lda sprite_y
 pha
 clc
 adc #38
 sta gfx_rect_h
 lda #16
 sta gfx_rect_w
 lda #0
 sta sprite_y
 jsr gfx_mark_rect
 pla
 sta sprite_y
@ordinary:
 clc
 rts
@hidden:
 lda #0
 sta gfx_hero_valid
 lda #22
 sta z_row
 rts
.endproc

.proc trapeze_clip_budget
 ldx mode
 cpx #2
 bne @ordinary
 ldx r_depth_page
 beq @ordinary
 cmp #219
 bcc @hidden
 lda #25
 sta gfx_reserve
@hidden:
 sec
 rts
@ordinary:
 clc
 rts
.endproc
