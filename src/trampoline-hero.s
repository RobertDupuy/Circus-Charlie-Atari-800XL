; Original arcade body poses on an even-pixel Atari drawing grid.
; Contact follows the same snapped pose, including its somersault silhouette.
.segment "TRAMPCONTACT"
.proc tramp_hero_pose
 lda f_phase
 beq @upright
 lda f_direction
 bne @moving
 lda f_phase
 cmp #26
 lda #6
 bcc @done
 lda #7
@done:
 rts
@moving:
 lda f_phase
 cmp #26
 bcs @upright
 sec
 sbc #1
 ldy #0
@divide:
 cmp #5
 bcc @index
 sbc #5
 iny
 bne @divide
@index:
 tya
 clc
 adc #1
 rts
@upright:
 lda #0
 rts
.endproc

.proc tramp_hero_draw
 lda mode
 cmp #2
 bne @old
 jsr tramp_hero_pose
 tay
 lda tramp_hero_ids,y
 sta sprite_pose
 lda #100
 sec
 sbc jump_pixels
 and #254
 sta sprite_y
 lda world
 sec
 sbc camera
 sec
 sbc #12
 and #254
 sta sprite_x
 lda #0
 sbc #0
 sta sprite_xhi
 jsr gfx_tag_hero
 jmp draw_stamp
@old:
 jmp draw_scene::tramp_plain_char
.endproc

.proc tramp_fire_contact
 jmp tramp_body_contact
.endproc
.proc tramp_sword_contact
 jsr tramp_body_contact
 bcs @hit
 sec
 rts
@hit:
 clc
 rts
.endproc

.proc tramp_body_contact
 ; Rendering samples the updated camera later in this same simulation tick.
 txa
 pha
 jsr update_camera
 pla
 tax
 lda world
 sec
 sbc camera
 sec
 sbc #12
 and #1
 clc
 adc #7
 sta z_tmp2
 lda t_proj_xlo,x
 sec
 sbc world
 sta z_tmp
 lda t_proj_xhi,x
 sbc world+1
 sta z_off
 lda z_tmp
 clc
 adc z_tmp2
 sta z_tmp
 lda z_off
 adc #0
 jne @miss
 lda z_tmp
 cmp #32
 jcs @miss
 sta z_left
 ; Both projectile kinds use the same biased dy after their origin offsets.
 lda jump_pixels
 and #1
 clc
 adc jump_pixels
 clc
 adc t_proj_y,x
 sec
 sbc #149
 cmp #64
 jcs @miss
 sta z_savedx
 lda #0
 sta z_value
 lda t_proj_kind,x
 cmp #1
 beq @pose
 ldy t_proj_owner,x
 lda t_proj_xlo,x
 sec
 sbc t_positions_lo,y
 sec
 sbc #3
 and #1
 sta z_value
 lda t_proj_phase,x
 and #4
 lsr
 ora z_value
 clc
 adc #1
 sta z_value
@pose:
 jsr tramp_hero_pose
 sta z_tmp
 asl
 asl
 clc
 adc z_tmp
 clc
 adc z_value
 tay
 lda tramp_contact_lo,y
 sta z_ptr
 lda tramp_contact_hi,y
 sta z_ptr+1
 lda tramp_contact_bits_lo,y
 sta z_bg
 lda tramp_contact_bits_hi,y
 sta z_bg+1
 ldy z_left
 lda (z_ptr),y
 sta z_src
 tya
 lsr
 tay
 lda (z_bg),y
 sta z_tmp
 lda z_left
 and #1
 beq @low_nibble
 lda z_tmp
 lsr
 lsr
 lsr
 lsr
 bpl @high_byte
@low_nibble:
 lda z_tmp
 and #15
@high_byte:
 ora #$A0
 sta z_src+1
 ldy #0
@span:
 lda (z_src),y
 cmp z_savedx
 beq @upper
 bcs @miss
@upper:
 iny
 lda (z_src),y
 cmp z_savedx
 bcc @next
 beq @next
 sec
 rts
@next:
 iny
 bne @span
@miss:
 clc
 rts
.endproc
.include "trampoline-hero-tables.inc"
.segment "TRAMPOLINE"
