.proc fidelity_tramp_step
 lda #0
 sta z_dx
 lda f_direction
 beq @height
 cmp #4
 beq @left
 lda f_fraction
 clc
 adc #128
 sta f_fraction
 lda world
 adc #1
 sta world
 lda world+1
 adc #0
 sta world+1
 jmp @height
@left:
 lda f_fraction
 sec
 sbc #128
 sta f_fraction
 lda world
 sbc #1
 sta world
 lda world+1
 sbc #0
 sta world+1
 bpl @height
 lda #60
 sta world
 lda #0
 sta world+1
@height:
 inc f_phase
 ldx f_tramp_arc
 lda trampoline_arc_lo,x
 sta z_ptr
 lda trampoline_arc_hi,x
 sta z_ptr+1
 ldy f_phase
 lda (z_ptr),y
 sta jump_pixels
 lda trampoline_arc_length,x
 cmp f_phase
 beq @land
 lsr
 cmp f_phase
 lda #1
 bcs :+
 lda #255
:
 sta velocity
 jmp @hazards
@land:
 lda world
 cmp stage_end
 lda world+1
 sbc stage_end+1
 bcc @apparatus
 lda stage_end
 clc
 adc #32
 sta z_pos
 lda stage_end+1
 adc #0
 sta z_pos+1
 lda world
 cmp z_pos
 lda world+1
 sbc z_pos+1
 jcs hurt
 jmp finish_act
@apparatus:
 ldx #0
@platform:
 lda arcade_tramp_lo,x
 clc
 adc #8
 sta z_pos
 lda arcade_tramp_hi,x
 adc #0
 sta z_pos+1
 jsr distance_to_player
 lda z_pos+1
 bne @next
 lda z_pos
 cmp #13
 bcc @bounce
@next:
 inx
 cpx #25
 bne @platform
 jmp hurt
@bounce:
 stx tramp_index
 lda z_joy
 and #12
 cmp #12
 bne :+
 lda #0
:
 sta f_direction
 cmp #0
 beq @stationary
 lda #0
 sta bounce_count
 sta f_tramp_arc
 txa
@mod:
 cmp #3
 bcc @short
 sbc #3
 bcs @mod
@short:
 cmp #2
 bne @reset
 lda #1
 sta f_tramp_arc
 bne @reset
@stationary:
 inc bounce_count
 lda bounce_count
 cmp #4
 jcs hurt
 clc
 adc #1
 sta f_tramp_arc
@reset:
 lda #0
 sta f_phase
 sta jump_pixels
 sta sound_age
 lda #1
 sta sound_fx
@hazards:
 lda bounce_count
 cmp #3
 bne @flame
 lda jump_pixels
 cmp #80
 bcc @flame
 ldx tramp_index
 lda passed,x
 bne @flame
 inc passed,x
 jsr complete_tramp_prize
@flame:
 jmp tramp_attacks
.endproc
trampoline_arc_0: .byte 0,4,7,10,13,16,19,22,24,26,28,30,32,33,34,35,36,37,37,37,37,37,37,37,37,37,37,37,37,36,35,34,33,32,30,28,26,24,22,19,16,13,10,7,0
trampoline_arc_1: .byte 0,3,6,9,12,15,17,19,21,23,25,26,27,28,29,30,30,30,30,30,30,30,30,30,30,30,30,29,28,27,26,25,23,21,19,17,15,12,9,6,0
trampoline_arc_2: .byte 0,4,8,11,14,17,20,23,26,28,30,32,34,36,37,38,39,40,41,41,41,41,41,41,41,41,41,41,41,41,40,39,38,37,36,34,32,30,28,26,23,20,17,14,11,8,0
trampoline_arc_3: .byte 0,5,9,13,17,21,25,28,31,34,37,40,43,45,47,49,51,53,54,55,56,57,58,58,58,58,58,58,58,58,58,58,58,58,57,56,55,54,53,51,49,47,45,43,40,37,34,31,28,25,21,17,13,9,0
trampoline_arc_4: .byte 0,6,12,17,22,27,32,37,41,45,49,53,57,60,63,66,69,72,75,77,79,81,83,85,86,87,88,89,90,90,90,90,90,90,90,90,90,90,90,90,89,88,87,86,85,83,81,79,77,75,72,69,66,63,60,57,53,49,45,41,37,32,27,22,17,12,0
trampoline_arc_lo: .byte <trampoline_arc_0,<trampoline_arc_1,<trampoline_arc_2,<trampoline_arc_3,<trampoline_arc_4
trampoline_arc_hi: .byte >trampoline_arc_0,>trampoline_arc_1,>trampoline_arc_2,>trampoline_arc_3,>trampoline_arc_4
trampoline_arc_length: .byte 44,40,46,54,66

