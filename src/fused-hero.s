; Native whole-pose copy/merge at the ordinary camera-follow X coordinate.
; The generic compositor remains responsible for edges and clipped poses.
.segment "FUSED"
.proc trapeze_hero_dispatch
 jsr trapeze_fast_hero
 bcc @generic
 rts
@generic:
 jmp gfx_draw_hero
.endproc
.proc trapeze_fast_hero
 lda act
 cmp #5
 bne @no
 lda sprite_pose
 sec
 sbc #3
 cmp #2
 bcs @no
 sta z_tmp
 lda sprite_xhi
 bne @no
 lda sprite_x
 cmp #52
 bne @no
 lda sprite_y
 cmp #139
 bcs @no
 lda #16
 sta gfx_rect_w
 lda #38
 sta gfx_rect_h
 jsr gfx_mark_rect
 lda sprite_pose
 sec
 sbc #3
 asl
 ora back
 asl
 asl
 clc
 adc #$80
 sta z_ptr+1
 lda sprite_y
 sta z_ptr
 lda #$40
 sta $D500
 ldy #0
 lda (z_ptr),y
 sta z_tempword
 inc z_ptr+1
 lda (z_ptr),y
 sta z_tempword+1
 inc z_ptr+1
 lda (z_ptr),y
 sta $D500
 lda #0
 sta gfx_mask_count
 jsr @call
 sec
 rts
@call:
 jmp (z_tempword)
@no:
 clc
 rts
.endproc