.proc tramp_init
 lda #1
 sta jumping
 lda #60
 sta world
 lda #0
 sta world+1
 sta f_tramp_arc
 sta f_phase
 sta f_fraction
 sta f_direction
 sta bounce_count
 sta gfx_reserve+2
 sta tramp_index
 sta t_first
 sta t_end
 ldx #$7F
@clear:
 sta t_active,x
 sta $0F00,x
 dex
 bpl @clear
 ldx rank
 lda t_intervals,x
 sta t_period
 lda #1
 sta row_band+17
 sta row_band+18
 sta row_band+19
 lda #7
 sta gfx_dli_next+6
 lda #4
 sta tramp_font_adjust+1
 lda #$84
 sta $681B
 sta $691B
 lda #<1656
 sta stage_end
 lda #>1656
 sta stage_end+1
 rts
.endproc

.proc tramp_resume
 ; Retry on the last reached trampoline; discard the old attack pool.
 lda tramp_index
 pha
 jsr tramp_init
 pla
 tax
 stx tramp_index
 lda arcade_tramp_lo,x
 clc
 adc #8
 sta world
 lda arcade_tramp_hi,x
 adc #0
 sta world+1
 lda #90
 sta grace
 inc checkpoint_restores
 jmp update_camera
.endproc

.proc tramp_attacks
 ldx rank
 lda t_schedule_lo,x
 sta t_sequence
 lda t_schedule_hi,x
 sta t_sequence+1
 ; Keep the active actor window as Charlie moves in either direction.
 ldx t_first
@backward:
 cpx #0
 beq @forward
 dex
 jsr @end_position
 lda world
 cmp z_pos
 lda world+1
 sbc z_pos+1
 bcc @backward
 inx
@forward:
 cpx #24
 beq @begin
 jsr @end_position
 lda world
 cmp z_pos
 lda world+1
 sbc z_pos+1
 bcc @begin
 lda #0
 sta t_active,x
 inx
 bne @forward
@begin:
 stx t_first
 stx t_actor
@actor:
 ldx t_actor
 cpx #24
 jeq @finished
 lda world
 cmp t_triggers_lo,x
 lda world+1
 sbc t_triggers_hi,x
 jcc @finished
 lda t_active,x
 bne @update
 ; Actors spawn from the original position/rank table, never a global clock.
 lda t_sequence
 sta z_ptr
 lda t_sequence+1
 sta z_ptr+1
 txa
 tay
 lda (z_ptr),y
 jeq @next
 sta t_active,x
 sec
 sbc #1
 sta t_remaining,x
 lda t_period
 sta t_timer,x
 lda #100
 sta t_anim,x
@update:
 lda t_anim,x
 cmp #254
 beq :+
 inc t_anim,x
:
 lda t_active,x
 cmp #1
 beq @timer
 lda t_remaining,x
 jeq @next
@timer:
 dec t_timer,x
 jne @next
 lda t_active,x
 cmp #1
 bne @sword
 ldy #0
@fire_pool:
 lda t_proj_kind,y
 beq @spawn
 iny
 cpy #3
 bne @fire_pool
 jmp @retry
@sword:
 ldy #3
@sword_pool:
 lda t_proj_kind,y
 beq @spawn
 iny
 cpy #7
 bne @sword_pool
@retry:
 lda #1
 sta t_timer,x
 jmp @next
@spawn:
 lda t_period
 sta t_timer,x
 lda #0
 sta t_anim,x
 sta t_proj_phase,y
 sta t_proj_frac,y
 txa
 sta t_proj_owner,y
 lda #1
 cpy #3
 bcc :+
 dec t_remaining,x
 lda #2
:
 sta t_proj_kind,y
 lda t_positions_lo,x
 clc
 adc #3
 sta t_proj_xlo,y
 lda t_positions_hi,x
 adc #0
 sta t_proj_xhi,y
 inc t_projectiles
 jmp @next
@next:
 inc t_actor
 jmp @actor
@finished:
 ldx t_actor
@clear_future:
 cpx t_end
 bcs @done
 lda #0
 sta t_active,x
 inx
 bne @clear_future
@done:
 lda t_actor
 sta t_end
 jmp tramp_projectile_step
@end_position:
 lda t_positions_lo,x
 clc
 adc #84
 sta z_pos
 lda t_positions_hi,x
 adc #0
 sta z_pos+1
 rts
.endproc
.proc tramp_projectile_step
 lda #0
 sta t_slot
@projectile:
 ldx t_slot
 lda t_proj_kind,x
 jeq @pnext
 ldy t_proj_owner,x
 lda t_active,y
 jeq @remove
 ldy t_proj_phase,x
 lda t_proj_kind,x
 cmp #1
 bne @sword_move
 cpy #T_FIRE_LENGTH
 jcs @remove
 lda t_fire_y,y
 sta t_proj_y,x
 inc t_proj_phase,x
 jmp @collision
@sword_move:
 cpy #T_SWORD_LENGTH
 bcc @sword_flight
 cpy #T_SWORD_LENGTH+16
 bcs @rethrow
 inc t_proj_phase,x
 jmp @pnext
@rethrow:
 lda #0
 sta t_proj_phase,x
 ldy t_proj_owner,x
 sta t_anim,y
 lda t_positions_lo,y
 clc
 adc #3
 sta t_proj_xlo,x
 lda t_positions_hi,y
 adc #0
 sta t_proj_xhi,x
 ldy #0
@sword_flight:
 lda t_sword_y,y
 sta t_proj_y,x
 inc t_proj_phase,x
 ; Original sword drift: one arcade pixel every eight ticks = 3/32 Atari.
 lda t_proj_frac,x
 clc
 adc #24
 sta t_proj_frac,x
 lda t_proj_xlo,x
 adc #0
 sta t_proj_xlo,x
 bcc @collision
 inc t_proj_xhi,x
@collision:
 lda grace
 jne @pnext
 lda t_proj_xlo,x
 clc
 adc #4
 sta z_pos
 lda t_proj_xhi,x
 adc #0
 sta z_pos+1
 jsr distance_to_player
 lda z_pos+1
 jne @pnext
 lda z_pos
 cmp #7
 jcs @pnext
 lda #176
 sec
 sbc jump_pixels
 sta z_tmp
 lda t_proj_kind,x
 cmp #1
 bne @sword_hit
 lda t_proj_y,x
 sec
 sbc #4
 jmp @dy
@sword_hit:
 lda t_proj_y,x
 clc
 adc #8
@dy:
 sec
 sbc z_tmp
 bcs :+
 eor #255
 clc
 adc #1
:
 ldy t_proj_kind,x
 cpy #1
 bne @blade
 cmp #10
 bcs @pnext
 jmp hurt
@blade:
 cmp #8
 bcs @pnext
 jmp hurt
@remove:
 lda #0
 sta t_proj_kind,x
@pnext:
 inc t_slot
 lda t_slot
 cmp #7
 jne @projectile
 rts
.endproc

.proc tramp_draw
 jsr tramp_clear
 lda t_first
 sta t_draw
 cmp t_end
 jeq @projectiles
@performer:
 ldx t_draw
 lda t_active,x
 jeq @next
 sta t_kind
 lda t_positions_lo,x
 sta z_pos
 lda t_positions_hi,x
 sta z_pos+1
 jsr screen_position
 lda #16
 jsr gfx_visible_width
 bcs @next
 lda sprite_x
 and #$FE
 sta sprite_x
 lda #144
 sta sprite_y
 ldx t_draw
 lda t_kind
 cmp #1
 bne @juggler
 lda #96
 ldy t_anim,x
 cpy #36
 bcc @pose
 lda #97
 bne @pose
@juggler:
 lda #98
 ldy t_anim,x
 cpy #15
 bcs @pose
 lda #99
@pose:
 sec
 sbc #69
 sta gfx_cached_kind
 jsr tramp_stamp
@next:
 inc t_draw
 lda t_draw
 cmp t_end
 jne @performer
@projectiles:
 lda #0
 sta t_draw
 sta t_pm_count
@projectile:
 ldx t_draw
 lda #255
 sta t_pm_slot,x
 lda t_proj_kind,x
 jeq @pnext
 sta t_kind
 cmp #2
 bne :+
 lda t_proj_phase,x
 cmp #T_SWORD_LENGTH+1
 jcs @pnext
:
 lda t_proj_xlo,x
 sta z_pos
 lda t_proj_xhi,x
 sta z_pos+1
 jsr screen_position
 lda #8
 jsr gfx_visible_width
 jcs @pnext
 ldx t_draw
 lda t_kind
 cmp #1
 bne @sword
 lda t_proj_y,x
 sec
 sbc #80
 sta z_tmp
 lda t_proj_phase,x
 lsr
 lsr
 and #1
 clc
 adc #8
 sta z_tmp2
 lda t_proj_phase,x
 and #4
 asl
 asl
 eor #$28
 bne @pm
@sword:
 lda t_proj_y,x
 sec
 sbc #64
 sta z_tmp
 lda t_proj_phase,x
 lsr
 lsr
 and #1
 clc
 adc #10
 sta z_tmp2
 lda #$0E
@pm:
 sta z_value
 ; One player per performer. Multiple projectiles from that performer share
 ; its bitmap, so the three-fire/four-sword pools never hide a fifth shot.
 ldx t_draw
 ldy t_proj_owner,x
 lda #0
 sta z_obj
@find:
 ldx z_obj
 cpx t_pm_count
 beq @new_group
 tya
 cmp t_pm_owner,x
 beq @group
 inc z_obj
 bne @find
@new_group:
 cpx #4
 jcs @pnext
 tya
 sta t_pm_owner,x
 lda #255
 sta pm_y,x
 lda #0
 sta t_pm_bottom,x
 lda z_value
 sta pm_color,x
 lda z_tmp2
 sta pm_id,x
 lda t_kind
 sec
 sbc #1
 sta pm_size,x
 inc t_pm_count
 ; Anchor both sword flights to their performer, retaining their real drift.
 lda t_positions_lo,y
 clc
 adc #3
 sta z_pos
 lda t_positions_hi,y
 adc #0
 sta z_pos+1
 jsr screen_position
 ldx z_obj
 lda sprite_x
 sta pm_x,x
@group:
 ldy t_draw
 txa
 sta t_pm_slot,y
 lda z_tmp
 cmp pm_y,x
 bcs :+
 sta pm_y,x
:
 ldy #32
 lda t_kind
 cmp #1
 beq :+
 ldy #16
:
 tya
 clc
 adc z_tmp
 cmp t_pm_bottom,x
 bcc @pnext
 sta t_pm_bottom,x
@pnext:
 inc t_draw
 lda t_draw
 cmp #7
 jne @projectile
 rts
.endproc
.include "act3-tables.inc"


; The fixed-height apparatus occupies uniform field rows. Repaint those rows
; once per picture instead of recording/restoring overlapping object rectangles.
.proc tramp_clear
 lda back
 jne @second
 .repeat 6,R
 lda $3400+(16+R)*40
 .repeat 40,C
 sta $3800+(16+R)*40+C
 .endrepeat
 .endrepeat
 rts
@second:
 .repeat 6,R
 lda $3400+(16+R)*40
 .repeat 40,C
 sta $3C00+(16+R)*40+C
 .endrepeat
 .endrepeat
 rts
.endproc

; Clear the old extents, stage the new player registers, then OR every shot into
; its performer's player. Sword pairs fit the 16-pixel double-width player.
.proc tramp_prepare
 lda back
 asl
 asl
 sta z_pmnum
 lda back
 asl
 asl
 asl
 asl
 asl
 sta z_savedx
 lda #0
 sta z_iter
@group:
 ldx back
 lda pm_high,x
 clc
 adc #4
 adc z_iter
 sta z_pm+1
 ldx z_pmnum
 lda pm_old_y,x
 sta z_pm
 lda pm_old_h,x
 beq @cleared
 ; Unrolled stores clear each old bitmap byte in five cycles.
 sta z_tmp
 lda #0
 sta z_tmp2
 asl z_tmp
 rol z_tmp2
 clc
 lda z_tmp
 adc pm_old_h,x
 sta z_tmp
 lda z_tmp2
 adc #0
 sta z_tmp2
 lda t_clear_lo,x
 sec
 sbc z_tmp
 sta z_rom
 lda t_clear_hi,x
 sbc z_tmp2
 sta z_rom+1
 ldy pm_old_y,x
 lda #0
 jsr @erase
@cleared:
 ldy z_savedx
 lda #0
 sta $0E00,y
 sta $0E04,y
 sta $0E08,y
 ldx z_pmnum
 sta pm_old_h,x
 ldx z_iter
 cpx t_pm_count
 bcs @next_group
 lda pm_x,x
 clc
 adc #48
 sta $0E00,y
 lda pm_size,x
 sta $0E08,y
 lda pm_color,x
 tax
 lda $FD00,x
 sta $0E0C,y
 ldx z_iter
 lda pm_y,x
 clc
 adc #40
 ldy z_pmnum
 sta pm_old_y,y
 lda t_pm_bottom,x
 sec
 sbc pm_y,x
 sta pm_old_h,y
@next_group:
 ldx z_iter
 lda #0
 sta t_pm_owner,x ; Reuse after grouping: whether this player has a first shot.
 inc z_pmnum
 inc z_savedx
 inc z_iter
 lda z_iter
 cmp #4
 jne @group
 lda #0
 sta t_slot
@shot:
 ldx t_slot
 ldy t_pm_slot,x
 cpy #255
 jeq @next
 lda back
 asl
 asl
 asl
 clc
 adc #$5C
 sta z_pm+1
 tya
 clc
 adc z_pm+1
 sta z_pm+1
 lda t_proj_kind,x
 cmp #1
 bne @sword
 lda t_proj_y,x
 sec
 sbc #40
 sta z_pm
 lda t_proj_phase,x
 lsr
 lsr
 and #1
 clc
 adc #8
 tay
 lda pm_pattern_lo,y
 sta z_pmdata
 lda pm_pattern_hi,y
 sta z_pmdata+1
 lda #32
 sta z_pmheight
 jmp @copy
@sword:
 lda t_proj_y,x
 sec
 sbc #24
 sta z_pm
 ldy t_proj_owner,x
 lda t_proj_xlo,x
 sec
 sbc t_positions_lo,y
 sec
 sbc #3
 sta z_pmdata
 lda #0
 sta z_pmdata+1
 .repeat 5
 asl z_pmdata
 rol z_pmdata+1
 .endrepeat
 lda t_proj_phase,x
 and #4
 beq :+
 lda z_pmdata
 ora #$10
 sta z_pmdata
:
 lda z_pmdata
 clc
 adc #<t_sword_masks
 sta z_pmdata
 lda z_pmdata+1
 adc #>t_sword_masks
 sta z_pmdata+1
 lda #16
 sta z_pmheight
@copy:
 ldx t_slot
 ldy t_pm_slot,x
 lda t_pm_owner,y
 bne @merge_start
 lda #1
 sta t_pm_owner,y
 ldy #0
@first:
 .repeat 8
 lda (z_pmdata),y
 sta (z_pm),y
 iny
 .endrepeat
 cpy z_pmheight
 bcc @first
 jmp @next
@merge_start:
 ldy #0
@merge:
 .repeat 8
 lda (z_pmdata),y
 ora (z_pm),y
 sta (z_pm),y
 iny
 .endrepeat
 cpy z_pmheight
 bcc @merge
@next:
 inc t_slot
 lda t_slot
 cmp #7
 jne @shot
 rts
@erase:
 jmp (z_rom)
.endproc

t_sword_masks:
.incbin "../assets/act3-sword-masks.bin"

; Enter N stores before RTS, with Y equal to the old top scanline.
.repeat 8,P
.ident(.sprintf("t_clear_%d",P)):
 .repeat 132,I
 sta $5C00+(P/4)*$800+(P .mod 4)*$100+131-I,y
 .endrepeat
.ident(.sprintf("t_clear_end_%d",P)):
 rts
.endrepeat
t_clear_lo:
.repeat 8,P
 .byte <.ident(.sprintf("t_clear_end_%d",P))
.endrepeat
t_clear_hi:
.repeat 8,P
 .byte >.ident(.sprintf("t_clear_end_%d",P))
.endrepeat
